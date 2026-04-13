import SwiftUI

struct DecisionOverlay: View {
    let dragOffset: CGSize

    private var decision: SwipeDecision? {
        let x = dragOffset.width
        let y = dragOffset.height
        if abs(x) > abs(y) {
            if x > 30 { return .keep }
            if x < -30 { return .delete }
        } else {
            if y < -30 { return .favorite }
        }
        return nil
    }

    private var opacity: Double {
        let x = dragOffset.width
        let y = dragOffset.height
        let magnitude = abs(x) > abs(y) ? abs(x) : abs(y)
        return min(1.0, magnitude / 80.0)
    }

    var body: some View {
        ZStack {
            if let decision {
                switch decision {
                case .keep:
                    badge(text: "保留", color: .keep, rotation: -15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(24)
                case .delete:
                    badge(text: "删除", color: .delete, rotation: 15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(24)
                case .favorite:
                    badge(text: "收藏", color: .favorite, rotation: 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 48)
                case .undecided:
                    EmptyView()
                }
            }
        }
        .opacity(opacity)
        .animation(.easeOut(duration: 0.1), value: dragOffset)
    }

    private func badge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.title.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 3)
            )
            .rotationEffect(.degrees(rotation))
    }
}
