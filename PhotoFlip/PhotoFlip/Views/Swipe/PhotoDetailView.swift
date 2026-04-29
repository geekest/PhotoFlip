import SwiftUI
import Photos

struct PhotoDetailView: View {
    let asset: PHAsset

    @Environment(\.dismiss) private var dismiss
    @State private var loader = ImageLoader()
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var locationName: String?
    @State private var shareURL: URL?
    @State private var isPreparingShare = false
    @State private var shareError: String?

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
                    Button {
                        Task { await prepareShare() }
                    } label: {
                        if isPreparingShare {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.callout)
                        }
                    }
                    .disabled(isPreparingShare)
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
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { cleanupShareFile() } }
        )) {
            if let url = shareURL {
                ShareSheet(items: [url], onComplete: cleanupShareFile)
            }
        }
        .alert("无法分享", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("好") { shareError = nil }
        } message: {
            Text(shareError ?? "")
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

    private func prepareShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        defer { isPreparingShare = false }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.version = .current

        let result: (data: Data, uti: String?)? = await withCheckedContinuation { cont in
            var resumed = false
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, uti, _, info in
                // Opportunistic delivery may invoke the handler multiple times.
                guard !resumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded { return }
                resumed = true
                if let data {
                    cont.resume(returning: (data, uti))
                } else {
                    cont.resume(returning: nil)
                }
            }
        }

        guard let payload = result else {
            shareError = "无法读取原始照片数据"
            return
        }

        let ext = fileExtension(forUTI: payload.uti)
        let baseName = asset.creationDate
            .map { "PhotoFlip-\(Int($0.timeIntervalSince1970))" } ?? "PhotoFlip-\(UUID().uuidString)"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(baseName)
            .appendingPathExtension(ext)
        do {
            try payload.data.write(to: url, options: .atomic)
            shareURL = url
        } catch {
            shareError = error.localizedDescription
        }
    }

    private func cleanupShareFile() {
        if let url = shareURL {
            try? FileManager.default.removeItem(at: url)
        }
        shareURL = nil
    }

    private func fileExtension(forUTI uti: String?) -> String {
        switch uti {
        case "public.heic", "public.heif": return "heic"
        case "public.png":                 return "png"
        case "public.jpeg":                return "jpg"
        case "com.compuserve.gif":         return "gif"
        case "public.tiff":                return "tiff"
        default:                            return "jpg"
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
