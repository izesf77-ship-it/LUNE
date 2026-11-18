import Foundation

/// Единственный источник версии внутри приложения.
/// Значения читаются из Info.plist, который собирается из VERSION + build number CI.
enum LuneAppVersion {

    static var marketing: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.lune.cycletracker"
    }

    /// Формат: Версия 1.1.0 (12)
    static var displayText: String {
        "Версия \(marketing) (\(build))"
    }
}
