import SwiftUI
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: ReadingStore
    @StateObject private var tips = TipStore()
    @State private var exportDoc = FamilyBibleDocument(data: Data())
    @State private var exporting = false
    @State private var importing = false
    @State private var status = ""

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

                Section("This family's writing") {
                    Text("Export keeps notes, comments, journals, prayers, places, and pictures in a file you choose. Import adds them back. Nothing is sent to SW7FT.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    Button("Export…") { exportFamily() }
                    Button("Import…") { importing = true }
                    if !status.isEmpty {
                        Text(status)
                            .font(QuietFont.small(13))
                            .foregroundStyle(store.theme.accent)
                    }
                }

                Section("Support SW7FT") {
                    Text(tips.showTips
                         ? "A review is the help Apple welcomes. A tip is optional — nothing in the Bible changes. Apple handles the payment."
                         : "A review is the help Apple welcomes.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    Button("Write a review") { askReview() }
                    if tips.showTips {
                        ForEach(TipStore.offers) { offer in
                            Button {
                                Task { await tips.buy(offer) }
                            } label: {
                                HStack {
                                    Text(offer.name)
                                    Spacer()
                                    Text(tips.price(for: offer))
                                        .foregroundStyle(store.theme.mute)
                                }
                            }
                            .disabled(tips.busy)
                        }
                    }
                    if !tips.status.isEmpty {
                        Text(tips.status)
                            .font(QuietFont.small(13))
                            .foregroundStyle(store.theme.accent)
                    }
                    if let url = URL(string: "https://sw7ft.github.io/family-bible/") {
                        Link("SW7FT on the web", destination: url)
                    }
                }

                Section("This Bible") {
                    Text("Published by SW7FT. The words are public domain. Your writing and pictures stay on this phone — no account, no ads, no tracking.")
                        .font(QuietFont.small(14))
                        .foregroundStyle(store.theme.mute)
                    Text("Maps: George Adam Smith, Atlas of the Historical Geography of the Holy Land, 1915.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    Text(versionLine)
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    if let url = URL(string: "https://sw7ft.github.io/family-bible/privacy.html") {
                        Link("Privacy", destination: url)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .navigationTitle("Settings")
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .fileExporter(
                isPresented: $exporting,
                document: exportDoc,
                contentType: .json,
                defaultFilename: exportName
            ) { result in
                switch result {
                case .success:
                    status = "Saved. Keep that file with the family."
                case .failure(let error):
                    status = error.localizedDescription
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    importFamily(from: url)
                case .failure(let error):
                    status = error.localizedDescription
                }
            }
        }
    }

    private var exportName: String {
        "Family Bible \(Date().formatted(date: .abbreviated, time: .omitted))"
    }

    private func exportFamily() {
        do {
            exportDoc = FamilyBibleDocument(data: try store.exportFamily())
            exporting = true
            status = ""
        } catch {
            status = error.localizedDescription
        }
    }

    private func importFamily(from url: URL) {
        do {
            let got = url.startAccessingSecurityScopedResource()
            defer { if got { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            try store.importFamily(data)
            status = "Added. Existing writing was kept; matching items were updated."
        } catch {
            status = error.localizedDescription
        }
    }

    private func askReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        if build.isEmpty {
            return "Family Bible \(version) · © 2026 SW7FT"
        }
        return "Family Bible \(version) (\(build)) · © 2026 SW7FT"
    }
}
