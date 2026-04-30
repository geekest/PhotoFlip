import SwiftUI
import Photos

struct SwipeCardView: View {
    let photoItem: PhotoItem
    @Bindable var viewModel: SwipeSessionViewModel
    let isTopCard: Bool
    let loader: ImageLoader

    @State private var flyOffDirection: SwipeDecision?
    @State private var showDetail = false
    @State private var locationName: String?

    private let screenWidth = UIScreen.main.bounds.width
    private let dragThresholdX: CGFloat = 100

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            if let image = loader.image {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
                .allowsHitTesting(false)
            } else {
                ProgressView()
            }

            // Bottom gradient info strip
            bottomInfoStrip
                .allowsHitTesting(false)

            if isTopCard {
                DecisionOverlay(dragOffset: viewModel.dragOffset)

                // Heart / favorite button — circular white button with orange heart
                Button {
                    viewModel.markFavorite(for: photoItem)
                } label: {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 52, height: 52)
                            .shadow(color: .black.opacity(0.22), radius: 6, y: 3)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.pfOrange)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .cornerRadius(20)
        .shadow(color: isTopCard ? .black.opacity(0.28) : .black.opacity(0.14),
                radius: isTopCard ? 20 : 8, x: 0, y: isTopCard ? 12 : 4)
        .offset(isTopCard ? viewModel.dragOffset : .zero)
        .rotationEffect(
            isTopCard
                ? .degrees(Double(viewModel.dragOffset.width / screenWidth) * 15)
                : .zero
        )
        .gesture(isTopCard ? dragGesture : nil)
        .onTapGesture {
            if isTopCard { showDetail = true }
        }
        .onChange(of: flyOffDirection) { _, direction in
            guard let direction else { return }
            performFlyOff(to: direction)
        }
        .task(id: photoItem.id) {
            await loadLocation()
        }
        .sheet(isPresented: $showDetail) {
            PhotoDetailView(asset: photoItem.asset)
        }
    }

    @ViewBuilder
    private var bottomInfoStrip: some View {
        if photoItem.asset.creationDate != nil || photoItem.asset.location != nil {
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.65)
            )
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    if let date = photoItem.asset.creationDate {
                        Label(date.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption2)
                    }
                    if let name = locationName {
                        Label(name, systemImage: "mappin")
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .foregroundStyle(.white)
                .padding(14)
            }
        }
    }

    private func loadLocation() async {
        guard let location = photoItem.asset.location else {
            locationName = nil
            return
        }
        let key = photoItem.id
        if let cached = LocationResolver.cached(for: key) {
            locationName = cached
            return
        }
        locationName = nil
        let resolved = await LocationResolver.resolve(location: location, assetID: key)
        // .task(id:) already cancels stale work, but guard once more in case the
        // view was reused with a different photo while we awaited.
        if photoItem.id == key {
            locationName = resolved
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

#Preview {
    let assets = PHAsset.fetchAssets(with: .image, options: nil)
    if let asset = assets.firstObject {
        let photo = PhotoItem(asset: asset)
        let viewModel = SwipeSessionViewModel(photos: [photo], libraryManager: PhotoLibraryManager())
        SwipeCardView(photoItem: photo, viewModel: viewModel, isTopCard: true, loader: ImageLoader())
            .aspectRatio(3/4, contentMode: .fit)
            .padding()
    } else {
        ContentUnavailableView("需要照片权限", systemImage: "photo")
    }
}
