import Foundation

enum ShuffleMode: String, CaseIterable, Identifiable {
    case recent
    case random
    case specifiedDate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent:        return "最近"
        case .random:        return "随机"
        case .specifiedDate: return "指定时间"
        }
    }

    var systemImage: String {
        switch self {
        case .recent:        return "clock.arrow.circlepath"
        case .random:        return "shuffle"
        case .specifiedDate: return "calendar"
        }
    }
}
