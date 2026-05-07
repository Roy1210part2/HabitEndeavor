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
        #if os(macOS)
        macOSLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsGroup("화면") {
                    HStack {
                        Text("다크 모드").font(.body)
                        Spacer()
                        Toggle("", isOn: $settings.prefersDarkMode).labelsHidden()
                    }
                    .padding(.vertical, 4)
                }

                settingsGroup("주간") {
                    HStack {
                        Text("주 시작 요일").font(.body)
                        Spacer()
                        Picker("", selection: $settings.weekStartsOnMonday) {
                            Text("월요일").tag(true)
                            Text("일요일").tag(false)
                        }
                        .labelsHidden().frame(width: 100)
                    }
                    .padding(.vertical, 4)
                }

                settingsGroup("리포트 알림") {
                    HStack {
                        Text("매일 알림 받기").font(.body)
                        Spacer()
                        Toggle("", isOn: $notificationEnabled)
                            .labelsHidden()
                            .onChange(of: notificationEnabled) { _, on in
                                on ? requestPermission() : cancelNotification()
                            }
                    }
                    .padding(.vertical, 4)

                    if notificationEnabled {
                        HStack {
                            Text("알림 시간").font(.body)
                            Spacer()
                            DatePicker("", selection: notificationTime,
                                       displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }

                settingsGroup("앱 정보") {
                    HStack {
                        Text("버전").font(.body)
                        Spacer()
                        Text(appVersion).font(.body).foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("개발자").font(.body)
                        Spacer()
                        Text("류성균").font(.body).foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(24)
            .frame(maxWidth: 500, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { checkPermissionStatus() }
        .alert("알림 권한이 필요해요", isPresented: $showPermissionAlert) {
            Button("설정 열기") { openSystemSettings() }
            Button("취소", role: .cancel) { notificationEnabled = false }
        } message: {
            Text("시스템 설정에서 HabitEndeavor 알림을 허용해주세요.")
        }
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(Color.secondary).textCase(.uppercase)
                .padding(.bottom, 2)
            VStack(alignment: .leading, spacing: 0) { content() }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color(.windowBackgroundColor).opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    #endif

    // MARK: - iOS Layout (아이폰 설정 스타일)

    #if os(iOS)
    private var iosLayout: some View {
        Form {
            Section("화면") {
                Toggle("다크 모드", isOn: $settings.prefersDarkMode)
            }

            Section("주간") {
                Picker("주 시작 요일", selection: $settings.weekStartsOnMonday) {
                    Text("월요일").tag(true)
                    Text("일요일").tag(false)
                }
                .pickerStyle(.segmented)
            }

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
    #endif

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
        let content       = UNMutableNotificationContent()
        content.title     = "HabitEndeavor"
        content.body      = "오늘 습관 체크 하셨나요?"
        content.sound     = .default
        var c             = DateComponents()
        c.hour            = settings.notificationHour
        c.minute          = settings.notificationMinute
        let trigger       = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
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

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: AppSettings.self, inMemory: true)
}
