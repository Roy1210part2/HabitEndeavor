import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsArray: [AppSettings]

    private var colorScheme: ColorScheme? {
        guard let s = settingsArray.first else { return nil }
        return s.prefersDarkMode ? .dark : .light
    }

    var body: some View {
        Group {
            #if os(macOS)
            MacContentView()
            #else
            IOSContentView()
            #endif
        }
        .preferredColorScheme(colorScheme)
        .tint(.primary)
    }
}

// MARK: - iOS / iPadOS

#if os(iOS)
struct IOSContentView: View {
    var body: some View {
        TabView {
            NavigationStack { CheckboxView() }
                .tabItem { Label("체크박스", systemImage: "square.grid.2x2") }
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { RecordsView() }
                .tabItem { Label("기록", systemImage: "chart.bar") }
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { ScheduleView() }
                .tabItem { Label("일정", systemImage: "calendar") }
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { WorldView() }
                .tabItem { Label("세계", systemImage: "globe") }
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { SettingsView() }
                .tabItem { Label("설정", systemImage: "gearshape") }
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
#endif

// MARK: - macOS

#if os(macOS)
struct MacContentView: View {
    @State private var selectedTab: AppTab = .checkbox

    var body: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon).tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 210)
        } detail: {
            NavigationStack {
                switch selectedTab {
                case .checkbox: CheckboxView()
                case .records:  RecordsView()
                case .schedule: ScheduleView()
                case .world:    WorldView()
                case .settings: SettingsView()
                }
            }
        }
    }
}
#endif

// MARK: - Tab Model

enum AppTab: String, CaseIterable, Identifiable {
    case checkbox, records, schedule, world, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkbox: "체크박스"
        case .records:  "기록"
        case .schedule: "일정"
        case .world:    "세계"
        case .settings: "설정"
        }
    }

    var icon: String {
        switch self {
        case .checkbox: "square.grid.2x2"
        case .records:  "chart.bar"
        case .schedule: "calendar"
        case .world:    "globe"
        case .settings: "gearshape"
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
