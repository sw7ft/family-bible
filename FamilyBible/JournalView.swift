import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: ReadingStore
    @State private var compose: JournalEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("A quiet place for the family.")
                        .font(QuietFont.body(17))
                        .foregroundStyle(store.theme.mute)

                    ForEach(JournalKind.allCases) { kind in
                        NavigationLink {
                            JournalListView(kind: kind)
                        } label: {
                            journalCard(kind)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(22)
            }
            .background(store.theme.page)
            .navigationTitle("Journal")
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .navigationDestination(item: $compose) { entry in
                JournalEditor(entry: entry)
            }
            .onChange(of: store.journalOpen) { _, kind in
                guard let kind else { return }
                let place = store.journalAttachPlace
                let verse = store.journalVerse
                var draft = JournalEntry.blank(
                    kind,
                    bookId: place ? store.bookId : nil,
                    chapter: place ? store.chapter : nil,
                    verse: place ? verse : nil
                )
                if place, let bookId = draft.bookId, let chapter = draft.chapter {
                    draft.title = store.datedReference(bookId: bookId, chapter: chapter, verse: verse)
                }
                compose = draft
                store.journalOpen = nil
                store.journalAttachPlace = false
                store.journalVerse = nil
            }
        }
    }

    private func journalCard(_ kind: JournalKind) -> some View {
        let count = store.entries(for: kind).count
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: kind.symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(store.theme.accent)
                .frame(width: 36, height: 36)
                .background(store.theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(QuietFont.display(22))
                    .foregroundStyle(store.theme.ink)
                Text(kind.blurb)
                    .font(QuietFont.small(14))
                    .foregroundStyle(store.theme.mute)
                Text(count == 1 ? "1 saved" : "\(count) saved")
                    .font(QuietFont.small(12))
                    .foregroundStyle(store.theme.accent)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(store.theme.mute)
        }
        .padding(16)
        .background(store.theme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JournalListView: View {
    @EnvironmentObject private var store: ReadingStore
    let kind: JournalKind
    @State private var compose: JournalEntry?

    var body: some View {
        List {
            if store.entries(for: kind).isEmpty {
                Text(emptyCopy)
                    .font(QuietFont.body(16))
                    .foregroundStyle(store.theme.mute)
                    .listRowBackground(Color.clear)
            }
            ForEach(store.entries(for: kind)) { entry in
                NavigationLink {
                    JournalEditor(entry: entry)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        if let first = entry.photoIds.first {
                            NotePhotoThumb(id: first)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title.isEmpty ? kind.singular : entry.title)
                                .font(QuietFont.display(18))
                                .foregroundStyle(store.theme.ink)
                            if !entry.body.isEmpty {
                                Text(entry.body)
                                    .font(QuietFont.body(15))
                                    .foregroundStyle(store.theme.mute)
                                    .lineLimit(2)
                            } else if entry.kind == .devotion, !entry.sitWith.isEmpty {
                                Text(entry.sitWith)
                                    .font(QuietFont.body(15))
                                    .foregroundStyle(store.theme.mute)
                                    .lineLimit(2)
                            } else if entry.kind == .devotion, !entry.prayerLine.isEmpty {
                                Text(entry.prayerLine)
                                    .font(QuietFont.body(15))
                                    .foregroundStyle(store.theme.mute)
                                    .lineLimit(2)
                            }
                            HStack(spacing: 8) {
                                Text(entry.updated.formatted(date: .abbreviated, time: .omitted))
                                if let bookId = entry.bookId, let chapter = entry.chapter {
                                    Text(store.placeLabel(bookId: bookId, chapter: chapter, verse: entry.verse, verseEnd: entry.verseEnd))
                                }
                                if entry.photoIds.count > 1 {
                                    Text("\(entry.photoIds.count) pictures")
                                } else if entry.photoIds.count == 1, entry.body.isEmpty {
                                    Text("Picture")
                                }
                            }
                            .font(QuietFont.small(12))
                            .foregroundStyle(store.theme.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
            }
            .onDelete { index in
                let items = store.entries(for: kind)
                index.map { items[$0] }.forEach(store.delete)
            }
        }
        .scrollContentBackground(.hidden)
        .background(store.theme.page)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .quietBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    compose = JournalEntry.blank(kind)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New \(kind.singular)")
            }
        }
        .navigationDestination(item: $compose) { entry in
            JournalEditor(entry: entry)
        }
    }

    private var emptyCopy: String {
        switch kind {
        case .note: return "Nothing here yet. Add a note from a chapter or from this page."
        case .comment: return "No comments yet. Write one here, or from a verse. The family will see it on the page."
        case .devotion: return "No devotions yet. Build one here, then open it anytime to review."
        case .prayer: return "No prayer requests yet. Write one when you are ready."
        case .answered: return "When a prayer is answered, mark it from the request."
        }
    }
}

struct JournalEditor: View {
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss
    @State var entry: JournalEntry
    @State private var attach = false
    @State private var originalPhotos: [String] = []
    @State private var createdPhotos: [String] = []
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                TextField(entry.kind == .devotion ? "Title — what this devotion is about" : "Title", text: $entry.title)
                    .font(QuietFont.display(20))
                if entry.kind == .devotion {
                    Text("The word")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                }
                TextEditor(text: $entry.body)
                    .font(QuietFont.body(17))
                    .frame(minHeight: entry.kind == .devotion ? 140 : 180)
                    .foregroundStyle(store.theme.ink)
                if entry.kind == .devotion {
                    Text("A prayer")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    TextEditor(text: $entry.prayerLine)
                        .font(QuietFont.body(17))
                        .frame(minHeight: 80)
                        .foregroundStyle(store.theme.ink)
                    Text("To sit with")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                    TextField("A question for later", text: $entry.sitWith)
                        .font(QuietFont.body(17))
                }
                NotePhotoComposer(ids: $entry.photoIds, created: $createdPhotos)
            }

            Section("Passage") {
                Toggle("Link \(store.placeTitle)", isOn: Binding(
                    get: { attach },
                    set: { on in
                        attach = on
                        if on {
                            entry.bookId = store.bookId
                            entry.chapter = store.chapter
                            entry.verse = store.focusVerse
                        } else {
                            entry.bookId = nil
                            entry.chapter = nil
                            entry.verse = nil
                        }
                    }
                ))
                if let bookId = entry.bookId, let chapter = entry.chapter {
                    Button("Open \(store.placeLabel(bookId: bookId, chapter: chapter, verse: entry.verse, verseEnd: entry.verseEnd))") {
                        if let book = store.book(id: bookId) {
                            store.open(book, chapter: chapter, verse: entry.verse)
                        }
                    }
                }
            }

            if entry.kind == .prayer {
                Section {
                    Button("Mark as answered") {
                        save()
                        store.markAnswered(entry)
                        dismiss()
                    }
                }
            }

            if store.entries.contains(where: { $0.id == entry.id }) {
                Section {
                    Button("Delete", role: .destructive) {
                        store.delete(entry)
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(store.theme.page)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(entry.kind.singular)
        .navigationBarTitleDisplayMode(.inline)
        .quietBar()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .fontWeight(.semibold)
                .accessibilityLabel("Save")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                save()
                dismiss()
            } label: {
                Text("Save")
                    .font(QuietFont.display(18))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(store.theme.page.ignoresSafeArea())
        }
        .onAppear {
            if entry.kind == .comment, entry.bookId == nil {
                attach = true
                entry.bookId = store.bookId
                entry.chapter = store.chapter
                entry.verse = store.focusVerse
            } else {
                attach = entry.bookId != nil
            }
            originalPhotos = entry.photoIds
        }
        .onDisappear {
            if saved {
                NotePhotos.delete(createdPhotos.filter { !entry.photoIds.contains($0) })
            } else {
                NotePhotos.delete(createdPhotos)
            }
        }
    }

    private func save() {
        entry.updated = Date()
        if entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            entry.title = entry.kind.singular
        }
        NotePhotos.delete(originalPhotos.filter { !entry.photoIds.contains($0) })
        saved = true
        store.upsert(entry)
    }
}

extension JournalEntry: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
