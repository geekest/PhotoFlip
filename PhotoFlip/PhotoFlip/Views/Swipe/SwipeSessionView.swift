import SwiftUI

struct SwipeSessionView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: SwipeSessionViewModel?

    var body: some View {
        Group {
            if let viewModel {
                SwipeContent(viewModel: viewModel)
            } else {
                ProgressView("准备中…")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SwipeSessionViewModel(
                    photos: appState.pendingPhotos,
                    appState: appState
                )
            }
        }
    }
}

private struct SwipeContent: View {
    @Bindable var viewModel: SwipeSessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            ProgressBarView(
                current: viewModel.currentIndex,
                total: viewModel.photos.count
            )
            .padding(.top, 8)

            CardStackView(viewModel: viewModel)
                .padding(.horizontal, 16)

            HStack(spacing: 48) {
                actionButton(
                    icon: "xmark.circle.fill",
                    color: .delete,
                    action: { viewModel.processDecision(.delete) }
                )
                actionButton(
                    icon: "arrow.uturn.left.circle.fill",
                    color: .secondary,
                    action: { viewModel.undo() },
                    disabled: !viewModel.canUndo
                )
                actionButton(
                    icon: "star.circle.fill",
                    color: .favorite,
                    action: { viewModel.processDecision(.favorite) }
                )
                actionButton(
                    icon: "checkmark.circle.fill",
                    color: .keep,
                    action: { viewModel.processDecision(.keep) }
                )
            }
            .padding(.bottom, 32)
        }
    }

    private func actionButton(
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(disabled ? Color.secondary.opacity(0.4) : color)
        }
        .disabled(disabled)
    }
}
