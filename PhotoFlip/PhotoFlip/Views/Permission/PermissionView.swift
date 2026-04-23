import SwiftUI
import Photos

struct PermissionView: View {
    @Environment(AppState.self) private var appState
    @Environment(PhotoLibraryManager.self) private var libraryManager

    @AppStorage("batchSize") private var batchSize: Int = 100

    @State private var isDenied = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Gradient app icon
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 108, height: 108)
                    .shadow(color: Color.accentColor.opacity(0.42), radius: 20, x: 0, y: 10)
                Image(systemName: "photo.stack")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 32)

            // Title + description
            VStack(spacing: 12) {
                Text("快速整理相册")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.5)
                Text("PhotoFlip 需要访问您的相册，帮您通过\n左右滑动快速整理和删除不需要的照片。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 24)

            // Gesture guide card
            VStack(spacing: 0) {
                gestureRow(symbol: "arrow.right", color: .green, label: "右滑 — 保留照片")
                Divider().padding(.leading, 56)
                gestureRow(symbol: "arrow.left", color: .red, label: "左滑 — 标记删除")
                Divider().padding(.leading, 56)
                gestureRow(symbol: "heart.fill", color: .pfOrange, label: "点心 — 加入收藏")
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .frame(maxWidth: 300)
            .padding(.top, 36)

            Spacer()

            // Bottom CTA
            VStack(spacing: 14) {
                if isDenied {
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
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        Task { await requestAccess() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Text("允许访问相册").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }

                Label {
                    Text("照片不会离开你的设备")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } icon: {
                    Image(systemName: "lock.shield")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    private func gestureRow(symbol: String, color: Color, label: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .font(.body.weight(.medium))
            }
            Text(label).font(.body)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func requestAccess() async {
        isLoading = true
        let status = await libraryManager.requestAuthorization()
        switch status {
        case .authorized, .limited:
            let limit = batchSize > 0 ? batchSize : 100
            let assets = await libraryManager.fetchAllPhotos(limit: limit)
            appState.pendingPhotos = assets.map { PhotoItem(asset: $0) }
            appState.sessionStartTime = Date()
            appState.isPermissionGranted = true
        case .denied, .restricted:
            isDenied = true
            isLoading = false
        default:
            isLoading = false
        }
    }
}

#Preview {
    PermissionView()
        .environment(AppState())
        .environment(PhotoLibraryManager())
}
