import SwiftUI

struct SwipeCardView: View {
    let photoItem: PhotoItem
    @Bindable var viewModel: SwipeSessionViewModel
    let isTopCard: Bool
    let loader: ImageLoader

    @State private var flyOffDirection: SwipeDecision?

    private let screenWidth = UIScreen.main.bounds.width
    private let dragThresholdX: CGFloat = 100
    private let dragThresholdY: CGFloat = -80

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(ProgressView())
            }

            if isTopCard {
                DecisionOverlay(dragOffset: viewModel.dragOffset)
            }
        }
        .cornerRadius(16)
        .shadow(radius: 8)
        .offset(isTopCard ? viewModel.dragOffset : .zero)
        .rotationEffect(
            isTopCard
                ? .degrees(Double(viewModel.dragOffset.width / screenWidth) * 15)
                : .zero
        )
        .gesture(isTopCard ? dragGesture : nil)
        .onChange(of: flyOffDirection) { _, direction in
            guard let direction else { return }
            performFlyOff(to: direction)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                viewModel.dragOffset = value.translation
            }
            .onEnded { value in
                let x = value.translation.width
                let y = value.translation.height

                if x > dragThresholdX {
                    flyOffDirection = .keep
                } else if x < -dragThresholdX {
                    flyOffDirection = .delete
                } else if y < dragThresholdY {
                    flyOffDirection = .favorite
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.dragOffset = .zero
                    }
                }
            }
    }

    private func performFlyOff(to decision: SwipeDecision) {
        let targetOffset: CGSize
        switch decision {
        case .keep:
            targetOffset = CGSize(width: 700, height: viewModel.dragOffset.height)
        case .delete:
            targetOffset = CGSize(width: -700, height: viewModel.dragOffset.height)
        case .favorite:
            targetOffset = CGSize(width: viewModel.dragOffset.width, height: -800)
        case .undecided:
            targetOffset = .zero
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.dragOffset = targetOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.processDecision(decision)
            viewModel.dragOffset = .zero
            flyOffDirection = nil
        }
    }
}
