import SwiftUI

enum KeyDisplayOrientation: String, CaseIterable {
    case vertical = "Vertical"
    case horizontal = "Horizontal"
}

enum CaseStyle: String, CaseIterable {
    case auto = "Detectar"
    case uppercase = "Mayúsculas"
    case lowercase = "Minúsculas"
}

class Settings: ObservableObject, Equatable {
    @AppStorage("maxVisibleKeys") var maxVisibleKeys: Int = 5
    @AppStorage("keyDisplayDuration") var keyDisplayDuration: Double = 2.0
    @AppStorage("fontSize") var fontSize: Double = 16.0
    @AppStorage("opacity") var opacity: Double = 0.8
    @AppStorage("showBackground") var showBackground: Bool = true
    @AppStorage("orientation") private var orientationRawValue: String = KeyDisplayOrientation.vertical.rawValue
    @AppStorage("spacing") var spacing: Double = 4.0
    @AppStorage("caseStyle") private var caseStyleRawValue: String = CaseStyle.auto.rawValue
    
    // Propiedades computadas para position
    @AppStorage("positionX") private var positionX: Double = 100
    @AppStorage("positionY") private var positionY: Double = 100
    
    // Propiedades computadas para colores
    @AppStorage("keyBackgroundColorHex") private var keyBackgroundColorHex: String = "#80000000"
    @AppStorage("keyTextColorHex") private var keyTextColorHex: String = "#FFFFFF"
    
    var orientation: KeyDisplayOrientation {
        get { KeyDisplayOrientation(rawValue: orientationRawValue) ?? .vertical }
        set { orientationRawValue = newValue.rawValue }
    }
    
    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }
    
    var keyBackgroundColor: Color {
        get { Color(hex: keyBackgroundColorHex) ?? .black.opacity(0.5) }
        set { keyBackgroundColorHex = newValue.toHex() ?? "#80000000" }
    }
    
    var keyTextColor: Color {
        get { Color(hex: keyTextColorHex) ?? .white }
        set { keyTextColorHex = newValue.toHex() ?? "#FFFFFF" }
    }
    
    var caseStyle: CaseStyle {
        get { CaseStyle(rawValue: caseStyleRawValue) ?? .auto }
        set { caseStyleRawValue = newValue.rawValue }
    }
    
    static func == (lhs: Settings, rhs: Settings) -> Bool {
        return lhs.maxVisibleKeys == rhs.maxVisibleKeys &&
               lhs.keyDisplayDuration == rhs.keyDisplayDuration &&
               lhs.fontSize == rhs.fontSize &&
               lhs.opacity == rhs.opacity &&
               lhs.showBackground == rhs.showBackground &&
               lhs.orientationRawValue == rhs.orientationRawValue &&
               lhs.spacing == rhs.spacing &&
               lhs.positionX == rhs.positionX &&
               lhs.positionY == rhs.positionY &&
               lhs.keyBackgroundColorHex == rhs.keyBackgroundColorHex &&
               lhs.keyTextColorHex == rhs.keyTextColorHex
    }
}

// Extensiones para manejar colores
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var a: CGFloat = 1.0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if hexSanitized.count == 8 {
            a = CGFloat((rgb >> 24) & 0xFF) / 255.0
            self.init(
                .sRGB,
                red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
                green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
                blue: CGFloat(rgb & 0xFF) / 255.0,
                opacity: a
            )
        } else {
            self.init(
                .sRGB,
                red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
                green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
                blue: CGFloat(rgb & 0xFF) / 255.0,
                opacity: a
            )
        }
    }
    
    func toHex() -> String? {
        let uiColor = NSColor(self)
        guard let components = uiColor.cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(components[3])
        
        let hex = String(
            format: "#%02lX%02lX%02lX%02lX",
            lround(Double(a * 255)),
            lround(Double(r * 255)),
            lround(Double(g * 255)),
            lround(Double(b * 255))
        )
        
        return hex
    }
} 