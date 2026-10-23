import SwiftUI

/// 使用系统分段控件选择照片来源，保留指定日期的再次打开入口。
struct ShuffleModeSelector: View {
    @Binding var selection: ShuffleMode
    var onSelect: (ShuffleMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("整理来源", selection: Binding(
                get: { selection },
                set: { mode in
                    selection = mode
                    onSelect(mode)
                }
            )) {
                ForEach(ShuffleMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if selection == .specifiedDate {
                Button {
                    onSelect(.specifiedDate)
                } label: {
                    Label("重新选择日期", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .accessibilityHint(Text("打开日期选择器"))
            }
        }
    }
}

#Preview("ShuffleModeSelector") {
    struct Wrapper: View {
        @State private var mode: ShuffleMode = .recent
        var body: some View {
            VStack(spacing: 24) {
                ShuffleModeSelector(selection: $mode) { _ in }
                    .padding(.horizontal)
                Text("当前模式: \(mode.label)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    return Wrapper()
}
