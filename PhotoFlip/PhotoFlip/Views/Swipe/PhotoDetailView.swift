import SwiftUI
import Photos

struct PhotoDetailView: View {
    let asset: PHAsset

    @Environment(\.dismiss) private var dismiss
    @State private var loader = ImageLoader()
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var locationName: String?

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let image = loader.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(magnificationGesture)
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if scale > 1 {
                                        scale = 1; lastScale = 1
                                    } else {
                                        scale = 2; lastScale = 2
                                    }
                                }
                            }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                // Bottom info strip
                HStack {
                    if let date = asset.creationDate {
                        Label(date.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    if let name = locationName {
                        Label(name, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else if asset.location == nil {
                        Text("双击放大")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("去照片查看") { openInPhotos() }
                        .font(.callout)
                }
            }
        }
        .onAppear {
            loader.load(
                asset: asset,
                targetSize: CGSize(
                    width: UIScreen.main.bounds.width * UIScreen.main.scale,
                    height: UIScreen.main.bounds.height * UIScreen.main.scale
                )
            )
        }
        .onDisappear { loader.cancel() }
        .task(id: asset.localIdentifier) {
            await loadLocation()
        }
    }

    private func loadLocation() async {
        guard let location = asset.location else {
            locationName = nil
            return
        }
        let key = asset.localIdentifier
        if let cached = LocationResolver.cached(for: key) {
            locationName = cached
            return
        }
        locationName = nil
        let resolved = await LocationResolver.resolve(location: location, assetID: key)
        if asset.localIdentifier == key {
            locationName = resolved
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in scale = max(1, lastScale * value) }
            .onEnded { _ in
                lastScale = scale
                if scale < 1 {
                    withAnimation(.spring()) { scale = 1; lastScale = 1 }
                }
            }
    }

    private func openInPhotos() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    let assets = PHAsset.fetchAssets(with: .image, options: nil)
    if let asset = assets.firstObject {
        PhotoDetailView(asset: asset)
    } else {
        ContentUnavailableView("需要照片权限", systemImage: "photo")
    }
}
