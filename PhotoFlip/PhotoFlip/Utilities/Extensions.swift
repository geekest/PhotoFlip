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
    // 使用语义颜色，让浅色/深色外观和提高对比度设置由系统负责适配。
    static let keep = Color.green
    static let delete = Color.red
    static let favorite = Color.pfOrange
    static let pfOrange = Color(red: 0.94, green: 0.56, blue: 0.12)
}

enum PhotoFlipStyle {
    static let pagePadding: CGFloat = 20
    static let compactPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 24
    static let controlCornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 24
}

extension View {
    /// 统一可交互内容卡片的系统表面层级，不改变内容本身的状态或动作。
    func photoFlipCard(cornerRadius: CGFloat = PhotoFlipStyle.cardCornerRadius) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
