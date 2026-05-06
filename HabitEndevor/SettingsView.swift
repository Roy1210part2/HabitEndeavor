import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    var body: some View {
        Group {
            if let settings = settingsArray.first {
                SettingsForm(settings: settings)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("설정")
    }
}

// MARK: - Form

struct SettingsForm: View {
    @Bindable var settings: AppSettings
    @State private var notificationEnabled = false
    @State private var showPermissionAlert = false

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour   = settings.notificationHour
                c.minute = settings.notificationMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let cal = Calendar.current
                settings.notificationHour   = cal.component(.hour, from: date)
                settings.notificationMinute = cal.component(.minute, from: date)
                if notificationEnabled { scheduleNotification() }
            }
        )
    }

    var body: some View {
        Form {
            // MARK: 화면 설정
            Section("화면") {
                Toggle("다크 모드", isOn: $settings.prefersDarkMode)
            }

            // MARK: 주간 설정
            Section("주간") {
                Picker("주 시작 요일", selection: $settings.weekStartsOnMonday) {
                    Text("월요일").tag(true)
                    Text("일요일").tag(false)
                }
                #if os(iOS)
                .pickerStyle(.segmented)
                #endif
            }

            // MARK: 알림
            Section("리포트 알림") {
                Toggle("매일 알림 받기", isOn: $notificationEnabled)
                    .onChange(of: notificationEnabled) { _, on in
                        on ? requestPermission() : cancelNotification()
                    }

                if notificationEnabled {
                    DatePicker("알림 시간",
                               selection: notificationTime,
                               displayedComponents: .hourAndMinute)
                }
            }

            // MARK: 앱 정보
            Section("앱 정보") {
                LabeledContent("버전", value: appVersion)
                LabeledContent("개발자", value: "류성균")
            }
        }
        .onAppear { checkPermissionStatus() }
        .alert("알림 권한이 필요해요", isPresented: $showPermissionAlert) {
            Button("설정 열기") { openSystemSettings() }
            Button("취소", role: .cancel) { notificationEnabled = false }
        } message: {
            Text("시스템 설정에서 HabitEndeavor 알림을 허용해주세요.")
        }
    }

    // MARK: - Notification

    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { ns in
            DispatchQueue.main.async {
                notificationEnabled = ns.authorizationStatus == .authorized
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted { scheduleNotification() }
                    else { notificationEnabled = false; showPermissionAlert = true }
                }
            }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-report"])

        let content        = UNMutableNotificationContent()
        content.title      = "HabitEndeavor"
        content.body       = "오늘 습관 체크 하셨나요?"
        content.sound      = .default

        var c        = DateComponents()
        c.hour       = settings.notificationHour
        c.minute     = settings.notificationMinute
        let trigger  = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
        center.add(UNNotificationRequest(identifier: "daily-report", content: content, trigger: trigger))
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-report"])
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #else
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: AppSettings.self, inMemory: true)
}
