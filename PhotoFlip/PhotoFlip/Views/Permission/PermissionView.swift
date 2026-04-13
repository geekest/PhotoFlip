import SwiftUI
import Photos

struct PermissionView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @State private var isDenied = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("快速整理相册")
                    .font(.largeTitle.bold())

                Text("PhotoFlip 需要访问您的相册，帮您通过左右滑动快速整理和删除不需要的照片。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            if isDenied {
                VStack(spacing: 16) {
                    Text("相册访问被拒绝，请前往设置开启权限。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("前往设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            } else {
                Button {
                    Task { await requestAccess() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("允许访问相册")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(isLoading)
            }

            Spacer().frame(height: 20)
        }
    }

    private func requestAccess() async {
        isLoading = true
        let status = await libraryManager.requestAuthorization()
        switch status {
        case .authorized, .limited:
            appState.screen = .loading
            let assets = await libraryManager.fetchAllPhotos()
            appState.pendingPhotos = assets.map { PhotoItem(asset: $0) }
            appState.sessionStartTime = Date()
            appState.screen = .swiping
        case .denied, .restricted:
            isDenied = true
            isLoading = false
        default:
            isLoading = false
        }
    }
}
