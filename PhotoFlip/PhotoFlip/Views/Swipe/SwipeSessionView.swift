import SwiftUI

struct SwipeSessionView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @AppStorage("batchSize") private var batchSize: Int = 100

    @State private var viewModel: SwipeSessionViewModel?
    @State private var isLoadingNextRound = false

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isComplete {
                    CompletionContent(
                        viewModel: viewModel,
                        isLoading: isLoadingNextRound,
                        onNewRound: { Task { await startNewRound() } }
                    )
                } else {
                    SwipeContent(viewModel: viewModel, libraryManager: libraryManager)
                }
            } else {
                ProgressView("准备中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: appState.pendingPhotos) { _, newPhotos in
            if !newPhotos.isEmpty && viewModel == nil {
                viewModel = SwipeSessionViewModel(photos: newPhotos, libraryManager: libraryManager)
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            if appState.pendingPhotos.isEmpty {
                Task { await startNewRound() }
            } else {
                viewModel = SwipeSessionViewModel(
                    photos: appState.pendingPhotos,
                    libraryManager: libraryManager
                )
            }
        }
    }

    private func startNewRound() async {
        isLoadingNextRound = true
        let limit = batchSize > 0 ? batchSize : 100
        let assets = await libraryManager.fetchAllPhotos(limit: limit)
        let newPhotos = assets.map { PhotoItem(asset: $0) }
        appState.pendingPhotos = newPhotos
        appState.sessionStartTime = Date()
        viewModel = SwipeSessionViewModel(photos: newPhotos, libraryManager: libraryManager)
        isLoadingNextRound = false
    }
}

// MARK: – Swipe content (card stack + top bar)

private struct SwipeContent: View {
    @Bindable var viewModel: SwipeSessionViewModel
    let libraryManager: PhotoLibraryManager

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }
    private var cardHeight: CGFloat { cardWidth * 4 / 3 }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top bar ──────────────────────────────────────────────
            HStack(alignment: .center) {
                // Left: trash + pending count
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label {
                        if viewModel.photosToDelete.count > 0 {
                            Text("\(viewModel.photosToDelete.count)")
                                .font(.callout.bold())
                        }
                    } icon: {
                        Image(systemName: "trash")
                    }
                    .foregroundStyle(viewModel.photosToDelete.isEmpty ? Color.secondary : Color.red)
                }
                .disabled(viewModel.photosToDelete.isEmpty || isDeleting)

                Spacer()

                // Center: X · Y · Z counter
                CounterView(viewModel: viewModel)

                Spacer()

                // Right: undo
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.left")
                        .foregroundStyle(viewModel.canUndo ? Color.primary : Color.secondary.opacity(0.4))
                }
                .disabled(!viewModel.canUndo)
            }
            .font(.title3)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)

            if let error = deleteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            // ── Card stack ───────────────────────────────────────────
            CardStackView(viewModel: viewModel)
                .frame(width: cardWidth, height: cardHeight)
                .padding(.vertical, 8)
        }
        .confirmationDialog(
            "确认删除 \(viewModel.photosToDelete.count) 张照片？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                Task { await performDelete() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作无法撤销")
        }
    }

    private func performDelete() async {
        isDeleting = true
        deleteError = nil
        do {
            let toDelete = viewModel.photosToDelete
            try await libraryManager.deleteAssets(toDelete.map { $0.asset })
            viewModel.markActuallyDeleted(ids: Set(toDelete.map { $0.id }))
        } catch {
            deleteError = error.localizedDescription
        }
        isDeleting = false
    }
}

// MARK: – Counter (X · Y · Z)

private struct CounterView: View {
    let viewModel: SwipeSessionViewModel

    var body: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.deletedCount)")
                .foregroundStyle(.red)
                .contentTransition(.numericText())
            Text("·").foregroundStyle(.secondary)
            Text("\(viewModel.keptCount)")
                .foregroundStyle(.green)
                .contentTransition(.numericText())
            Text("·").foregroundStyle(.secondary)
            Text("\(viewModel.favoritedCount)")
                .foregroundStyle(.orange)
                .contentTransition(.numericText())
        }
        .font(.headline.monospacedDigit())
        .animation(.default, value: viewModel.deletedCount)
        .animation(.default, value: viewModel.keptCount)
        .animation(.default, value: viewModel.favoritedCount)
    }
}

// MARK: – Completion state

private struct CompletionContent: View {
    let viewModel: SwipeSessionViewModel
    let isLoading: Bool
    let onNewRound: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("整理完成！")
                .font(.title.bold())

            HStack(spacing: 0) {
                statCell(count: viewModel.deletedCount, label: "已删除", color: .red)
                Divider().frame(height: 44)
                statCell(count: viewModel.keptCount, label: "已保留", color: .green)
                Divider().frame(height: 44)
                statCell(count: viewModel.favoritedCount, label: "已收藏", color: .orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button {
                onNewRound()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Text("再来一轮").frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .disabled(isLoading)

            Spacer().frame(height: 20)
        }
    }

    private func statCell(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("整理视图") {
    SwipeSessionView()
        .environment(AppState())
        .environment(PhotoLibraryManager())
}

#Preview("完成界面") {
    let viewModel = SwipeSessionViewModel(photos: [], libraryManager: PhotoLibraryManager())
    CompletionContent(viewModel: viewModel, isLoading: false, onNewRound: {})
}

#Preview("计数器") {
    let viewModel = SwipeSessionViewModel(photos: [], libraryManager: PhotoLibraryManager())
    CounterView(viewModel: viewModel)
        .padding()
}
