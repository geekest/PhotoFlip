import SwiftUI
import Photos

struct PhotoDetailView: View {
    let asset: PHAsset

    @Environment(\.dismiss) private var dismiss
    @State private var loader = ImageLoader()
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

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
        // iOS does not expose a deep-link URL for specific photos;
        // we open Photos.app at its root.
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}
