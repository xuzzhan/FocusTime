import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: PomodoroViewModel

    private let pagePadding: CGFloat = 20
    private let blockSpacing: CGFloat = 16
    private let cardCornerRadius: CGFloat = 12

    private let sectionTitleFont: Font = .caption
    private let valueFont: Font = .subheadline
    private let statusFont: Font = .caption2

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { vm.launchAtLoginEnabled },
            set: { newValue in
                vm.setLaunchAtLogin(newValue)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            pageHeader(
                title: vm.appLanguage == .zh ? "偏好" : "Preferences",
                subtitle: vm.appLanguage == .zh
                ? "调整语言、启动与提醒相关选项"
                : "Adjust language, launch, and reminder options"
            )

            VStack(alignment: .leading, spacing: 14) {
                settingRow(title: vm.t("language")) {
                    Picker("", selection: $vm.appLanguageRaw) {
                        Text("中文").tag(PomodoroViewModel.AppLanguage.zh.rawValue)
                        Text("English").tag(PomodoroViewModel.AppLanguage.en.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .controlSize(.small)
                    .font(valueFont)
                }

                Divider()

                settingRow(title: vm.t("launch_at_login")) {
                    Toggle("", isOn: launchAtLoginBinding)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Divider()

                settingRow(title: vm.appLanguage == .zh ? "提醒铃声" : "Remind sound") {
                    HStack(spacing: 6) {
                        Picker("", selection: $vm.alarmSound) {
                            ForEach(vm.availableSystemSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .frame(width: 120)
                        .controlSize(.small)

                        Button {
                            vm.previewAlarmSound()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .controlSize(.small)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    settingRow(title: vm.appLanguage == .zh ? "滴答声" : "Tick Sound") {
                        HStack(spacing: 8) {
                            Text(vm.appLanguage == .zh ? "仅专注" : "Focus Only")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Toggle("", isOn: $vm.tickOnlyInFocus)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }

                    HStack {
                        Slider(
                            value: Binding(
                                get: { vm.tickVolume },
                                set: { vm.updateTickVolume($0) }
                            ),
                            in: 0...1
                        )

                        Text("\(Int(vm.tickVolume * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 38, alignment: .trailing)
                    }
                }

                if let error = vm.launchAtLoginError, !error.isEmpty {
                    Divider()

                    Text(error)
                        .font(statusFont)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))

            Spacer(minLength: 0)
        }
        .padding(pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            vm.refreshLaunchAtLoginStatus()
        }
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
    private func settingRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(sectionTitleFont)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Spacer(minLength: 0)

            content()
        }
    }
}

#Preview {
    SettingsView(vm: PomodoroViewModel())
}
