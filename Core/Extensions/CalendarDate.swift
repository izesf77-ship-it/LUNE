import Foundation

/// Календарный день (год-месяц-день) без привязки к моменту времени.
///
/// Все расчёты цикла в LUNE выполняются над `CalendarDate`, а не над `Date`.
/// Это исключает смещение записей на день при смене часового пояса и DST:
/// пользователь видит тот же день, который он записал, где бы он ни находился.
struct CalendarDate: Codable, Hashable, Comparable, CustomStringConvertible {

    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        let clampedMonth = min(max(month, 1), 12)
        let reference = Calendar.gregorianUTC.date(
            from: DateComponents(year: year, month: clampedMonth, day: 1)
        ) ?? Date(timeIntervalSince1970: 0)
        let range = Calendar.gregorianUTC.range(of: .day, in: .month, for: reference) ?? 1..<32
        self.year = year
        self.month = clampedMonth
        self.day = min(max(day, range.lowerBound), range.upperBound - 1)
    }

    /// Создаёт календарный день из момента времени в календаре пользователя.
    init(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(
            year: components.year ?? 1970,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    /// Создаёт календарный день из стабильного ключа `yyyy-MM-dd`.
    init?(key: String) {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    /// Стабильный ключ для хранения в SwiftData и backup-файле.
    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    var description: String { key }

    /// Момент времени в UTC-календаре, используемый только для арифметики дней.
    var utcDate: Date {
        Self.makeDate(year: year, month: month, day: day)
    }

    /// Преобразование в `Date` для отображения в локальном календаре пользователя.
    func localDate(calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    func adding(days: Int) -> CalendarDate {
        let date = Calendar.gregorianUTC.date(
            byAdding: .day, value: days, to: utcDate
        ) ?? utcDate
        return CalendarDate(date, calendar: .gregorianUTC)
    }

    /// Количество дней от `self` до `other` (отрицательное, если `other` раньше).
    func days(until other: CalendarDate) -> Int {
        Calendar.gregorianUTC.dateComponents(
            [.day], from: utcDate, to: other.utcDate
        ).day ?? 0
    }

    var weekday: Int {
        Calendar.gregorianUTC.component(.weekday, from: utcDate)
    }

    /// Число дней в указанном месяце по фиксированному григорианскому календарю.
    /// Не зависит от часового пояса устройства.
    static func daysInMonth(year: Int, month: Int) -> Int {
        let first = CalendarDate(year: year, month: month, day: 1)
        return Calendar.gregorianUTC.range(of: .day, in: .month, for: first.utcDate)?.count ?? 30
    }

    static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        lhs.key < rhs.key
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar.gregorianUTC
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }
}

// MARK: - Fixed calendar

extension Calendar {
    /// Григорианский календарь в UTC. Используется только для арифметики дней,
    /// поэтому на него не влияют DST и локальный часовой пояс.
    static let gregorianUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }()
}

// MARK: - Russian pluralization

/// Корректные русские формы для чисел (1 день, 2 дня, 5 дней).
enum RussianPlural {
    static func form(_ number: Int, one: String, few: String, many: String) -> String {
        let n = abs(number) % 100
        let n1 = n % 10
        if n > 10 && n < 20 { return many }
        if n1 > 1 && n1 < 5 { return few }
        if n1 == 1 { return one }
        return many
    }

    static func days(_ number: Int) -> String {
        form(number, one: "день", few: "дня", many: "дней")
    }

    static func cycles(_ number: Int) -> String {
        form(number, one: "цикл", few: "цикла", many: "циклов")
    }

    static func tests(_ number: Int) -> String {
        form(number, one: "тест", few: "теста", many: "тестов")
    }

    static func daysPhrase(_ number: Int) -> String {
        "\(number) \(days(number))"
    }
}
