import SwiftUI
import AppKit

struct AboutView: View {
    @ObservedObject var vm: PomodoroViewModel

    private let pagePadding: CGFloat = 20
    private let blockSpacing: CGFloat = 16
    private let cardCornerRadius: CGFloat = 12

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: blockSpacing) {
                pageHeader(
                    title: vm.appLanguage == .zh ? "关于" : "About",
                    subtitle: vm.appLanguage == .zh
                    ? "应用信息与版本说明"
                    : "App information and version details"
                )

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("FocusTime")
                                .font(.title3.weight(.semibold))

                            Text(vm.appLanguage == .zh ? "一个极简的专注计时器" : "A minimal focus timer")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Divider()

                    Text(
                        vm.appLanguage == .zh
                        ? "FocusTime 是一个 macOS 菜单栏专注计时器，支持番茄钟、专注统计、金币奖励与主题解锁。"
                        : "FocusTime is a macOS menu bar focus timer with Pomodoro sessions, study statistics, coin rewards, and unlockable themes."
                    )
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    infoRow(
                        title: vm.appLanguage == .zh ? "开发者" : "Developer",
                        value: "Xu Zihan"
                    )

                    infoRow(
                        title: vm.appLanguage == .zh ? "平台" : "Platform",
                        value: "macOS"
                    )

                    infoRow(
                        title: vm.appLanguage == .zh ? "版权" : "Copyright",
                        value: "© 2026 Xu Zihan"
                    )
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            }
            .padding(pagePadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func pageHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview("Content") {
    AboutView(vm: PomodoroViewModel())
        .frame(width: 600, height: 420)
}
