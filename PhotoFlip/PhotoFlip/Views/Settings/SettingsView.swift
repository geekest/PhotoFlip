import SwiftUI

struct SettingsView: View {
    @AppStorage("batchSize") private var batchSize: Int = 100

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Photo deletion ───────────────────────────────────
                Section("照片删除") {
                    HStack {
                        Text("单次整理数量")
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                batchSize = max(10, batchSize - 10)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(batchSize <= 10 ? Color.secondary : Color.accentColor)
                            }
                            .buttonStyle(.plain)
                            .disabled(batchSize <= 10)

                            Text("\(batchSize)")
                                .frame(width: 44)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()

                            Button {
                                batchSize = min(500, batchSize + 10)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(batchSize >= 500 ? Color.secondary : Color.accentColor)
                            }
                            .buttonStyle(.plain)
                            .disabled(batchSize >= 500)
                        }
                    }
                }

                // ── About ────────────────────────────────────────────
                Section("关于") {
                    Button {
                        if let url = URL(string: "mailto:feedback@photoflip.app") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("反馈", systemImage: "envelope")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        if let url = URL(string: "https://www.xiaohongshu.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("开发者小红书", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        if let url = URL(string: "https://apps.apple.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("给个好评", systemImage: "hand.thumbsup")
                            .foregroundStyle(.primary)
                    }

                    HStack {
                        Text("版本号")
                        Spacer()
                        Text(versionString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
