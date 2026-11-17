import SwiftUI

/// Дизайн-система LUNÉ: Цветовые токены
/// Soft Rose Luxury палитра с поддержкой light/dark режимов
struct ColorTokens {
    
    // MARK: - Background Colors
    
    /// Основной фон приложения
    static let background = Color("Background", bundle: nil)
    
    /// Фон для карточек и поверхностей
    static let surface = Color("Surface", bundle: nil)
    
    /// Вторичный фон
    static let surfaceSecondary = Color("SurfaceSecondary", bundle: nil)
    
    // MARK: - Brand Colors
    
    /// Основной розовый цвет бренда
    static let rosePrimary = Color("RosePrimary", bundle: nil)
    
    /// Глубокий розовый для акцентов
    static let roseDeep = Color("RoseDeep", bundle: nil)
    
    /// Нежный румянец
    static let blush = Color("Blush", bundle: nil)
    
    /// Лавандовый для фертильности
    static let lavender = Color("Lavender", bundle: nil)
    
    // MARK: - Text Colors
    
    /// Основной текст
    static let textPrimary = Color("TextPrimary", bundle: nil)
    
    /// Вторичный текст
    static let textSecondary = Color("TextSecondary", bundle: nil)
    
    /// Tertiary (placeholder) text
    static let textTertiary = Color("TextTertiary", bundle: nil)
    
    // MARK: - Semantic Colors
    
    /// Период менструации
    static let periodActive = Color("PeriodActive", bundle: nil)
    
    /// Прогнозируемый период
    static let periodPredicted = Color("PeriodPredicted", bundle: nil)
    
    /// Фертильное окно
    static let fertilityWindow = Color("FertilityWindow", bundle: nil)
    
    /// Овуляция
    static let ovulation = Color("Ovulation", bundle: nil)
    
    /// Сегодня в календаре
    static let today = Color("Today", bundle: nil)
    
    /// Выбранная дата
    static let selected = Color("Selected", bundle: nil)
    
    // MARK: - Symptom Colors
    
    static let symptomLow = Color("SymptomLow", bundle: nil)
    static let symptomMedium = Color("SymptomMedium", bundle: nil)
    static let symptomHigh = Color("SymptomHigh", bundle: nil)
    
    // MARK: - Status Colors
    
    static let success = Color("Success", bundle: nil)
    static let warning = Color("Warning", bundle: nil)
    static let error = Color("Error", bundle: nil)
    static let info = Color("Info", bundle: nil)
    
    // MARK: - Test Results
    
    static let testPositive = Color("TestPositive", bundle: nil)
    static let testNegative = Color("TestNegative", bundle: nil)
    static let testInvalid = Color("TestInvalid", bundle: nil)
    
    // MARK: - Light Mode Fallbacks
    
    struct Light {
        static let background = Color(hex: "#FFF9FB")
        static let surface = Color(hex: "#FFFFFF")
        static let surfaceSecondary = Color(hex: "#FCE8EF")
        static let rosePrimary = Color(hex: "#F4A6BE")
        static let roseDeep = Color(hex: "#A64D72")
        static let blush = Color(hex: "#FCE8EF")
        static let lavender = Color(hex: "#EDE5FA")
        static let textPrimary = Color(hex: "#352C35")
        static let textSecondary = Color(hex: "#836E7B")
        static let textTertiary = Color(hex: "#A89BA5")
    }
    
    // MARK: - Dark Mode Fallbacks
    
    struct Dark {
        static let background = Color(hex: "#1C1719")
        static let surface = Color(hex: "#2A2428")
        static let surfaceSecondary = Color(hex: "#362F33")
        static let rosePrimary = Color(hex: "#D98FA8")
        static let roseDeep = Color(hex: "#C47594")
        static let blush = Color(hex: "#3D2F36")
        static let lavender = Color(hex: "#4A4254")
        static let textPrimary = Color(hex: "#F5EEF2")
        static let textSecondary = Color(hex: "#C4B5BE")
        static let textTertiary = Color(hex: "#8A7882")
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
