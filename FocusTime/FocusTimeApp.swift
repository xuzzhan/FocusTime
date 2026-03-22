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

final class AppPanelWindowController {
    static let shared = AppPanelWindowController()

    private var window: NSWindow?

    func show(vm: PomodoroViewModel, section: AppPanelSection = .rewards) {
        let contentView = AppPanelView(vm: vm, initialSelection: section)

        if let window = window {
            window.contentView = NSHostingView(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "FocusTime"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)

        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview("Idle") {
    MenuBarLabelView(
        timerStatus: .idle,
        sessionMode: .focus,
        timeString: "25:00"
    )
    .padding(8)
}

#Preview("Focus Running") {
    MenuBarLabelView(
        timerStatus: .running,
        sessionMode: .focus,
        timeString: "24:12"
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Break Running") {
    MenuBarLabelView(
        timerStatus: .running,
        sessionMode: .rest,
        timeString: "04:59"
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Paused") {
    MenuBarLabelView(
        timerStatus: .paused,
        sessionMode: .focus,
        timeString: "12:34"
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
