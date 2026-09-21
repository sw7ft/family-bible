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
    @Environment(\.horizontalSizeClass) private var size

    var body: some View {
        Group {
            if size == .regular {
                PadRoot()
            } else {
                PhoneRoot()
            }
        }
        .tint(store.theme.accent)
        .background(store.theme.page.ignoresSafeArea())
    }
}

struct PhoneRoot: View {
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
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag("settings")
        }
        .quietTabs()
    }
}

struct PadRoot: View {
    @EnvironmentObject private var store: ReadingStore

    var body: some View {
        NavigationSplitView {
            List(selection: tabPick) {
                Section {
                    Label("Read", systemImage: "book").tag("read")
                    Label("Books", systemImage: "list.bullet").tag("books")
                    Label("Search", systemImage: "magnifyingglass").tag("search")
                    Label("Journal", systemImage: "heart.text.square").tag("journal")
                    Label("Settings", systemImage: "gearshape").tag("settings")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Family Bible")
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .quietBar()
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            switch store.tab {
            case "books": LibraryView()
            case "search": SearchView()
            case "journal": JournalView()
            case "settings": SettingsView()
            default: ReaderView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var tabPick: Binding<String?> {
        Binding(
            get: { store.tab },
            set: { if let value = $0 { store.tab = value } }
        )
    }
}
