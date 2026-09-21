import SwiftUI

struct SearchHit: Identifiable {
    let id: String
    let book: Book
    let chapter: Int
    let verse: Int
    let text: String
    var lookup: Bool = false
}

struct SearchView: View {
    @EnvironmentObject private var store: ReadingStore
    @State private var query = ""
    @State private var hits: [SearchHit] = []
    @State private var reference: VerseRef?

    var body: some View {
        NavigationStack {
            List {
                if let reference {
                    Button {
                        store.open(reference)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Go to \(reference.heading)")
                                .font(QuietFont.display(20))
                                .foregroundStyle(store.theme.accent)
                            if let text = verseText(reference) {
                                Text(text)
                                    .font(QuietFont.body(17))
                                    .foregroundStyle(store.theme.ink)
                                    .lineLimit(6)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                if trimmed.count < 2, reference == nil {
                    Text("Try John 3:16, Ps 23, 1 Cor 13, or a word.")
                        .font(QuietFont.small(15))
                        .foregroundStyle(store.theme.mute)
                } else if hits.isEmpty, reference == nil {
                    Text("No verses in \(store.translation.label).")
                        .font(QuietFont.small(15))
                        .foregroundStyle(store.theme.mute)
                }

                ForEach(hits) { hit in
                    Button {
                        store.open(hit.book, chapter: hit.chapter, verse: hit.verse)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(hit.book.name) \(hit.chapter):\(hit.verse)")
                                .font(QuietFont.small(13))
                                .foregroundStyle(store.theme.accent)
                            Text(hit.text)
                                .font(QuietFont.body(17))
                                .foregroundStyle(store.theme.ink)
                                .lineLimit(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .navigationTitle("Search")
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .searchable(text: $query, prompt: "John 3:16 or a word")
            .onSubmit(of: .search) {
                if let reference { store.open(reference) }
            }
            .onChange(of: query) { _, value in
                refresh(value)
            }
            .onChange(of: store.translationId) { _, _ in
                refresh(query)
            }
        }
    }

    private var trimmed: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func refresh(_ raw: String) {
        reference = ScriptureLookup.parse(raw, books: store.translation.books)
        hits = find(raw)
    }

    private func verseText(_ ref: VerseRef) -> String? {
        let verses = ref.book.chapters[ref.chapter - 1]
        if let verse = ref.verse, verse >= 1, verse <= verses.count {
            return verses[verse - 1]
        }
        return verses.first
    }

    private func find(_ raw: String) -> [SearchHit] {
        let needle = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if reference != nil, needle.split(separator: " ").count <= 3 { return [] }
        guard needle.count >= 3 else { return [] }
        var out: [SearchHit] = []
        for book in store.translation.books {
            for (chapterIndex, verses) in book.chapters.enumerated() {
                for (verseIndex, text) in verses.enumerated() {
                    if text.lowercased().contains(needle) {
                        out.append(
                            SearchHit(
                                id: "\(book.id).\(chapterIndex + 1).\(verseIndex + 1)",
                                book: book,
                                chapter: chapterIndex + 1,
                                verse: verseIndex + 1,
                                text: text
                            )
                        )
                        if out.count >= 40 { return out }
                    }
                }
            }
        }
        return out
    }
}
