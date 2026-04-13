import SwiftUI

extension Color {
    static let keep = Color.green
    static let delete = Color.red
    static let favorite = Color.yellow
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
