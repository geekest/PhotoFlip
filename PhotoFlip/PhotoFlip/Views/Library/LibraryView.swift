import SwiftUI
import Photos

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @State private var allAssets: [PHAsset] = []
    @State private var isLoading = false
    @State private var selectedAsset: PHAsset?

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    /// IDs of photos in the current session marked for deletion.
    private var pendingDeleteIDs: Set<String> {
        Set(appState.pendingPhotos.filter { $0.decision == .delete }.map { $0.id })
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && allAssets.isEmpty {
                    ProgressView("加载中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allAssets.isEmpty {
                    ContentUnavailableView("相册为空", systemImage: "photo.on.rectangle")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(allAssets, id: \.localIdentifier) { asset in
                                LibraryPhotoCell(
                                    asset: asset,
                                    isPendingDelete: pendingDeleteIDs.contains(asset.localIdentifier)
                                ) {
                                    selectedAsset = asset
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("图库")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: .init(
                get: { selectedAsset != nil },
                set: { if !$0 { selectedAsset = nil } }
            )) {
                if let asset = selectedAsset {
                    PhotoDetailView(asset: asset)
                }
            }
            .task { await loadPhotos() }
            .refreshable { await loadPhotos() }
        }
    }

    private func loadPhotos() async {
        isLoading = true
        allAssets = await libraryManager.fetchAllPhotos()
        isLoading = false
    }
}

// MARK: – Grid cell

private struct LibraryPhotoCell: View {
    let asset: PHAsset
    let isPendingDelete: Bool
    let onTap: () -> Void

    @State private var loader = ImageLoader()

    private let size: CGFloat = (UIScreen.main.bounds.width - 4) / 3

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: size, height: size)
            }

            if isPendingDelete {
                Color.red.opacity(0.45)
                    .frame(width: size, height: size)

                Image(systemName: "trash.fill")
                    .foregroundStyle(.white)
                    .font(.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(6)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            loader.load(
                asset: asset,
                targetSize: CGSize(
                    width: size * UIScreen.main.scale,
                    height: size * UIScreen.main.scale
                )
            )
        }
        .onDisappear { loader.cancel() }
    }
}

#Preview {
    LibraryView()
        .environment(AppState())
        .environment(PhotoLibraryManager())
}
