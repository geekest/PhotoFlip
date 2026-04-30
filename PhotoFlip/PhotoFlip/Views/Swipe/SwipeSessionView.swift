import SwiftUI
import Photos

struct SwipeSessionView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @AppStorage("batchSize") private var batchSize: Int = 100
    @AppStorage("shuffleMode") private var shuffleModeRaw: String = ShuffleMode.recent.rawValue
    @AppStorage("shuffleAnchorDate") private var shuffleAnchorTimestamp: Double = 0
    @AppStorage("skipOrganizedPhotos") private var skipOrganizedPhotos: Bool = false

    @State private var viewModel: SwipeSessionViewModel?
    @State private var isLoadingNextRound = false
    @State private var isAllOrganized = false
    @State private var showDatePicker = false
    @State private var pendingPickerDate: Date = Date()
    @State private var previousModeBeforePicker: ShuffleMode = .recent

    private var shuffleMode: Binding<ShuffleMode> {
        Binding(
            get: { ShuffleMode(rawValue: shuffleModeRaw) ?? .recent },
            set: { shuffleModeRaw = $0.rawValue }
        )
    }

    private var anchorDate: Date? {
        shuffleAnchorTimestamp > 0
            ? Date(timeIntervalSince1970: shuffleAnchorTimestamp)
            : nil
    }

    var body: some View {
        Group {
            if isAllOrganized {
                AllOrganizedView(onClearAndRestart: {
                    OrganizedPhotosStore.shared.clearAll()
                    isAllOrganized = false
                    Task { await startNewRound() }
                })
            } else if let viewModel {
                if viewModel.isComplete {
                    CompletionContent(
                        viewModel: viewModel,
                        libraryManager: libraryManager,
                        isLoading: isLoadingNextRound,
                        sessionStartTime: appState.sessionStartTime,
                        onNewRound: { Task { await startNewRound() } }
                    )
                } else {
                    SwipeContent(
                        viewModel: viewModel,
                        libraryManager: libraryManager,
                        shuffleMode: shuffleMode,
                        anchorDate: anchorDate,
                        isReloading: isLoadingNextRound,
                        onModeSelected: handleModeSelected
                    )
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
        .onChange(of: batchSize) { _, _ in
            // Settings changed. Reload immediately if it's safe — i.e. the user
            // hasn't started swiping yet. Otherwise the new size kicks in on the
            // next "再来一轮".
            guard let vm = viewModel,
                  !isLoadingNextRound,
                  vm.currentIndex == 0,
                  !vm.isComplete
            else { return }
            Task { await startNewRound() }
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
        .sheet(isPresented: $showDatePicker, onDismiss: {
            // If the user dismissed without confirming, revert the mode change.
            if shuffleMode.wrappedValue == .specifiedDate && anchorDate == nil {
                shuffleMode.wrappedValue = previousModeBeforePicker
            }
        }) {
            DatePickerSheet(
                selection: $pendingPickerDate,
                onConfirm: { confirmedDate in
                    shuffleAnchorTimestamp = confirmedDate.timeIntervalSince1970
                    showDatePicker = false
                    Task { await startNewRound() }
                },
                onCancel: {
                    showDatePicker = false
                }
            )
        }
    }

    private func handleModeSelected(_ mode: ShuffleMode) {
        switch mode {
        case .specifiedDate:
            // Always re-open the wheel so the user can change the date.
            previousModeBeforePicker = (anchorDate != nil) ? .specifiedDate : .recent
            pendingPickerDate = anchorDate ?? Date()
            showDatePicker = true
        case .recent, .random:
            shuffleAnchorTimestamp = 0
            Task { await startNewRound() }
        }
    }

    private func startNewRound() async {
        // Persist decisions from the outgoing session before creating a new one.
        viewModel?.saveOrganizedPhotoIDs()

        isLoadingNextRound = true
        isAllOrganized = false
        let limit = batchSize > 0 ? batchSize : 100
        let mode = shuffleMode.wrappedValue
        let assets: [PHAsset]
        switch mode {
        case .recent:
            assets = await libraryManager.fetchAllPhotos(limit: limit)
        case .random:
            let excludeIDs = skipOrganizedPhotos ? OrganizedPhotosStore.shared.loadIDs() : []
            assets = await libraryManager.fetchRandomPhotos(limit: limit, excluding: excludeIDs)
        case .specifiedDate:
            let anchor = anchorDate ?? Date()
            assets = await libraryManager.fetchPhotos(before: anchor, limit: limit)
        }

        if assets.isEmpty && mode == .random && skipOrganizedPhotos {
            isAllOrganized = true
            isLoadingNextRound = false
            return
        }

        let newPhotos = assets.map { PhotoItem(asset: $0) }
        appState.pendingPhotos = newPhotos
        appState.sessionStartTime = Date()
        viewModel = SwipeSessionViewModel(photos: newPhotos, libraryManager: libraryManager)
        isLoadingNextRound = false
    }
}

// MARK: – Swipe content (card stack + top bar + progress + action pad)

private struct SwipeContent: View {
    @Bindable var viewModel: SwipeSessionViewModel
    let libraryManager: PhotoLibraryManager
    @Binding var shuffleMode: ShuffleMode
    let anchorDate: Date?
    let isReloading: Bool
    let onModeSelected: (ShuffleMode) -> Void

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }
    private var cardHeight: CGFloat { cardWidth * 4 / 3 }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top bar ──────────────────────────────────────────────
            HStack(alignment: .center) {
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

                CounterView(viewModel: viewModel)

                Spacer()

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

            // ── Progress bar ─────────────────────────────────────────
            progressBar
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            if let error = deleteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            // ── Mode selector + anchor caption ───────────────────────
            VStack(spacing: 4) {
                ShuffleModeSelector(selection: $shuffleMode, onSelect: onModeSelected)
                    .padding(.horizontal, 20)

                if shuffleMode == .specifiedDate, let anchor = anchorDate {
                    Text("从 \(anchor.formatted(.dateTime.year().month().day())) 起向前 \(viewModel.photos.count) 张")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)

            // ── Card stack ───────────────────────────────────────────
            ZStack {
                CardStackView(viewModel: viewModel)
                    .id(ObjectIdentifier(viewModel))
                    .frame(width: cardWidth, height: cardHeight)
                    .opacity(isReloading ? 0.3 : 1.0)

                if isReloading {
                    ProgressView()
                }
            }
            .padding(.vertical, 6)

            // ── Action pad ───────────────────────────────────────────
            actionPad
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
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

    // ── Progress bar ─────────────────────────────────────────────────
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, .pfOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: viewModel.photos.isEmpty ? 0 :
                                geo.size.width * CGFloat(viewModel.currentIndex) / CGFloat(viewModel.photos.count),
                            height: 4
                        )
                        .animation(.spring(response: 0.3), value: viewModel.currentIndex)
                }
            }
            .frame(height: 4)

            Text("\(min(viewModel.currentIndex + 1, viewModel.photos.count)) / \(viewModel.photos.count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    // ── Action pad buttons ────────────────────────────────────────────
    private var actionPad: some View {
        HStack(spacing: 22) {
            ActionPadButton(symbol: "xmark", color: .delete, size: 64, label: "删除") {
                buttonDecide(.delete)
            }
            ActionPadButton(symbol: "heart.fill", color: .pfOrange, size: 52, label: "收藏") {
                buttonDecide(.favorite)
            }
            ActionPadButton(symbol: "checkmark", color: .keep, size: 64, label: "保留") {
                buttonDecide(.keep)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func buttonDecide(_ decision: SwipeDecision) {
        guard !viewModel.isComplete else { return }

        if decision == .favorite {
            if let photo = viewModel.photos[safe: viewModel.currentIndex] {
                viewModel.markFavorite(for: photo)
            }
            return
        }

        let tx: CGFloat = decision == .keep ? 700 : -700
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
            viewModel.dragOffset = CGSize(width: tx, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            viewModel.processDecision(decision)
            viewModel.dragOffset = .zero
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

// MARK: – Action pad button

private struct ActionPadButton: View {
    let symbol: String
    let color: Color
    let size: CGFloat
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 5) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: size, height: size)
                        .shadow(color: color.opacity(0.28), radius: 8, y: 4)
                        .overlay(Circle().stroke(color.opacity(0.6), lineWidth: 1.5))
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.40, weight: .semibold))
                        .foregroundStyle(color)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
                .foregroundStyle(Color.pfOrange)
                .contentTransition(.numericText())
        }
        .font(.headline.monospacedDigit())
        .animation(.default, value: viewModel.deletedCount)
        .animation(.default, value: viewModel.keptCount)
        .animation(.default, value: viewModel.favoritedCount)
    }
}

// MARK: – Wheel date picker sheet

private struct DatePickerSheet: View {
    @Binding var selection: Date
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "选择日期",
                    selection: $selection,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()

                Text("将以此日期作为起点向前回溯照片")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            .navigationTitle("指定时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") { onConfirm(selection) }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: – Completion state

private struct CompletionContent: View {
    let viewModel: SwipeSessionViewModel
    let libraryManager: PhotoLibraryManager
    let isLoading: Bool
    let sessionStartTime: Date
    let onNewRound: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    private var elapsedString: String {
        let elapsed = Int(max(0, Date().timeIntervalSince(sessionStartTime)))
        if elapsed < 60 { return "\(elapsed) 秒" }
        let secs = elapsed % 60
        return secs > 0 ? "\(elapsed / 60) 分 \(secs) 秒" : "\(elapsed / 60) 分"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Gradient checkmark circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.green.opacity(0.45), radius: 18, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("整理完成！")
                    .font(.title.bold())
                Text("共浏览 \(viewModel.deletedCount + viewModel.keptCount) 张 · 用时 \(elapsedString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Stats grid
            HStack(spacing: 0) {
                statCell(count: viewModel.deletedCount, label: "已删除", color: .red)
                Divider().frame(height: 44)
                statCell(count: viewModel.keptCount, label: "已保留", color: .green)
                Divider().frame(height: 44)
                statCell(count: viewModel.favoritedCount, label: "已收藏", color: .pfOrange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 0.5))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 10) {
                if !viewModel.photosToDelete.isEmpty {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Group {
                            if isDeleting {
                                ProgressView()
                                    .tint(.red)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label(
                                    "待删除 \(viewModel.photosToDelete.count) 张，点击删除",
                                    systemImage: "trash"
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isDeleting)
                }

                if let error = deleteError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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
                .disabled(isLoading || isDeleting)
            }
            .padding(.horizontal)

            Spacer().frame(height: 20)
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

// MARK: – All-organized empty state

private struct AllOrganizedView: View {
    let onClearAndRestart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 18, y: 8)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("所有照片都整理过了！")
                    .font(.title2.bold())
                Text("随机模式下已没有未整理的照片。\n可以清除记录重新开始，或前往设置关闭此功能。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: onClearAndRestart) {
                Text("清除记录并重新开始")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer().frame(height: 20)
        }
    }
}

// MARK: – Previews

#Preview("整理视图") {
    SwipeSessionView()
        .environment(AppState())
        .environment(PhotoLibraryManager())
}

#Preview("完成界面") {
    let manager = PhotoLibraryManager()
    let viewModel = SwipeSessionViewModel(photos: [], libraryManager: manager)
    CompletionContent(
        viewModel: viewModel,
        libraryManager: manager,
        isLoading: false,
        sessionStartTime: Date().addingTimeInterval(-185),
        onNewRound: {}
    )
}

#Preview("计数器") {
    let viewModel = SwipeSessionViewModel(photos: [], libraryManager: PhotoLibraryManager())
    CounterView(viewModel: viewModel)
        .padding()
}
