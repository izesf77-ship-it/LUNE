import Foundation
import SwiftData

// MARK: - Schema versions

/// Версия 1: исходная схема LUNE.
enum LuneSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            AppPreferences.self,
            MenstrualPeriod.self,
            BleedingDayEntry.self,
            DailySymptomEntry.self,
            DailyMoodEntry.self,
            DailyWellbeingEntry.self,
            BasalTemperatureEntry.self,
            CervicalMucusEntry.self,
            LHTestEntry.self,
            PregnancyTestEntry.self,
            IntimacyEntry.self,
            MedicationEntry.self,
            DailyNote.self,
            CycleAnnotation.self,
            NotificationConfiguration.self,
            BackupMetadata.self
        ]
    }
}

/// Версия 2: та же модель данных, добавлен план миграции и расширенные метаданные.
/// Новые поля в `@Model` являются optional и не требуют миграции данных.
enum LuneSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] { LuneSchemaV1.models }
}

/// План миграции SwiftData. Все stages — lightweight: добавление полей и новых сущностей.
enum LuneMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LuneSchemaV1.self, LuneSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: LuneSchemaV1.self, toVersion: LuneSchemaV2.self)]
    }
}

// MARK: - DatabaseManager

@MainActor
final class DatabaseManager {

    static let shared = DatabaseManager()

    private(set) var container: ModelContainer
    private(set) var context: ModelContext

    private let storeURL: URL?

    private init() {
        // Явно задаём путь к хранилищу, чтобы применить класс защиты iOS к файлу БД.
        let resolvedStoreURL: URL? = try? {
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = base.appendingPathComponent("LUNE", isDirectory: true)
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            return directory.appendingPathComponent("LUNE.store")
        }()
        self.storeURL = resolvedStoreURL

        let configuration: ModelConfiguration
        if let resolvedStoreURL {
            configuration = ModelConfiguration(
                schema: Schema(versionedSchema: LuneSchemaV2.self),
                url: resolvedStoreURL,
                allowsSave: true
            )
        } else {
            configuration = ModelConfiguration(
                schema: Schema(versionedSchema: LuneSchemaV2.self),
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
        }

        do {
            container = try ModelContainer(
                for: Schema(versionedSchema: LuneSchemaV2.self),
                migrationPlan: LuneMigrationPlan.self,
                configurations: configuration
            )
            context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            // Полная потеря базы — исключительная ситуация. Пытаемся открыть
            // хранилище в памяти, чтобы приложение не упало и пользователь
            // мог восстановиться из резервной копии.
            let fallback = ModelConfiguration(
                schema: Schema(versionedSchema: LuneSchemaV2.self),
                isStoredInMemoryOnly: true
            )
            do {
                container = try ModelContainer(for: Schema(versionedSchema: LuneSchemaV2.self), configurations: fallback)
                context = ModelContext(container)
                context.autosaveEnabled = true
            } catch {
                fatalError("Не удалось инициализировать хранилище SwiftData: \(error)")
            }
        }

        applyDataProtection()
    }

    /// Устанавливает класс защиты для файла базы: данные доступны после первой разблокировки.
    private func applyDataProtection() {
        #if os(iOS)
        guard let storeURL else { return }
        let candidates = [storeURL,
                          storeURL.deletingLastPathComponent().appendingPathComponent("LUNE.store-wal"),
                          storeURL.deletingLastPathComponent().appendingPathComponent("LUNE.store-shm")]
        for file in candidates where FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: file.path
            )
        }
        #endif
    }

    // MARK: - Profile

    func fetchOrCreateProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        save()
        return profile
    }

    // MARK: - Generic access

    func all<T: PersistentModel>(_ type: T.Type) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    func records<T: PersistentModel & DayKeyedRecord>(
        _ type: T.Type,
        on day: CalendarDate? = nil
    ) -> [T] {
        let all = all(type)
        guard let day else { return all }
        return all.filter { $0.dayKey == day.key }
    }

    func insert(_ model: some PersistentModel) {
        context.insert(model)
        save()
    }

    func delete(_ model: some PersistentModel) {
        context.delete(model)
        save()
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Ошибка сохранения SwiftData: \(error)")
        }
    }

    // MARK: - Periods

    /// Все записи менструаций создаются пользователем; прогнозы никогда не сохраняются.
    func periods() -> [MenstrualPeriod] {
        all(MenstrualPeriod.self).sorted { $0.startDay > $1.startDay }
    }

    func periodStarts() -> [CalendarDate] {
        periods().map(\.startDay).sorted()
    }

    // MARK: - Destructive operations

    func deleteAllData() {
        do {
            try context.delete(model: UserProfile.self)
            try context.delete(model: AppPreferences.self)
            try context.delete(model: MenstrualPeriod.self)
            try context.delete(model: BleedingDayEntry.self)
            try context.delete(model: DailySymptomEntry.self)
            try context.delete(model: DailyMoodEntry.self)
            try context.delete(model: DailyWellbeingEntry.self)
            try context.delete(model: BasalTemperatureEntry.self)
            try context.delete(model: CervicalMucusEntry.self)
            try context.delete(model: LHTestEntry.self)
            try context.delete(model: PregnancyTestEntry.self)
            try context.delete(model: IntimacyEntry.self)
            try context.delete(model: MedicationEntry.self)
            try context.delete(model: DailyNote.self)
            try context.delete(model: CycleAnnotation.self)
            try context.delete(model: NotificationConfiguration.self)
            try context.delete(model: BackupMetadata.self)
        } catch {
            assertionFailure("Не удалось удалить данные: \(error)")
        }
        save()
    }

    /// Количество записей во всех сущностях — используется в экране приватности и backup.
    var totalRecordCount: Int {
        var count = 0
        count += (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<AppPreferences>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<MenstrualPeriod>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<BleedingDayEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<DailySymptomEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<DailyMoodEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<DailyWellbeingEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<BasalTemperatureEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<CervicalMucusEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<LHTestEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<PregnancyTestEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<IntimacyEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<MedicationEntry>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<DailyNote>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<CycleAnnotation>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<NotificationConfiguration>())) ?? 0
        count += (try? context.fetchCount(FetchDescriptor<BackupMetadata>())) ?? 0
        return count
    }
}
