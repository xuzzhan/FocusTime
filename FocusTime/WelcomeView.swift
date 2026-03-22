import SwiftUI
import AppKit

struct WelcomeView: View {
    @ObservedObject var vm: PomodoroViewModel

    private let titleFont: Font = .title2
    private let subtitleFont: Font = .subheadline
    private let sectionTitleFont: Font = .subheadline
    private let valueFont: Font = .subheadline
    private let inputFont: Font = .subheadline

    private var isRunning: Bool {
        vm.timerStatus == .running
    }

    var body: some View {
        VStack(spacing: 14) {
            headerSection
            settingsSection
            actionSection
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: 320)
        .onChange(of: vm.focusMinutes) { _, newValue in
            vm.updateFocusMinutes(newValue)
        }
        .onChange(of: vm.breakMinutes) { _, newValue in
            vm.updateBreakMinutes(newValue)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("FocusTime")
                .font(titleFont.weight(.semibold))

            Text(vm.appLanguage == .zh ? "开始一个新的专注周期" : "Start a new focus session")
                .font(subtitleFont)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("© \(Calendar.current.component(.year, from: Date())) Xu Zihan")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            quickAdjustRow(
                title: vm.t("focus_time"),
                valueText: "\(Int(vm.focusMinutes)) \(vm.t("minute_unit"))",
                value: $vm.focusMinutes,
                range: 1...120
            )

            quickAdjustRow(
                title: vm.t("break_time"),
                valueText: "\(Int(vm.breakMinutes)) \(vm.t("minute_unit"))",
                value: $vm.breakMinutes,
                range: 1...60
            )

            languageRow
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var languageRow: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.t("language"))
                    .font(sectionTitleFont)
                    .foregroundStyle(.secondary)

                Text(vm.appLanguage == .zh ? "中文" : "English")
                    .font(valueFont)
            }

            Spacer(minLength: 8)

            Picker("", selection: $vm.appLanguageRaw) {
                Text("中文").tag(PomodoroViewModel.AppLanguage.zh.rawValue)
                Text("English").tag(PomodoroViewModel.AppLanguage.en.rawValue)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .controlSize(.small)
        }
    }

    private var actionSection: some View {
        HStack(spacing: 8) {
            Button(vm.t("start")) {
                vm.resetTimer()
                vm.startTimer()
                closeWindow()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button(vm.appLanguage == .zh ? "退出" : "Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func quickAdjustRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(sectionTitleFont)
                    .foregroundStyle(.secondary)

                Text(valueText)
                    .font(valueFont)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Button {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(isRunning || value.wrappedValue <= range.lowerBound)

                TextField("", value: value, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
                    .font(inputFont)
                    .multilineTextAlignment(.center)
                    .frame(width: 48)
                    .disabled(isRunning)

                Button {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(isRunning || value.wrappedValue >= range.upperBound)
            }
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}

#Preview {
    WelcomeView(vm: PomodoroViewModel())
}
