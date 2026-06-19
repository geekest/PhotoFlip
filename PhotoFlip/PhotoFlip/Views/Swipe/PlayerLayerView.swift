import AVFoundation
import SwiftUI

/// 用 `AVPlayerLayer` 渲染视频的无控件视图，按 `resizeAspectFill` 充满卡片。
///
/// `VideoPlayer`(AVKit) 自带控件且为 aspectFit，不适合卡片内联预览，因此自定义包装。
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    /// 以 `AVPlayerLayer` 作为 backing layer 的容器视图，保证 layer 跟随视图尺寸。
    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
