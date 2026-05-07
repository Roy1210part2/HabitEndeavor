import SwiftUI
import SwiftData

@main
struct HabitEndevorApp: App {
    var sharedModelContainer: ModelContainer = makeContainer()

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
    // 3. Containers에 "iCloud.co.lyu.HabitEndevor" 추가
    // 위 설정이 없으면 자동으로 로컬 저장소로 폴백됩니다.

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitRecord.self,
            PurchasedCountry.self,
            AppSettings.self,
        ])

        // CloudKit 동기화 시도 (.automatic은 entitlement에서 컨테이너를 자동 선택)
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.co.lyu.HabitEndevor")
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }

        // CloudKit 미설정 시 로컬 저장소
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
