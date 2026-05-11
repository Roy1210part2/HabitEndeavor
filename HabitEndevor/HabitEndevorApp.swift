import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Notification Name

extension Notification.Name {
    static let openDailyCheck = Notification.Name("com.habitendeavor.openDailyCheck")
}

// MARK: - iOS AppDelegate (알림 딥링크 처리)

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 알림을 탭했을 때 → daily-report, streak-rescue 모두 DailyHabitCheckSheet로 연결
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        if id == "daily-report" || id == "streak-rescue" {
            NotificationCenter.default.post(name: .openDailyCheck, object: nil)
        }
        completionHandler()
    }

    // 앱이 포그라운드일 때도 배너 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
#endif

// MARK: - App

@main
struct HabitEndeavorApp: App {
    var sharedModelContainer: ModelContainer = makeContainer()

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var showSplash = true

    init() {
        #if os(iOS)
        UIWindow.appearance().backgroundColor = UIColor.systemBackground

        let tabBar = UITabBarAppearance()
        tabBar.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance   = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let navBar = UINavigationBarAppearance()
        navBar.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance           = navBar
        UINavigationBar.appearance().scrollEdgeAppearance         = navBar
        UINavigationBar.appearance().compactAppearance            = navBar
        UINavigationBar.appearance().compactScrollEdgeAppearance  = navBar
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash ? 0 : 1)
                    .task { seedSettingsIfNeeded() }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeOut(duration: 0.45)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedSettingsIfNeeded() {
        let context = sharedModelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if count == 0 {
            context.insert(AppSettings())
            try? context.save()
        }
    }

    // MARK: - Container Factory

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitRecord.self,
            PurchasedCountry.self,
            AppSettings.self,
            CompletedQuest.self,
            ScheduleItem.self,
        ])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.co.lyu.HabitEndeavor")
        )
        if let c = try? ModelContainer(for: schema, configurations: [cloudConfig]) { return c }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [localConfig]) { return c }

        // 스키마 변경으로 마이그레이션 불가 시 (개발 중)
        let storeURL = localConfig.url
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        if let c = try? ModelContainer(for: schema, configurations: [localConfig]) { return c }

        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memConfig])
        } catch {
            fatalError("ModelContainer 생성 완전 실패: \(error)")
        }
    }
}
