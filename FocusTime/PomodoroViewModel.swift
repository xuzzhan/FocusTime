import Foundation
import SwiftUI
import Combine

// 先放类型定义，再放存储属性，再放初始化，再放公开状态/基础计算属性，然后按功能分组：
// 初始化与默认值
// 计时器控制
// 时长更新
// 统计相关
// 开机自启
// 声音与通知
// 文案与格式化

final class PomodoroViewModel: ObservableObject {
    enum SessionMode {
        case focus
        case rest
    }

    enum TimerStatus {
        case idle
        case running
        case paused
    }

    enum AppLanguage: String, CaseIterable, Identifiable {
        case zh
        case en

        var id: String { rawValue }
    }

    struct DailyStatsPoint: Identifiable {
        let id = UUID()
        let date: Date
        let focusHours: Double
        let breakHours: Double
    }

    @AppStorage("appLanguage") var appLanguageRaw = AppLanguage.zh.rawValue
    @AppStorage("focusMinutes") var focusMinutes = 50.0
    @AppStorage("breakMinutes") var breakMinutes = 10.0

    @AppStorage("dailyFocusSecondsData") private var dailyFocusSecondsData: Data = Data()
    @AppStorage("dailyBreakSecondsData") private var dailyBreakSecondsData: Data = Data()

    @AppStorage("alarmSound") var alarmSound: String = "Glass"
    @AppStorage("tickOnlyInFocus") var tickOnlyInFocus: Bool = true
    @AppStorage("tickVolume") var tickVolume: Double = 0.3
    @AppStorage("hasInitializedDefaults") private var hasInitializedDefaults = false

    @Published var launchAtLoginEnabled: Bool = false
    @Published var launchAtLoginError: String? = nil

    @Published var remainingSeconds = 25 * 60
    @Published var sessionMode: SessionMode = .focus
    @Published var timerStatus: TimerStatus = .idle
    @Published var panelSelection: AppPanelSection = .rewards

    private var timer: Timer?

    var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .zh
    }

    var availableSystemSounds: [String] {
        [
            "None", "Basso", "Blow", "Bottle", "Frog",
            "Funk", "Glass", "Hero", "Morse", "Ping",
            "Pop", "Purr", "Sosumi", "Submarine", "Tink"
        ]
    }

    private var statsDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var todayKey: String {
        statsDateFormatter.string(from: Date())
    }

    init() {
        applyInitialDefaultsIfNeeded()
        resetToCurrentModeDuration()
        NotificationManager.shared.requestAuthorization()
        refreshLaunchAtLoginStatus()
    }

    deinit {
        timer?.invalidate()
    }

    private func applyInitialDefaultsIfNeeded() {
        guard !hasInitializedDefaults else { return }

        appLanguageRaw = AppLanguage.en.rawValue
        focusMinutes = 50.0
        breakMinutes = 10.0
        tickVolume = 0.3
        alarmSound = "Glass"
        tickOnlyInFocus = true
        setLaunchAtLogin(true)
        hasInitializedDefaults = true
    }

    func startOrPauseOrResume() {
        switch timerStatus {
        case .idle:
            startTimer()
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = nil
        timerStatus = .running

        if tickVolume > 0.01, !tickOnlyInFocus || sessionMode == .focus {
            TickSoundManager.shared.startLoop(volume: tickVolume)
        } else {
            TickSoundManager.shared.stopTick()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                guard self.timerStatus == .running else { return }

                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.switchMode()
                }
            }
        }

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func resumeTimer() {
        guard timerStatus == .paused else { return }
        startTimer()
    }

    func pauseTimer() {
        guard timerStatus == .running else { return }
        timer?.invalidate()
        timer = nil
        timerStatus = .paused
        TickSoundManager.shared.stopTick()
    }

    func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerStatus = .idle
        TickSoundManager.shared.stopTick()

        sessionMode = .focus
        remainingSeconds = Int(focusMinutes) * 60
    }

    func switchMode() {
        timer?.invalidate()
        timer = nil
        TickSoundManager.shared.stopTick()

        if sessionMode == .focus {
            addFocusSecondsToday(Int(focusMinutes) * 60)
            notifyFocusFinished()
            sessionMode = .rest
            remainingSeconds = Int(breakMinutes) * 60
        } else {
            addBreakSecondsToday(Int(breakMinutes) * 60)
            notifyBreakFinished()
            sessionMode = .focus
            remainingSeconds = Int(focusMinutes) * 60
        }

        startTimer()
    }

    func resetToCurrentModeDuration() {
        if sessionMode == .focus {
            remainingSeconds = Int(focusMinutes) * 60
        } else {
            remainingSeconds = Int(breakMinutes) * 60
        }
    }

    func updateFocusMinutes(_ value: Double) {
        focusMinutes = min(max(value, 1), 120)
        if timerStatus != .running && sessionMode == .focus {
            remainingSeconds = Int(focusMinutes) * 60
        }
    }

    func updateBreakMinutes(_ value: Double) {
        breakMinutes = min(max(value, 1), 60)
        if timerStatus != .running && sessionMode == .rest {
            remainingSeconds = Int(breakMinutes) * 60
        }
    }

    func updateTickVolume(_ value: Double) {
        tickVolume = min(max(value, 0), 1)
        TickSoundManager.shared.updateVolume(tickVolume)
    }

    private func loadSecondsMap(from data: Data) -> [String: Int] {
        guard !data.isEmpty else { return [:] }

        do {
            return try JSONDecoder().decode([String: Int].self, from: data)
        } catch {
            print("读取统计失败: \(error.localizedDescription)")
            return [:]
        }
    }

    private func saveSecondsMap(_ map: [String: Int], to storage: inout Data) {
        do {
            storage = try JSONEncoder().encode(map)
        } catch {
            print("保存统计失败: \(error.localizedDescription)")
        }
    }

    private func addFocusSecondsToday(_ seconds: Int) {
        var map = loadSecondsMap(from: dailyFocusSecondsData)
        map[todayKey, default: 0] += seconds
        saveSecondsMap(map, to: &dailyFocusSecondsData)
    }

    private func addBreakSecondsToday(_ seconds: Int) {
        var map = loadSecondsMap(from: dailyBreakSecondsData)
        map[todayKey, default: 0] += seconds
        saveSecondsMap(map, to: &dailyBreakSecondsData)
    }

    func weeklyStats(weekOffset: Int) -> [DailyStatsPoint] {
        let focusMap = loadSecondsMap(from: dailyFocusSecondsData)
        let breakMap = loadSecondsMap(from: dailyBreakSecondsData)
        let calendar = Calendar.current
        let today = Date()

        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
            return []
        }

        return (0..<7).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day, to: weekInterval.start) else {
                return nil
            }

            let key = statsDateFormatter.string(from: date)

            return DailyStatsPoint(
                date: date,
                focusHours: Double(focusMap[key, default: 0]) / 3600.0,
                breakHours: Double(breakMap[key, default: 0]) / 3600.0
            )
        }
    }

    func weekTitle(forWeekOffset offset: Int) -> String {
        let calendar = Calendar.current
        let today = Date()

        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: offset, to: today),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekInterval.start) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = appLanguage == .zh
            ? Locale(identifier: "zh_CN")
            : Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = appLanguage == .zh ? "M/d" : "MMM d"

        return "\(formatter.string(from: weekInterval.start)) - \(formatter.string(from: weekEnd))"
    }

    func totalCoins() -> Int {
        let focusMap = loadSecondsMap(from: dailyFocusSecondsData)
        let totalFocusSeconds = focusMap.values.reduce(0, +)
        return totalFocusSeconds / 3600
    }

    func coinsForWeek(weekOffset: Int) -> Int {
        let totalFocusSeconds = weeklyStats(weekOffset: weekOffset)
            .reduce(0.0) { $0 + $1.focusHours * 3600.0 }

        return Int(totalFocusSeconds) / 3600
    }

    func weekCoinsText(weekOffset: Int) -> String {
        let coins = coinsForWeek(weekOffset: weekOffset)
        return "\(min(coins, 999))"
    }

    func totalCoinsText() -> String {
        let coins = totalCoins()
        return coins > 9999 ? "9999+" : "\(coins)"
    }

    func coinsSummaryText(weekOffset: Int) -> String {
        let week = weekCoinsText(weekOffset: weekOffset)
        let total = totalCoinsText()

        if appLanguage == .zh {
            return "周 \(week) / 总 \(total)"
        } else {
            return "Week \(week) / All \(total)"
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
            launchAtLoginError = nil
        } catch {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
            launchAtLoginError = error.localizedDescription
            print("设置开机启动失败: \(error.localizedDescription)")
        }
    }

    func previewAlarmSound() {
        playAlarmSound()
    }

    func playSelectedAlarmSound() {
        playAlarmSound()
    }

    private func playAlarmSound() {
        SystemSoundManager.shared.playSystemSound(named: alarmSound, loop: false)
    }

    private func notifyFocusFinished() {
        let title = appLanguage == .zh ? "学习结束" : "Focus finished"
        let body = appLanguage == .zh ? "该休息了" : "Time for a break"
        playAlarmSound()
        NotificationManager.shared.send(title: title, body: body)
    }

    private func notifyBreakFinished() {
        let title = appLanguage == .zh ? "休息结束" : "Break finished"
        let body = appLanguage == .zh ? "继续学习" : "Back to focus"
        playAlarmSound()
        NotificationManager.shared.send(title: title, body: body)
    }

    func primaryButtonText() -> String {
        switch timerStatus {
        case .idle:
            return t("start")
        case .running:
            return t("pause")
        case .paused:
            return t("resume")
        }
    }

    func stageText() -> String {
        switch sessionMode {
        case .focus:
            return t("focus_mode")
        case .rest:
            return t("rest_mode")
        }
    }

    func statusText() -> String {
        switch timerStatus {
        case .idle:
            return t("status_idle")
        case .running:
            return t("status_running")
        case .paused:
            return t("status_paused")
        }
    }

    func timeString() -> String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func menuBarTitle() -> String {
        "\(stageText()) \(timeString())"
    }

    func t(_ key: String) -> String {
        switch appLanguage {
        case .zh:
            switch key {
            case "redeem_rewards": return "金币兑换"
            case "week_coins": return "本周金币"
            case "total_coins": return "总金币"
            case "focus_hours": return "专注时长"
            case "break_hours": return "休息时长"
            case "about": return "关于"
            case "help": return "帮助"
            case "settings": return "设置"
            case "focus_mode": return "学习阶段"
            case "rest_mode": return "休息阶段"
            case "launch_at_login": return "开机自启"
            case "launch_at_login_desc": return "登录后自动启动"
            case "status_idle": return "待开始"
            case "status_running": return "计时进行中"
            case "status_paused": return "已暂停"
            case "focus_time": return "专注时长"
            case "break_time": return "休息时长"
            case "minute_unit": return "分钟"
            case "language": return "语言"
            case "start": return "开始"
            case "resume": return "继续"
            case "pause": return "暂停"
            case "reset": return "重置"
            case "quit": return "退出"
            default: return key
            }
        case .en:
            switch key {
            case "redeem_rewards": return "Redeem"
            case "week_coins": return "Week coins"
            case "total_coins": return "Total coins"
            case "focus_hours": return "Focus"
            case "break_hours": return "Break"
            case "about": return "About"
            case "help": return "Help"
            case "settings": return "Settings"
            case "focus_mode": return "Focus session"
            case "rest_mode": return "Break session"
            case "launch_at_login": return "Launch at login"
            case "launch_at_login_desc": return "Launch after login"
            case "status_idle": return "Ready to start"
            case "status_running": return "Running"
            case "status_paused": return "Paused"
            case "focus_time": return "Focus time"
            case "break_time": return "Break time"
            case "minute_unit": return "min"
            case "language": return "Language"
            case "start": return "Start"
            case "resume": return "Resume"
            case "pause": return "Pause"
            case "reset": return "Reset"
            case "quit": return "Quit"
            default: return key
            }
        }
    }
}
