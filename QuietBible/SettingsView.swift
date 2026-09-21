import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ReadingStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Translation") {
                    Picker("Text", selection: Binding(
                        get: { store.translationId },
                        set: { store.setTranslation($0) }
                    )) {
                        Text("World English").tag("webu")
                        Text("Basic English").tag("bbe")
                        Text("King James").tag("kjv")
                    }
                    .pickerStyle(.inline)
                    Text(store.translation.notice)
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                }

                Section("Page") {
                    Picker("Theme", selection: $store.theme) {
                        ForEach(ReadingTheme.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Type size") {
                    Slider(value: $store.fontSize, in: 17...30, step: 1)
                    Text("In the beginning, God created the heavens and the earth.")
                        .font(QuietFont.body(store.fontSize))
                        .foregroundStyle(store.theme.ink)
                        .lineSpacing(store.fontSize * 0.35)
                        .padding(.vertical, 6)
                }

                Section("This Bible") {
                    Text("Published by SW7FT. The words are public domain. Your writing and pictures stay on this phone — no account, no ads, no tracking.")
                        .font(QuietFont.small(14))
                        .foregroundStyle(store.theme.mute)
                    Text("Maps: George Adam Smith, Atlas of the Historical Geography of the Holy Land, 1915.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    if let url = URL(string: "https://sw7ft.github.io/family-bible/") {
                        Link("Support and source", destination: url)
                    }
                    if let url = URL(string: "https://sw7ft.github.io/family-bible/privacy.html") {
                        Link("Privacy", destination: url)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .navigationTitle("Reading")
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
        }
    }
}
