import SwiftUI
import AppKit

struct AboutView: View {
    @ObservedObject var vm: PomodoroViewModel

    // MARK: - Layout
    private let pagePadding: CGFloat = 20
    private let blockSpacing: CGFloat = 16
    private let cardCornerRadius: CGFloat = 12
    private let cardPadding: CGFloat = 16
    private let iconSize: CGFloat = 60
    private let iconCornerRadius: CGFloat = 14

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: blockSpacing) {
                headerSection
                aboutCard
            }
            .padding(pagePadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sections
private extension AboutView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pageTitle)
                .font(.title2.weight(.semibold))

            Text(pageSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var aboutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            appIdentitySection
            Divider()
            descriptionSection
            Divider()
            metaInfoSection
        }
        .padding(cardPadding)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }

    var appIdentitySection: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.title3.weight(.semibold))

                Text(appTagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(appVersion)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    var descriptionSection: some View {
        Text(appDescription)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
    }

    var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(title: developerTitle, value: developerName)
            infoRow(title: platformTitle, value: platformName)
            infoRow(title: copyrightTitle, value: copyrightText)
        }
    }
}

// MARK: - Components
private extension AboutView {
    @ViewBuilder
    func infoRow(title: String, value: String) -> some View {
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

// MARK: - Copy
private extension AboutView {
    var isChinese: Bool {
        vm.appLanguage == .zh
    }

    var pageTitle: String {
        isChinese ? "关于" : "About"
    }

    var pageSubtitle: String {
        isChinese ? "应用信息与版本说明" : "App information and version details"
    }

    var appName: String {
        "FocusTime"
    }

    var appTagline: String {
        isChinese ? "一个极简的专注计时器" : "A minimal focus timer"
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        return isChinese
            ? "版本 \(version)"
            : "Version \(version)"
    }

    var appDescription: String {
        isChinese
        ? "FocusTime 是一个 macOS 菜单栏专注计时器，支持番茄钟、专注统计、金币奖励与主题解锁。"
        : "FocusTime is a macOS menu bar focus timer with Pomodoro sessions, study statistics, coin rewards, and unlockable themes."
    }

    var developerTitle: String {
        isChinese ? "开发者" : "Developer"
    }

    var developerName: String {
        "Xu Zihan"
    }

    var platformTitle: String {
        isChinese ? "平台" : "Platform"
    }

    var platformName: String {
        "macOS"
    }

    var copyrightTitle: String {
        isChinese ? "版权" : "Copyright"
    }

    var copyrightText: String {
        "© 2026 Xu Zihan"
    }
}

#Preview("Content") {
    AboutView(vm: PomodoroViewModel())
        .frame(width: 600, height: 420)
}
