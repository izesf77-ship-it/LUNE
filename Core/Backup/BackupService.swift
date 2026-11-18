import Foundation
import CryptoKit
import SwiftData

// MARK: - Errors

enum BackupError: Error, LocalizedError {
    case invalidFormat
    case unsupportedVersion
    case wrongPasswordOrCorrupted
    case emptyBackup
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat: return "Файл не является резервной копией LUNÉ."
        case .unsupportedVersion: return "Версия резервной копии не поддерживается."
        case .wrongPasswordOrCorrupted: return "Неверный пароль или повреждённый файл."
        case .emptyBackup: return "В резервной копии нет записей."
        case .importFailed(let detail): return "Не удалось импортировать: \(detail)"
        }
    }
}

// MARK: - DTO

struct BackupRecordDTO: Codable, Hashable {
    var entity: String
    var fields: [String: String]
}

struct BackupPayload: Codable {
    let formatVersion: Int
    let appVersion: String
    let schemaVersion: String
    let createdAt: String
    let records: [BackupRecordDTO]

    static let currentFormatVersion = 2
}

// MARK: - Crypto

enum BackupCrypto {
    private static let magic = Data("LUNEBK02".utf8)
    private static let version: UInt32 = 2
    private static let saltLength = 32

    static func encrypt(payload: Data, password: String) throws -> Data {
        let salt = Data((0..<saltLength).map { _ in UInt8.random(in: 0...255) })
        let key = try deriveKey(password: password, salt: salt)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(payload, using: key, nonce: nonce)
        guard let combined = sealed.combined else {
            throw BackupError.importFailed("Не удалось собрать зашифрованный блок.")
        }

        var output = magic
        withUnsafeBytes(of: version.littleEndian) { output.append(contentsOf: $0) }
        output.append(salt)
        output.append(combined)
        return output
    }

    static func decrypt(data: Data, password: String) throws -> Data {
        let headerLength = magic.count + MemoryLayout<UInt32>.size
        guard data.count > headerLength + saltLength + 16 else {
            throw BackupError.invalidFormat
        }
        guard Data(data.prefix(magic.count)) == magic else {
            throw BackupError.invalidFormat
        }

        let versionBytes = data.subdata(in: magic.count..<headerLength)
        guard versionBytes.count == MemoryLayout<UInt32>.size else { throw BackupError.invalidFormat }
        let fileVersion = UInt32(versionBytes[0])
            | (UInt32(versionBytes[1]) << 8)
            | (UInt32(versionBytes[2]) << 16)
            | (UInt32(versionBytes[3]) << 24)
        guard fileVersion == version else { throw BackupError.unsupportedVersion }

        let salt = data.subdata(in: headerLength..<(headerLength + saltLength))
        let combinedStart = headerLength + saltLength
        let combined = data.subdata(in: combinedStart..<data.count)

        do {
            let key = try deriveKey(password: password, salt: salt)
            let box = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw BackupError.wrongPasswordOrCorrupted
        }
    }

    /// PBKDF2-HMAC-SHA256. CryptoKit не предоставляет готовую функцию PBKDF2,
    /// поэтому реализация собрана из его HMAC<SHA256> — без внешних зависимостей.
    private static func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw BackupError.wrongPasswordOrCorrupted
        }

        let iterations = 100_000
        let outputLength = 32
        let key = SymmetricKey(data: passwordData)
        var derived = Data()
        var blockIndex: UInt32 = 1

        while derived.count < outputLength {
            var input = Data()
            input.append(salt)
            var indexBytes = blockIndex.bigEndian
            withUnsafeBytes(of: &indexBytes) { input.append(contentsOf: $0) }

            var u = HMAC<SHA256>.authenticationCode(for: input, using: key)
            var block = Data(Array(u))
            for _ in 1..<iterations {
                u = HMAC<SHA256>.authenticationCode(for: Data(Array(u)), using: key)
                let next = Array(u)
                for i in 0..<block.count { block[i] ^= next[i] }
            }
            derived.append(block)
            blockIndex += 1
        }

        return SymmetricKey(data: derived.prefix(outputLength))
    }
}

// MARK: - Service

@MainActor
final class BackupService {

    static let shared = BackupService()
    private let database = DatabaseManager.shared

    private init() {}

    // MARK: Export

    func createEncryptedBackup(password: String) throws -> URL {
        let records = collectRecords()
        guard !records.isEmpty else { throw BackupError.emptyBackup }

        let payload = BackupPayload(
            formatVersion: BackupPayload.currentFormatVersion,
            appVersion: LuneAppVersion.marketing,
            schemaVersion: "1.1.0",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            records: records
        )

        let json = try JSONEncoder().encode(payload)
        let encrypted = try BackupCrypto.encrypt(payload: json, password: password)

        let directory = try backupDirectory()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = directory.appendingPathComponent("LUNE-\(formatter.string(from: Date())).lunebackup")
        try encrypted.write(to: url, options: .atomic)

        database.insert(BackupMetadata(
            backupVersion: payload.formatVersion,
            recordCount: records.count,
            fileName: url.lastPathComponent
        ))
        return url
    }

    // MARK: Import

    /// Возвращает количество добавленных записей. Дубликаты по UUID пропускаются.
    @discardableResult
    func importBackup(from url: URL, password: String) throws -> Int {
        guard url.startAccessingSecurityScopedResource() else {
            throw BackupError.importFailed("Нет доступа к файлу.")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.importFailed("Файл не удалось прочитать.")
        }

        let json = try BackupCrypto.decrypt(data: data, password: password)
        let payload: BackupPayload
        do {
            payload = try JSONDecoder().decode(BackupPayload.self, from: json)
        } catch {
            throw BackupError.invalidFormat
        }
        guard payload.formatVersion <= BackupPayload.currentFormatVersion else {
            throw BackupError.unsupportedVersion
        }

        return apply(payload)
    }

    // MARK: - Record collection

    private func collectRecords() -> [BackupRecordDTO] {
        var result: [BackupRecordDTO] = []

        func add<T: PersistentModel>(_ entity: String, _ items: [T], _ map: (T) -> [String: String]) {
            result.append(contentsOf: items.map { BackupRecordDTO(entity: entity, fields: map($0)) })
        }

        add("UserProfile", database.all(UserProfile.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "currentMode": $0.currentModeRaw,
                "onboarding": String($0.hasCompletedOnboarding),
                "cycleLength": $0.typicalCycleLength.map(String.init) ?? "",
                "periodDuration": $0.typicalPeriodDuration.map(String.init) ?? "",
                "faceID": String($0.faceIDEnabled),
                "hideNotificationPreviews": String($0.hideNotificationPreviews),
                "notifications": String($0.notificationsEnabled)
            ], uniquingKeysWith: { _, new in new })
        }

        add("MenstrualPeriod", database.all(MenstrualPeriod.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "startDay": $0.startDayKey,
                "endDay": $0.endDayKey ?? "",
                "reportedDuration": $0.userReportedDuration.map(String.init) ?? "",
                "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("BleedingDayEntry", database.all(BleedingDayEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "flow": String($0.flow), "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("DailySymptomEntry", database.all(DailySymptomEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "symptom": $0.symptomRaw,
                "intensity": String($0.intensity), "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("DailyMoodEntry", database.all(DailyMoodEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "mood": $0.moodRaw, "note": $0.note ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("DailyWellbeingEntry", database.all(DailyWellbeingEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "energy": String($0.energy),
                "sleep": String($0.sleepHours), "pain": String($0.painLevel),
                "bloating": String($0.bloating), "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("BasalTemperatureEntry", database.all(BasalTemperatureEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "celsius": String($0.celsius),
                "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("CervicalMucusEntry", database.all(CervicalMucusEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "type": $0.typeRaw, "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("LHTestEntry", database.all(LHTestEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "result": $0.resultRaw, "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("PregnancyTestEntry", database.all(PregnancyTestEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "result": $0.resultRaw, "notes": $0.notes ?? "",
                "observation": String($0.wantsObservationScenario)
            ], uniquingKeysWith: { _, new in new })
        }

        add("IntimacyEntry", database.all(IntimacyEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "protection": String($0.protectionUsed),
                "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("MedicationEntry", database.all(MedicationEntry.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "name": $0.name, "dose": $0.dose ?? "",
                "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("DailyNote", database.all(DailyNote.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "text": $0.text
            ], uniquingKeysWith: { _, new in new })
        }

        add("CycleAnnotation", database.all(CycleAnnotation.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "day": $0.dayKey, "title": $0.title, "notes": $0.notes ?? ""
            ], uniquingKeysWith: { _, new in new })
        }

        add("NotificationConfiguration", database.all(NotificationConfiguration.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "identifier": $0.identifier, "kind": $0.kindRaw,
                "hour": String($0.hour), "enabled": String($0.isEnabled)
            ], uniquingKeysWith: { _, new in new })
        }

        add("AppPreferences", database.all(AppPreferences.self)) {
            base($0.id, $0.createdAt, $0.updatedAt).merging([
                "key": $0.key, "value": $0.value
            ], uniquingKeysWith: { _, new in new })
        }

        return result
    }

    private func base(_ id: UUID, _ created: Date, _ updated: Date) -> [String: String] {
        [
            "id": id.uuidString,
            "createdAt": ISO8601DateFormatter().string(from: created),
            "updatedAt": ISO8601DateFormatter().string(from: updated)
        ]
    }

    // MARK: - Apply

    private func apply(_ payload: BackupPayload) -> Int {
        var existingIds = Set(allExistingIds())
        var inserted = 0

        for record in payload.records {
            guard let idString = record.fields["id"],
                  let id = UUID(uuidString: idString),
                  !existingIds.contains(id) else { continue }

            let day = (record.fields["day"] ?? record.fields["startDay"])
                .flatMap { CalendarDate(key: $0) }
                ?? CalendarDate(Date())
            let endDayKey = record.fields["endDay"] ?? ""
            let endDay = endDayKey.isEmpty ? nil : CalendarDate(key: endDayKey)

            switch record.entity {
            case "UserProfile":
                // Профиль уже существует — не перезаписываем, чтобы не потерять текущие настройки.
                continue
            case "MenstrualPeriod":
                database.insert(MenstrualPeriod(
                    id: id,
                    startDay: day,
                    endDay: endDay,
                    userReportedDuration: int(record.fields, "reportedDuration"),
                    notes: text(record.fields, "notes")
                ))
            case "BleedingDayEntry":
                database.insert(BleedingDayEntry(
                    id: id, day: day,
                    flow: int(record.fields, "flow") ?? 2,
                    notes: text(record.fields, "notes")
                ))
            case "DailySymptomEntry":
                database.insert(DailySymptomEntry(
                    id: id, day: day,
                    symptom: SymptomType(rawValue: record.fields["symptom"] ?? "") ?? .other,
                    intensity: int(record.fields, "intensity") ?? 2,
                    notes: text(record.fields, "notes")
                ))
            case "DailyMoodEntry":
                database.insert(DailyMoodEntry(
                    id: id, day: day,
                    mood: MoodType(rawValue: record.fields["mood"] ?? "") ?? .neutral,
                    note: text(record.fields, "note")
                ))
            case "DailyWellbeingEntry":
                database.insert(DailyWellbeingEntry(
                    id: id, day: day,
                    energy: int(record.fields, "energy") ?? 3,
                    sleepHours: double(record.fields, "sleep") ?? 7,
                    painLevel: int(record.fields, "pain") ?? 0,
                    bloating: int(record.fields, "bloating") ?? 0,
                    notes: text(record.fields, "notes")
                ))
            case "BasalTemperatureEntry":
                database.insert(BasalTemperatureEntry(
                    id: id, day: day,
                    celsius: double(record.fields, "celsius") ?? 36.5,
                    notes: text(record.fields, "notes")
                ))
            case "CervicalMucusEntry":
                database.insert(CervicalMucusEntry(
                    id: id, day: day,
                    type: CervicalMucusType(rawValue: record.fields["type"] ?? "") ?? .unknown,
                    notes: text(record.fields, "notes")
                ))
            case "LHTestEntry":
                database.insert(LHTestEntry(
                    id: id, day: day,
                    result: TestResult(rawValue: record.fields["result"] ?? "") ?? .invalid,
                    notes: text(record.fields, "notes")
                ))
            case "PregnancyTestEntry":
                database.insert(PregnancyTestEntry(
                    id: id, day: day,
                    result: TestResult(rawValue: record.fields["result"] ?? "") ?? .invalid,
                    notes: text(record.fields, "notes"),
                    wantsObservationScenario: bool(record.fields, "observation")
                ))
            case "IntimacyEntry":
                database.insert(IntimacyEntry(
                    id: id, day: day,
                    protectionUsed: bool(record.fields, "protection"),
                    notes: text(record.fields, "notes")
                ))
            case "MedicationEntry":
                database.insert(MedicationEntry(
                    id: id, day: day,
                    name: record.fields["name"] ?? "",
                    dose: text(record.fields, "dose"),
                    notes: text(record.fields, "notes")
                ))
            case "DailyNote":
                database.insert(DailyNote(id: id, day: day, text: record.fields["text"] ?? ""))
            case "CycleAnnotation":
                database.insert(CycleAnnotation(
                    id: id, day: day,
                    title: record.fields["title"] ?? "",
                    notes: text(record.fields, "notes")
                ))
            case "NotificationConfiguration":
                database.insert(NotificationConfiguration(
                    id: id,
                    identifier: record.fields["identifier"] ?? id.uuidString,
                    kind: LocalNotificationKind(rawValue: record.fields["kind"] ?? "") ?? .period,
                    hour: int(record.fields, "hour") ?? 9,
                    isEnabled: record.fields["enabled"].map { $0 != "false" } ?? true
                ))
            case "AppPreferences":
                database.insert(AppPreferences(
                    id: id,
                    key: record.fields["key"] ?? "",
                    value: record.fields["value"] ?? ""
                ))
            default:
                continue
            }
            // Защита от повторного импорта того же файла и дубликатов внутри него.
            existingIds.insert(id)
            inserted += 1
        }

        return inserted
    }

    private func allExistingIds() -> [UUID] {
        var ids: [UUID] = []
        ids += database.all(UserProfile.self).map(\.id)
        ids += database.all(MenstrualPeriod.self).map(\.id)
        ids += database.all(BleedingDayEntry.self).map(\.id)
        ids += database.all(DailySymptomEntry.self).map(\.id)
        ids += database.all(DailyMoodEntry.self).map(\.id)
        ids += database.all(DailyWellbeingEntry.self).map(\.id)
        ids += database.all(BasalTemperatureEntry.self).map(\.id)
        ids += database.all(CervicalMucusEntry.self).map(\.id)
        ids += database.all(LHTestEntry.self).map(\.id)
        ids += database.all(PregnancyTestEntry.self).map(\.id)
        ids += database.all(IntimacyEntry.self).map(\.id)
        ids += database.all(MedicationEntry.self).map(\.id)
        ids += database.all(DailyNote.self).map(\.id)
        ids += database.all(CycleAnnotation.self).map(\.id)
        ids += database.all(NotificationConfiguration.self).map(\.id)
        ids += database.all(AppPreferences.self).map(\.id)
        return ids
    }

    private func text(_ fields: [String: String], _ key: String) -> String? {
        let value = fields[key] ?? ""
        return value.isEmpty ? nil : value
    }

    private func int(_ fields: [String: String], _ key: String) -> Int? {
        fields[key].flatMap { Int($0) }
    }

    private func double(_ fields: [String: String], _ key: String) -> Double? {
        fields[key].flatMap { Double($0) }
    }

    private func bool(_ fields: [String: String], _ key: String) -> Bool {
        fields[key] == "true"
    }

    private func backupDirectory() throws -> URL {
        let url = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Backups", isDirectory: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func existingBackups() -> [URL] {
        (try? backupDirectory())
            .map { try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) }
            .flatMap { $0 }?
            .filter { $0.pathExtension == "lunebackup" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            ?? []
    }

    func deleteBackup(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
