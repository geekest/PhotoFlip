import SwiftUI

struct SettingsView: View {
    @AppStorage("batchSize") private var batchSize: Int = 100
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("skipOrganizedPhotos") private var skipOrganizedPhotos: Bool = false

    @State private var organizedCount: Int = 0
    @State private var showClearConfirmation = false

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Display mode ──────────────────────────────────────
                Section {
                    Picker("显示模式", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("显示")
                } footer: {
                    Text("选择「自动」将跟随系统的深色模式设定。")
                }

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

                // ── Random mode ───────────────────────────────────────
                Section {
                    Toggle("跳过已整理的照片", isOn: $skipOrganizedPhotos)

                    HStack {
                        Text("已记录 \(organizedCount) 张")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("清除记录") {
                            showClearConfirmation = true
                        }
                        .foregroundStyle(organizedCount > 0 ? Color.red : Color.secondary)
                        .disabled(organizedCount == 0)
                    }
                    .font(.subheadline)
                } header: {
                    Text("随机模式")
                } footer: {
                    Text("开启后，在随机模式中已整理过的照片不会再次出现。")
                }
                .onAppear {
                    organizedCount = OrganizedPhotosStore.shared.count
                }
                .confirmationDialog("确认清除所有整理记录？", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                    Button("清除", role: .destructive) {
                        OrganizedPhotosStore.shared.clearAll()
                        organizedCount = 0
                    }
                    Button("取消", role: .cancel) {}
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
