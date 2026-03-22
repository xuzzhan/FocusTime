import SwiftUI

enum AppPanelSection: String, CaseIterable, Identifiable {
    case rewards
    case settings
    case about

    static var visibleCases: [AppPanelSection] {
        [.rewards, .settings, .about]
    }

    var id: String { rawValue }

    func title(for language: PomodoroViewModel.AppLanguage) -> String {
        switch self {
        case .rewards:
            return language == .zh ? "金币兑换" : "Rewards"
        case .settings:
            return language == .zh ? "偏好" : "Preferences"
        case .about:
            return language == .zh ? "关于" : "About"
        }
    }

    var iconName: String {
        switch self {
        case .rewards:
            return "dollarsign.circle"
        case .settings:
            return "gearshape"
        case .about:
            return "info.circle"
        }
    }
}

struct AppPanelView: View {
    @ObservedObject var vm: PomodoroViewModel

    private var navigationTitle: String {
        vm.appLanguage == .zh ? "设置" : "Settings"
    }

    var body: some View {
        NavigationSplitView {
            List(AppPanelSection.visibleCases, selection: $vm.panelSelection) { section in
                Label(section.title(for: vm.appLanguage), systemImage: section.iconName)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle(navigationTitle)
            .navigationSplitViewColumnWidth(min: 135, ideal: 150, max: 180)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch vm.panelSelection {
        case .rewards:
            RewardsView(vm: vm)
        case .settings:
            SettingsView(vm: vm)
        case .about:
            AboutView(vm: vm)
        }
    }
}

#Preview("Content") {
    AppPanelView(vm: PomodoroViewModel())
}
