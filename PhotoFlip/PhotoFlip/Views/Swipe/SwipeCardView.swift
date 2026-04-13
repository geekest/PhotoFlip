import SwiftUI

struct SwipeCardView: View {
    let photoItem: PhotoItem
    @Bindable var viewModel: SwipeSessionViewModel
    let isTopCard: Bool
    let loader: ImageLoader

    @State private var flyOffDirection: SwipeDecision?
    @State private var showDetail = false

    private let screenWidth = UIScreen.main.bounds.width
    private let dragThresholdX: CGFloat = 100

    var body: some View {
        ZStack {
            // Background shown while image loads
            Color(UIColor.secondarySystemBackground)

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .allowsHitTesting(false)
            } else {
                ProgressView()
            }

            if isTopCard {
                DecisionOverlay(dragOffset: viewModel.dragOffset)

                // Heart / favorite button – bottom-right corner
                Button {
                    viewModel.markFavorite(for: photoItem)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                        .shadow(color: .black.opacity(0.4), radius: 6)
                        .padding(20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
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
        .onTapGesture {
            // Only open detail when it's a stationary tap on the top card
            // (DragGesture minimumDistance:10 ensures drags don't trigger this)
            if isTopCard { showDetail = true }
        }
        .onChange(of: flyOffDirection) { _, direction in
            guard let direction else { return }
            performFlyOff(to: direction)
        }
        .sheet(isPresented: $showDetail) {
            PhotoDetailView(asset: photoItem.asset)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                viewModel.dragOffset = value.translation
            }
            .onEnded { value in
                let x = value.translation.width

                if x > dragThresholdX {
                    flyOffDirection = .keep
                } else if x < -dragThresholdX {
                    flyOffDirection = .delete
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
        default:
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
