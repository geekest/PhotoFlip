import Foundation
import Photos

/// 整理页支持整理的媒体类型：照片或视频。
enum MediaKind: String, CaseIterable, Identifiable {
    case photo
    case video

    var id: String { rawValue }

    var label: String {
        switch self {
        case .photo: return "照片"
        case .video: return "视频"
        }
    }

    var systemImage: String {
        switch self {
        case .photo: return "photo"
        case .video: return "video"
        }
    }

    var assetMediaType: PHAssetMediaType {
        switch self {
        case .photo: return .image
        case .video: return .video
        }
    }

    /// 单轮整理允许的最大数量。视频体积大、加载重，固定上限为 10。
    var batchLimit: Int {
        switch self {
        case .photo: return 0      // 0 表示沿用设置里的 batchSize
        case .video: return 10
        }
    }
}
