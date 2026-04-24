import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "自动"
        case .light:  return "浅色"
        case .dark:   return "深色"
        }
    }
}

extension Color {
    static let keep = Color.green
    static let delete = Color.red
    static let favorite = Color.pfOrange
    static let pfOrange = Color(red: 0.94, green: 0.56, blue: 0.12)
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
