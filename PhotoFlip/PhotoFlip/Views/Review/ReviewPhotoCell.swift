import SwiftUI
import Photos

struct ReviewPhotoCell: View {
    let item: PhotoItem
    let onTap: () -> Void

    @State private var loader = ImageLoader()

    private let size: CGFloat = (UIScreen.main.bounds.width - 6) / 3

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(ProgressView())
            }

            // Delete badge overlay
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(width: size, height: size)

            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            loader.load(
                asset: item.asset,
                targetSize: CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale)
            )
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
