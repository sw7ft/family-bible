import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: ReadingStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        store.tab = "read"
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Continue")
                                .font(QuietFont.small(12))
                                .foregroundStyle(store.theme.mute)
                            Text(store.placeTitle)
                                .font(QuietFont.display(24))
                                .foregroundStyle(store.theme.ink)
                            Text(store.translation.label)
                                .font(QuietFont.small(13))
                                .foregroundStyle(store.theme.accent)
                        }
                        .padding(.vertical, 8)
                    }
                }

                if !store.bookmarks.isEmpty {
                    Section("Places") {
                        ForEach(store.bookmarks, id: \.self) { item in
                            Button(store.bookmarkLabel(item)) {
                                store.open(item)
                            }
                            .foregroundStyle(store.theme.ink)
                        }
                        .onDelete { index in
                            index.map { store.bookmarks[$0] }.forEach(store.removePlace)
                        }
                    }
                }

                section("Old Testament", "ot")
                section("New Testament", "nt")

                Section {
                    NavigationLink {
                        MapsView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maps")
                                .font(QuietFont.display(22))
                                .foregroundStyle(store.theme.ink)
                            Text("Twenty-four plates from the 1915 atlas — public domain.")
                                .font(QuietFont.small(13))
                                .foregroundStyle(store.theme.mute)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .navigationTitle("Books")
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
        }
    }

    private func section(_ title: String, _ testament: String) -> some View {
        Section(title) {
            ForEach(store.translation.books.filter { $0.testament == testament }) { book in
                NavigationLink {
                    ChapterPicker(book: book)
                } label: {
                    HStack {
                        Text(book.name)
                            .font(QuietFont.body(18))
                            .foregroundStyle(store.theme.ink)
                        Spacer()
                        Text("\(book.chapterCount)")
                            .font(QuietFont.small(13))
                            .foregroundStyle(store.theme.mute)
                    }
                }
            }
        }
    }
}

struct ChapterPicker: View {
    @EnvironmentObject private var store: ReadingStore
    let book: Book
    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    Button {
                        store.open(book, chapter: chapter)
                    } label: {
                        Text("\(chapter)")
                            .font(QuietFont.body(17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(chip(chapter), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(store.theme.ink)
                            .overlay(alignment: .topTrailing) {
                                if BibleMaps.hasMap(bookId: book.id, chapter: chapter) {
                                    Image(systemName: "map")
                                        .font(.system(size: 7, weight: .ultraLight))
                                        .foregroundStyle(store.theme.mute.opacity(0.45))
                                        .padding(4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(store.theme.page)
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .quietBar()
    }

    private func chip(_ chapter: Int) -> Color {
        store.bookId == book.id && store.chapter == chapter
            ? store.theme.accent.opacity(0.22)
            : store.theme.ink.opacity(0.06)
    }
}
