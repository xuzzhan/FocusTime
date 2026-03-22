import SwiftUI
import AppKit
import Charts

// 先状态和样式属性，再是 body
// 按页面出现顺序放各个 section，接着放这些 section 依赖的小组件
// 最后放工具函数
struct ContentView: View {
    @ObservedObject var vm: PomodoroViewModel
    @State private var statsWeekOffset: Int = 0
    @State private var hoveredItem: PomodoroViewModel.DailyStatsPoint? = nil
    @State private var showChartSection = false
    @Environment(\.openWindow) private var openWindow

    private let stageFont: Font = .headline
    private let statusFont: Font = .subheadline
    private let timerFont: Font = .system(size: 24, weight: .medium, design: .rounded)
    private let sectionTitleFont: Font = .subheadline
    private let valueFont: Font = .subheadline
    private let inputFont: Font = .subheadline

    private var isRunning: Bool {
        vm.timerStatus == .running
    }

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            actionSection
            quickAdjustSection
            todayStatsSection
            bottomMenuSection
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.top, 10)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .onChange(of: vm.focusMinutes) { _, newValue in
            vm.updateFocusMinutes(newValue)
        }
        .onChange(of: vm.breakMinutes) { _, newValue in
            vm.updateBreakMinutes(newValue)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(vm.stageText())
                .font(stageFont.weight(.semibold))
                .lineLimit(1)

            Text(vm.statusText())
                .font(statusFont)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(vm.timeString())
                .font(timerFont)
                .monospacedDigit()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionSection: some View {
        HStack(spacing: 8) {
            Button(vm.primaryButtonText()) {
                vm.startOrPauseOrResume()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)

            Button(vm.t("reset")) {
                vm.resetTimer()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
        }
    }

    private var quickAdjustSection: some View {
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
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showChartSection.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))

                    Text(vm.appLanguage == .zh ? "统计" : "Stats")
                        .font(sectionTitleFont)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)

                        Text(vm.coinsSummaryText(weekOffset: statsWeekOffset))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: showChartSection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)

            if showChartSection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            statsWeekOffset -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(vm.weekTitle(forWeekOffset: statsWeekOffset))
                            .font(sectionTitleFont)
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 8) {
                            Button(vm.appLanguage == .zh ? "本周" : "This Week") {
                                statsWeekOffset = 0
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(statsWeekOffset == 0 ? .tertiary : .secondary)
                            .disabled(statsWeekOffset == 0)

                            Button {
                                if statsWeekOffset < 0 {
                                    statsWeekOffset += 1
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                            .disabled(statsWeekOffset >= 0)
                            .opacity(statsWeekOffset >= 0 ? 0.35 : 1.0)
                        }
                    }

                    statsChartView
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var bottomMenuSection: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.bottom, 6)

            menuRow(
                icon: "sidebar.left",
                title: vm.appLanguage == .zh ? "设置" : "Settings"
            ) {
                NSApp.activate(ignoringOtherApps: true)
                vm.panelSelection = .rewards
                openWindow(id: "app-panel")
            }

            menuRow(
                icon: "power",
                title: vm.t("quit")
            ) {
                NSApp.terminate(nil)
            }
        }
    }

    private var statsChartView: some View {
        let data = vm.weeklyStats(weekOffset: statsWeekOffset)

        return VStack(alignment: .leading, spacing: 6) {
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Hours", item.focusHours),
                        series: .value("Type", "Focus")
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Hours", item.focusHours)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(40)

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Hours", item.breakHours),
                        series: .value("Type", "Break")
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Hours", item.breakHours)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)

                    if let hoveredItem {
                        RuleMark(x: .value("Date", hoveredItem.date))
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                        .foregroundStyle(.quaternary)
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(shortWeekdayLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(.quaternary)
                    AxisTick()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(String(format: "%.1fh", number))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onHover { inside in
                            if !inside {
                                hoveredItem = nil
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else {
                                        hoveredItem = nil
                                        return
                                    }

                                    let frame = geo[plotFrame]
                                    let relativeX = value.location.x - frame.origin.x
                                    let relativeY = value.location.y - frame.origin.y

                                    guard relativeX >= 0,
                                          relativeX <= frame.width,
                                          relativeY >= 0,
                                          relativeY <= frame.height else {
                                        hoveredItem = nil
                                        return
                                    }

                                    guard let date: Date = proxy.value(atX: relativeX) else {
                                        hoveredItem = nil
                                        return
                                    }

                                    hoveredItem = data.min {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    }
                                }
                        )
                }
            }
            .frame(height: 120)

            HStack(spacing: 6) {
                chartLegendRow(color: .purple, title: vm.t("focus_hours"))
                chartLegendRow(color: .blue, title: vm.t("break_hours"))
                Spacer()
            }

            Text(
                vm.appLanguage == .zh
                ? "每专注1小时获得1金币"
                : "Earn 1 coin per focus hour."
            )
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .overlay(alignment: .topTrailing) {
            if let hoveredItem {
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortWeekdayLabel(hoveredItem.date))
                        .font(.caption2)

                    Text("\(vm.t("focus_hours")): \(String(format: "%.1f", hoveredItem.focusHours))h")
                        .font(.caption2)

                    Text("\(vm.t("break_hours")): \(String(format: "%.1f", hoveredItem.breakHours))h")
                        .font(.caption2)
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 8)
                .padding(.trailing, 10)
            }
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

    @ViewBuilder
    private func menuRow(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 14)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func chartLegendRow(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func shortWeekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = vm.appLanguage == .zh
            ? Locale(identifier: "zh_CN")
            : Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = vm.appLanguage == .zh ? "E" : "EEE"
        return formatter.string(from: date)
    }
}

#Preview("Content") {
    ContentView(vm: PomodoroViewModel())
        .frame(width: 250, height: 560)
}
