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
                    ContentUnavailableView {
                        ProgressView()
                    } description: {
                        Text("正在读取相册")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PhotoFlipStyle.sectionSpacing) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("你的相册")
                                        .font(.title2.bold())
                                    Text("\(allAssets.count) 张照片")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                Spacer()
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                            }

                            HStack(spacing: 12) {
                                LibraryStatCard(
                                    value: organizedCount,
                                    label: "已整理",
                                    symbol: "checkmark.circle",
                                    color: .accentColor
                                )
                                LibraryStatCard(
                                    value: deletedCount,
                                    label: "已删除",
                                    symbol: "trash",
                                    color: .pfOrange
                                )
                            }

                            if !pendingDeleteIDs.isEmpty {
                                Label {
                                    Text("本次会话有 \(pendingDeleteIDs.count) 张待删除照片")
                                        .font(.callout.weight(.medium))
                                } icon: {
                                    Image(systemName: "trash.fill")
                                }
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .photoFlipCard(cornerRadius: PhotoFlipStyle.controlCornerRadius)
                                .accessibilityHint(Text("整理页中可以确认或撤销删除标记"))
                            }
                        }
                        .padding(.horizontal, PhotoFlipStyle.pagePadding)
                        .padding(.top, 8)

                        if photoGroups.isEmpty {
                            ContentUnavailableView(
                                searchText.isEmpty ? "相册为空" : "没有匹配的照片",
                                systemImage: searchText.isEmpty ? "photo.on.rectangle" : "magnifyingglass",
                                description: Text(searchText.isEmpty ? "允许访问相册后，照片会显示在这里。" : "试试搜索其他月份。")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 36)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(photoGroups, id: \.title) { group in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(group.title)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(group.assets.count) 张")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                    .padding(.horizontal, PhotoFlipStyle.pagePadding)
                                    .padding(.top, 18)
                                    .padding(.bottom, 10)

                                    LazyVGrid(columns: columns, spacing: 4) {
                                        ForEach(group.assets, id: \.localIdentifier) { asset in
                                            LibraryPhotoCell(
                                                asset: asset,
                                                isPendingDelete: pendingDeleteIDs.contains(asset.localIdentifier)
                                            ) {
                                                selectedAsset = asset
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                    }
                    .refreshable { await loadPhotos() }
                }
            }
            .navigationTitle("图库")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索月份")
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

    private let size: CGFloat = (UIScreen.main.bounds.width - 24) / 3

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
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityLabel(Text(isPendingDelete ? "照片，待删除" : "照片"))
        .accessibilityHint(Text("双击查看详情"))
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

private struct LibraryStatCard: View {
    let value: Int
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .photoFlipCard(cornerRadius: PhotoFlipStyle.controlCornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label) \(value) 张"))
    }
}

#Preview {
    LibraryView()
        .environment(AppState())
        .environment(PhotoLibraryManager())
}
