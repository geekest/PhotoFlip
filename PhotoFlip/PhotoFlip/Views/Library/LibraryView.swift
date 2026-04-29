import SwiftUI
import Photos

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @State private var allAssets: [PHAsset] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedAsset: PHAsset?
    @State private var organizedCount: Int = 0
    @State private var deletedCount: Int = 0

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    private var pendingDeleteIDs: Set<String> {
        Set(appState.pendingPhotos.filter { $0.decision == .delete }.map { $0.id })
    }

    private var filteredAssets: [PHAsset] {
        guard !searchText.isEmpty else { return allAssets }
        let lowered = searchText.lowercased()
        return allAssets.filter { asset in
            guard let date = asset.creationDate else { return false }
            let str = DateFormatter.pfMonthYear.string(from: date)
            return str.lowercased().contains(lowered)
        }
    }

    private var photoGroups: [(title: String, assets: [PHAsset])] {
        let calendar = Calendar.current
        var buckets: [Date: [PHAsset]] = [:]
        for asset in filteredAssets {
            let date = asset.creationDate ?? .distantPast
            let month = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            ) ?? date
            buckets[month, default: []].append(asset)
        }
        return buckets.sorted { $0.key > $1.key }
            .map { (DateFormatter.pfMonthYear.string(from: $0.key), $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && allAssets.isEmpty {
                    ProgressView("加载中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        // ── Large title + search bar ───────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(allAssets.count) 张照片")
                                .font(.system(size: 34, weight: .bold))
                                .tracking(-0.5)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                            // Historical stats
                            HStack(spacing: 0) {
                                Text("已整理 ")
                                    .foregroundStyle(.secondary)
                                Text("\(organizedCount)")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                                Text(" 张")
                                    .foregroundStyle(.secondary)
                                Text("  ·  ")
                                    .foregroundStyle(.secondary)
                                Text("已删除 ")
                                    .foregroundStyle(.secondary)
                                Text("\(deletedCount)")
                                    .foregroundStyle(Color.pfOrange)
                                    .fontWeight(.semibold)
                                Text(" 张")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .monospacedDigit()
                            .padding(.horizontal, 20)

                            // Search bar
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.tertiary)
                                TextField("搜索月份（如 2024年3月）", text: $searchText)
                                    .font(.body)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 16)

                            // Pending delete banner
                            if !pendingDeleteIDs.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                    Text("本次会话有 \(pendingDeleteIDs.count) 张待删除 · 红色标记")
                                        .font(.callout.weight(.medium))
                                }
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 4)

                        // ── Photo groups ───────────────────────────────
                        if photoGroups.isEmpty {
                            ContentUnavailableView(
                                searchText.isEmpty ? "相册为空" : "没有匹配的照片",
                                systemImage: searchText.isEmpty ? "photo.on.rectangle" : "magnifyingglass"
                            )
                            .padding(.top, 60)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(photoGroups, id: \.title) { group in
                                    // Month header
                                    Text(group.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 14)
                                        .padding(.bottom, 8)

                                    // Grid
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(group.assets, id: \.localIdentifier) { asset in
                                            LibraryPhotoCell(
                                                asset: asset,
                                                isPendingDelete: pendingDeleteIDs.contains(asset.localIdentifier)
                                            ) {
                                                selectedAsset = asset
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }
                    }
                    .refreshable { await loadPhotos() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("图库").font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .sheet(isPresented: .init(
                get: { selectedAsset != nil },
                set: { if !$0 { selectedAsset = nil } }
            )) {
                if let asset = selectedAsset {
                    PhotoDetailView(asset: asset)
                }
            }
            .task { await loadPhotos() }
        }
    }

    private func loadPhotos() async {
        isLoading = true
        allAssets = await libraryManager.fetchAllPhotos()
        organizedCount = OrganizedPhotosStore.shared.count
        deletedCount = OrganizedPhotosStore.shared.deletedCount
        isLoading = false
    }
}

// MARK: – Month-year formatter

private extension DateFormatter {
    static let pfMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f
    }()
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

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: 22, height: 22)
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .font(.caption2)
                }
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
