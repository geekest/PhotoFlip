import AVFoundation
import Photos
import UIKit

/// 单个视频的播放器加载器，对标 `ImageLoader`。
///
/// - 通过 `PHImageManager.requestPlayerItem` 异步取得可播放的 `AVPlayerItem`（支持 iCloud 视频）。
/// - 卡片首次滑入为顶卡时，静音自动播放前 15 秒后暂停。
/// - 内联卡片与全屏详情共享同一个 `AVPlayer`，因此播放位置天然连续：
///   从详情退出后，内联画面会停在退出时那一帧。
@Observable
final class VideoPreviewLoader {
    /// 供内联图层与详情页共享的播放器。
    var player: AVPlayer?
    /// 是否已就绪（已拿到 player item）。
    var isReady: Bool = false

    /// 预览自动播放的截止时间（秒）。
    private let previewCutoff: Double = 15

    private var requestID: PHImageRequestID?
    private var timeObserver: Any?
    private var hasAutoPlayed = false

    /// 加载指定视频资源，准备好可播放的 `AVPlayer`。
    func load(asset: PHAsset) {
        guard asset.mediaType == .video else { return }
        cancel()

        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true

        requestID = PHImageManager.default().requestPlayerItem(
            forVideo: asset,
            options: options
        ) { [weak self] item, _ in
            guard let item else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                let player = AVPlayer(playerItem: item)
                player.isMuted = true                // 内联预览静音
                player.actionAtItemEnd = .pause
                self.player = player
                self.isReady = true
            }
        }
    }

    /// 卡片成为顶卡时调用：静音从头播放，到 15 秒自动暂停。仅触发一次。
    func playPreview() {
        guard let player, !hasAutoPlayed else { return }
        hasAutoPlayed = true
        player.isMuted = true
        player.seek(to: .zero)
        player.play()

        // 周期性观察播放进度，到达截止点后暂停并移除观察者。
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            if time.seconds >= self.previewCutoff {
                self.player?.pause()
                self.removeTimeObserver()
            }
        }
    }

    /// 暂停内联预览（卡片不再是顶卡时）。
    func pause() {
        player?.pause()
    }

    /// 进入全屏详情前调用：移除 15 秒限制，使全程播放不被截断。
    func prepareForDetail() {
        removeTimeObserver()
    }

    /// 回收：取消请求、移除观察者、释放播放器。
    func cancel() {
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
            requestID = nil
        }
        removeTimeObserver()
        player?.pause()
        player = nil
        isReady = false
        hasAutoPlayed = false
    }

    private func removeTimeObserver() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    deinit {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
        }
    }
}
