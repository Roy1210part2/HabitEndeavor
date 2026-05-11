import SwiftUI
import SwiftData

@main
struct HabitEndeavorApp: App {
    var sharedModelContainer: ModelContainer = makeContainer()

    init() {
        #if os(iOS)
        // 윈도우 배경 = 흰색/다크모드 배경 (safe area 영역 포함 모두 채움)
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
            ContentView()
                .task { seedSettingsIfNeeded() }
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
    //
    // iCloud 연동 방법:
    // 1. Xcode → Target → Signing & Capabilities → + Capability → iCloud
    // 2. CloudKit 체크박스 활성화
    // 3. Containers에 "iCloud.co.lyu.HabitEndeavor" 추가
    // 위 설정이 없으면 자동으로 로컬 저장소로 폴백됩니다.

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitRecord.self,
            PurchasedCountry.self,
            AppSettings.self,
            CompletedQuest.self,
            ScheduleItem.self,
        ])

        // 1. CloudKit 시도
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.co.lyu.HabitEndeavor")
        )
        if let c = try? ModelContainer(for: schema, configurations: [cloudConfig]) { return c }

        // 2. 로컬 저장소 시도
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [localConfig]) { return c }

        // 3. 스토어 파일 충돌 복구 — 스키마 변경으로 마이그레이션 불가 시 스토어 초기화
        //    (개발 중 Bundle ID 변경 or 모델 필드 추가 등으로 발생)
        let storeURL = localConfig.url
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        if let c = try? ModelContainer(for: schema, configurations: [localConfig]) { return c }

        // 4. 최후 수단: 인메모리 (데이터 유지 안 됨, 비상용)
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memConfig])
        } catch {
            fatalError("ModelContainer 생성 완전 실패: \(error)")
        }
    }
}
