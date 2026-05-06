//
//  HabitEndevorApp.swift
//  HabitEndevor
//
//  Created by 류성균 on 5/6/26.
//

import SwiftUI
import SwiftData

@main
struct HabitEndevorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitRecord.self,
            PurchasedCountry.self,
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { seedSettingsIfNeeded() }
        }
        .modelContainer(sharedModelContainer)
    }

    // AppSettings가 없으면 기본값으로 생성
    private func seedSettingsIfNeeded() {
        let context = sharedModelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if count == 0 {
            context.insert(AppSettings())
            try? context.save()
        }
    }
}
