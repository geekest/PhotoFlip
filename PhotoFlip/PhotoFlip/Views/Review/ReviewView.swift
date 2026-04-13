import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @State private var viewModel: ReviewViewModel?
    @State private var showConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let viewModel {
                ReviewContent(
                    viewModel: viewModel,
                    isDeleting: isDeleting,
                    errorMessage: errorMessage,
                    onConfirm: { showConfirmation = true },
                    onFinishEmpty: {
                        let duration = Date().timeIntervalSince(appState.sessionStartTime)
                        let keptCount = viewModel.photos.filter {
                            $0.decision == .keep || $0.decision == .favorite
                        }.count
                        appState.screen = .completion(deleted: 0, kept: keptCount, duration: duration)
                    }
                )
                .confirmationDialog(
                    "确认删除 \(viewModel.toDelete.count) 张照片？",
                    isPresented: $showConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("删除", role: .destructive) {
                        Task { await performDelete(viewModel: viewModel) }
                    }
                    Button("取消", role: .cancel) {}
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ReviewViewModel(
                    photos: appState.pendingPhotos,
                    libraryManager: libraryManager,
                    appState: appState,
                    sessionStartTime: appState.sessionStartTime
                )
            }
        }
    }

    private func performDelete(viewModel: ReviewViewModel) async {
        isDeleting = true
        do {
            try await viewModel.confirmDelete()
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
        }
    }
}

private struct ReviewContent: View {
    @Bindable var viewModel: ReviewViewModel
    let isDeleting: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onFinishEmpty: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.toDelete.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("没有要删除的照片")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.toDelete) { item in
                                ReviewPhotoCell(item: item) {
                                    viewModel.removeFromDelete(id: item.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("待删除照片")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    Button {
                        if viewModel.toDelete.isEmpty {
                            onFinishEmpty()
                        } else {
                            onConfirm()
                        }
                    } label: {
                        Group {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else if viewModel.toDelete.isEmpty {
                                Text("完成（不删除）")
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("删除 \(viewModel.toDelete.count) 张")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.toDelete.isEmpty ? .accentColor : .red)
                    .controlSize(.large)
                    .padding()
                    .disabled(isDeleting)
                }
                .background(.regularMaterial)
            }
        }
    }
}
