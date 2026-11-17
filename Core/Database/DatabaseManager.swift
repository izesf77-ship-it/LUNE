import Foundation
import SwiftData

/// Менеджер базы данных SwiftData
@MainActor
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private(set) var container: ModelContainer
    private(set) var context: ModelContext
    
    private init() {
        let schema = Schema([
            UserProfile.self,
            MenstrualPeriod.self,
            SymptomEntry.self,
            MoodEntry.self,
            DailyNote.self,
            BasalTemperatureEntry.self,
            CervicalMucusEntry.self,
            LHTestEntry.self,
            PregnancyTestEntry.self,
            IntimacyEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            fatalError("Не удалось инициализировать базу данных: \(error)")
        }
    }
    
    // MARK: - User Profile
    
    func fetchOrCreateUserProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try context.fetch(descriptor)
            if let profile = profiles.first {
                return profile
            }
        } catch {
            print("Ошибка получения профиля: \(error)")
        }
        
        // Создаём новый профиль
        let profile = UserProfile()
        context.insert(profile)
        saveContext()
        return profile
    }
    
    // MARK: - Menstrual Periods
    
    func fetchAllPeriods() -> [MenstrualPeriod] {
        let descriptor = FetchDescriptor<MenstrualPeriod>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Ошибка получения периодов: \(error)")
            return []
        }
    }
    
    func fetchConfirmedPeriods() -> [MenstrualPeriod] {
        var descriptor = FetchDescriptor<MenstrualPeriod>(
            predicate: #Predicate { $0.isConfirmed == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 12 // Last 12 cycles
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Ошибка получения подтверждённых периодов: \(error)")
            return []
        }
    }
    
    func addPeriod(_ period: MenstrualPeriod) {
        context.insert(period)
        saveContext()
    }
    
    func deletePeriod(_ period: MenstrualPeriod) {
        context.delete(period)
        saveContext()
    }
    
    // MARK: - Daily Entries
    
    func fetchEntries<T: PersistentModel>(for date: Date, type: T.Type) -> [T] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<T>()
        
        do {
            let allEntries = try context.fetch(descriptor)
            // Filter by date property if it exists
            return allEntries.filter { entry in
                if let dailyEntry = entry as? any DailyEntryProtocol {
                    let entryDate = dailyEntry.date
                    return entryDate >= startOfDay && entryDate < endOfDay
                }
                return false
            }
        } catch {
            print("Ошибка получения записей: \(error)")
            return []
        }
    }
    
    func addEntry<T: PersistentModel>(_ entry: T) {
        context.insert(entry)
        saveContext()
    }
    
    func deleteEntry<T: PersistentModel>(_ entry: T) {
        context.delete(entry)
        saveContext()
    }
    
    // MARK: - Save Context
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения контекста: \(error)")
        }
    }
    
    // MARK: - Delete All Data
    
    func deleteAllData() {
        do {
            try context.delete(model: UserProfile.self)
            try context.delete(model: MenstrualPeriod.self)
            try context.delete(model: SymptomEntry.self)
            try context.delete(model: MoodEntry.self)
            try context.delete(model: DailyNote.self)
            try context.delete(model: BasalTemperatureEntry.self)
            try context.delete(model: CervicalMucusEntry.self)
            try context.delete(model: LHTestEntry.self)
            try context.delete(model: PregnancyTestEntry.self)
            try context.delete(model: IntimacyEntry.self)
            saveContext()
        } catch {
            print("Ошибка удаления данных: \(error)")
        }
    }
}

// MARK: - Protocol для фильтрации по дате

protocol DailyEntryProtocol {
    var date: Date { get }
}

extension SymptomEntry: DailyEntryProtocol {}
extension MoodEntry: DailyEntryProtocol {}
extension DailyNote: DailyEntryProtocol {}
extension BasalTemperatureEntry: DailyEntryProtocol {}
extension CervicalMucusEntry: DailyEntryProtocol {}
extension LHTestEntry: DailyEntryProtocol {}
extension PregnancyTestEntry: DailyEntryProtocol {}
extension IntimacyEntry: DailyEntryProtocol {}
