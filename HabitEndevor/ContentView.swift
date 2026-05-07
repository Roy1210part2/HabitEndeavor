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

struct IOSContentView: View {
    var body: some View {
        TabView {
            NavigationStack { CheckboxView() }
                .tabItem { Label("체크박스", systemImage: "square.grid.2x2") }

            NavigationStack { RecordsView() }
                .tabItem { Label("기록", systemImage: "chart.bar") }

            NavigationStack { WorldView() }
                .tabItem { Label("세계", systemImage: "globe") }

            NavigationStack { SettingsView() }
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}

// MARK: - macOS

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
                case .world:    WorldView()
                case .settings: SettingsView()
                }
            }
        }
    }
}

// MARK: - Tab Model

enum AppTab: String, CaseIterable, Identifiable {
    case checkbox, records, world, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkbox: "체크박스"
        case .records:  "기록"
        case .world:    "세계"
        case .settings: "설정"
        }
    }

    var icon: String {
        switch self {
        case .checkbox: "square.grid.2x2"
        case .records:  "chart.bar"
        case .world:    "globe"
        case .settings: "gearshape"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
