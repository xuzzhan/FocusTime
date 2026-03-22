import SwiftUI

enum AppPanelSection: String, CaseIterable, Identifiable {
    case rewards
    case settings
    case about
    static var visibleCases: [AppPanelSection] {
        [.settings, .about]
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
    @State private var selection: AppPanelSection?

    init(vm: PomodoroViewModel, initialSelection: AppPanelSection = .rewards) {
        self.vm = vm
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        NavigationSplitView {
            List(AppPanelSection.visibleCases, selection: $selection) { section in
                Label(section.title(for: vm.appLanguage), systemImage: section.iconName)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 135, ideal: 150, max: 180)
        } detail: {
            Group {
                switch selection {
                case .rewards:
                    RewardsView(vm: vm)

                case .settings:
                    SettingsView(vm: vm)

                case .about:
                    AboutView(vm: vm)

                case .none:
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.appLanguage == .zh ? "请选择一个项目" : "Select an item")
                            .font(.title3.weight(.semibold))

                        Text(
                            vm.appLanguage == .zh
                            ? "从左侧导航栏中选择页面。"
                            : "Choose a page from the sidebar."
                        )
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
//        .frame(width: 520)
    }
}

#Preview("Content") {
    AppPanelView(vm: PomodoroViewModel())
//        .frame(width: 520)
}
