import SwiftUI

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
