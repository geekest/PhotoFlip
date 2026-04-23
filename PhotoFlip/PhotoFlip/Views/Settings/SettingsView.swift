import SwiftUI

struct SettingsView: View {
    @AppStorage("batchSize") private var batchSize: Int = 100

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Photo deletion ────────────────────────────────────
                Section {
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
                } header: {
                    Text("照片删除")
                } footer: {
                    Text("每次滑动会话最多显示的照片张数。建议 50–150 张，避免疲劳。")
                }

                // ── About ─────────────────────────────────────────────
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

                // ── Footer ────────────────────────────────────────────
                Section {
                } footer: {
                    Text("PhotoFlip · 用手势整理你的回忆")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
