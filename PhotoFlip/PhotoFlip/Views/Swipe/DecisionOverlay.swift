import SwiftUI

struct DecisionOverlay: View {
    let dragOffset: CGSize

    private var decision: SwipeDecision? {
        let x = dragOffset.width
        if x > 30 { return .keep }
        if x < -30 { return .delete }
        return nil
    }

    private var opacity: Double {
        min(1.0, abs(dragOffset.width) / 80.0)
    }

    var body: some View {
        ZStack {
            if let decision {
                switch decision {
                case .keep:
                    badge(text: "保留", color: .keep, rotation: -14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(24)
                case .delete:
                    badge(text: "删除", color: .delete, rotation: 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(24)
                default:
                    EmptyView()
                }
            }
        }
        .opacity(opacity)
        .animation(.easeOut(duration: 0.1), value: dragOffset)
    }

    private func badge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 4)
            )
            .rotationEffect(.degrees(rotation))
    }
}

#Preview("保留") {
    DecisionOverlay(dragOffset: CGSize(width: 120, height: 0))
        .frame(width: 300, height: 400)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}

#Preview("删除") {
    DecisionOverlay(dragOffset: CGSize(width: -120, height: 0))
        .frame(width: 300, height: 400)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}

#Preview("无操作") {
    DecisionOverlay(dragOffset: .zero)
        .frame(width: 300, height: 400)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}
