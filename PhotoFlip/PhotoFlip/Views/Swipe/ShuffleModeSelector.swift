import SwiftUI

/// Pill-shaped sliding selector for choosing the photo source mode.
/// Supports tap-to-select and horizontal drag-to-slide between segments.
struct ShuffleModeSelector: View {
    @Binding var selection: ShuffleMode
    var onSelect: (ShuffleMode) -> Void

    private let modes = ShuffleMode.allCases
    private let height: CGFloat = 36
    private let inset: CGFloat = 3

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let segmentWidth = (geo.size.width - inset * 2) / CGFloat(modes.count)
            let selectedIndex = modes.firstIndex(of: selection) ?? 0
            let baseX = inset + segmentWidth * CGFloat(selectedIndex)
            let knobX = clamp(baseX + dragOffset,
                              lower: inset,
                              upper: geo.size.width - inset - segmentWidth)

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color(.secondarySystemFill))

                // Sliding knob
                Capsule()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                    .frame(width: segmentWidth, height: height - inset * 2)
                    .offset(x: knobX)
                    .animation(isDragging ? nil : .spring(response: 0.32, dampingFraction: 0.78),
                               value: knobX)

                // Labels
                HStack(spacing: 0) {
                    ForEach(Array(modes.enumerated()), id: \.element) { index, mode in
                        Button {
                            select(mode)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mode.systemImage)
                                    .font(.caption)
                                Text(mode.label)
                                    .font(.footnote.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(index == selectedIndex ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, inset)
            }
            .frame(height: height)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let projected = baseX + value.translation.width + value.predictedEndTranslation.width * 0.2
                        let center = projected + segmentWidth / 2
                        let raw = Int((center - inset) / segmentWidth)
                        let target = max(0, min(modes.count - 1, raw))
                        isDragging = false
                        dragOffset = 0
                        select(modes[target])
                    }
            )
        }
        .frame(height: height)
    }

    private func select(_ mode: ShuffleMode) {
        // Always notify the caller — even if the user re-taps the same mode,
        // since for `.specifiedDate` the parent may want to re-open the picker.
        let changed = mode != selection
        if changed {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                selection = mode
            }
            HapticManager.shared.impact(.light)
        }
        onSelect(mode)
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
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
