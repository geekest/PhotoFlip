import SwiftUI

struct CompletionView: View {
    let deleted: Int
    let kept: Int
    let duration: TimeInterval

    @Environment(AppState.self) private var appState

    private var durationText: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) 分 \(seconds) 秒"
        }
        return "\(seconds) 秒"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("整理完成！")
                .font(.largeTitle.bold())

            VStack(spacing: 16) {
                statRow(icon: "trash.fill", color: .red, label: "已删除", value: "\(deleted) 张")
                statRow(icon: "checkmark.circle.fill", color: .green, label: "已保留", value: "\(kept) 张")
                statRow(icon: "clock.fill", color: .blue, label: "用时", value: durationText)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()

            Button("再来一轮") {
                appState.pendingPhotos = []
                appState.screen = .permission
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer().frame(height: 20)
        }
    }

    private func statRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.body)
    }
}
