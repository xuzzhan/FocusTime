import SwiftUI
import AppKit

@main
struct FocusTimeApp: App {
    @StateObject private var vm = PomodoroViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView(vm: vm)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            ContentView(vm: vm)
                .frame(width: 250)
        } label: {
            MenuBarLabelView(
                timerStatus: vm.timerStatus,
                sessionMode: vm.sessionMode,
                timeString: vm.timeString()
            )
        }
        .menuBarExtraStyle(.window)

        Window("FocusTime", id: "app-panel") {
            AppPanelView(vm: vm)
        }
        .defaultSize(width: 720, height: 500)
        .windowResizability(.contentSize)
    }
}

struct MenuBarLabelView: View {
    let timerStatus: PomodoroViewModel.TimerStatus
    let sessionMode: PomodoroViewModel.SessionMode
    let timeString: String

    private var menuBarIcon: NSImage {
        let image = NSImage(named: "MenuBarIcon") ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 14, height: 14)
        return image
    }

    var body: some View {
        if timerStatus == .running || timerStatus == .paused {
            HStack(spacing: 3) {
                Image(systemName: sessionMode == .focus ? "brain.head.profile" : "cup.and.saucer")
                    .font(.system(size: 12, weight: .regular))

                Text(timeString)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .regular))
            }
            .fixedSize()
        } else {
            Image(nsImage: menuBarIcon)
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .fixedSize()
        }
    }
}
