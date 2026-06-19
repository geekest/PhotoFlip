import AVFoundation
import AVKit
import SwiftUI

/// 全屏视频播放页：完整时长播放，支持原生时间线拖动与暂停，并可切换倍速（1x / 1.5x / 2x）。
///
/// 与内联卡片共享同一个 `AVPlayer`，退出后内联画面停在退出时那一帧。
struct VideoDetailView: View {
    let player: AVPlayer

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRate: Float = 1.0

    private let rateOptions: [Float] = [1.0, 1.5, 2.0]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(rateOptions, id: \.self) { rate in
                            Button {
                                applyRate(rate)
                            } label: {
                                if rate == selectedRate {
                                    Label(rateLabel(rate), systemImage: "checkmark")
                                } else {
                                    Text(rateLabel(rate))
                                }
                            }
                        }
                    } label: {
                        Text(rateLabel(selectedRate))
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }
        }
        .onAppear {
            // 切换到 playback 分类，确保即使在静音开关下也能播放声音。
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.isMuted = false           // 详情页恢复声音
        }
    }

    private func applyRate(_ rate: Float) {
        selectedRate = rate
        // 即使当前暂停，也设置 defaultRate，使下次播放沿用所选倍速。
        player.defaultRate = rate
        if player.timeControlStatus != .paused {
            player.rate = rate
        }
    }

    private func rateLabel(_ rate: Float) -> String {
        rate == rate.rounded() ? "\(Int(rate))x" : "\(rate)x"
    }
}
