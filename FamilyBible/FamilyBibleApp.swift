import SwiftUI
import UIKit

@main
struct FamilyBibleApp: App {
    @StateObject private var store = ReadingStore()

    init() {
        QuietChrome.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.theme.scheme)
        }
    }
}

enum QuietChrome {
    static func apply() {
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().isTranslucent = true

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }
}

extension View {
    func quietBar() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
    }

    func quietTabs() -> some View {
        toolbarBackground(.hidden, for: .tabBar)
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ReadingStore
    var body: some View {
        TabView(selection: $store.tab) {
            ReaderView()
                .tabItem { Label("Read", systemImage: "book") }
                .tag("read")
            LibraryView()
                .tabItem { Label("Books", systemImage: "list.bullet") }
                .tag("books")
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag("search")
            JournalView()
                .tabItem { Label("Journal", systemImage: "heart.text.square") }
                .tag("journal")
            SettingsView()
                .tabItem { Label("Settings", systemImage: "textformat.size") }
                .tag("settings")
        }
        .tint(store.theme.accent)
        .quietTabs()
        .background(store.theme.page.ignoresSafeArea())
    }
}
