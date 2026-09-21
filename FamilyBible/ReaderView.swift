import SwiftUI
import UIKit

struct ReaderView: View {
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.horizontalSizeClass) private var size
    @State private var verseNote: VerseAnchor?
    @State private var noteHeight = PresentationDetent.large
    @State private var pickStart: Int?
    @State private var pickEnd: Int?
    @State private var pickWordStart: Int?
    @State private var pickWordEnd: Int?
    @State private var showPlaces = false
    @State private var markPulse = 0
    @State private var showChapterMaps = false

    var body: some View {
        NavigationStack {
            ZStack {
                store.theme.page.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(store.placeTitle)
                                        .font(QuietFont.display(28))
                                        .foregroundStyle(store.theme.ink)
                                        .accessibilityAddTraits(.isHeader)
                                        .accessibilityHint("Swipe to change chapter")
                                        .accessibilityAction(named: "Previous chapter") { turn(-1) }
                                        .accessibilityAction(named: "Next chapter") { turn(1) }
                                    if !chapterMaps.isEmpty {
                                        Button {
                                            showPlaces = false
                                            showChapterMaps = true
                                        } label: {
                                            Image(systemName: "map")
                                                .font(.system(size: 15, weight: .ultraLight))
                                                .foregroundStyle(store.theme.mute.opacity(0.48))
                                                .padding(.horizontal, 2)
                                                .padding(.bottom, 2)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(mapAccess)
                                    }
                                }
                                Text(store.translation.label)
                                    .font(QuietFont.small(13))
                                    .foregroundStyle(store.theme.mute)
                                swipeHint
                            }
                            VStack(alignment: .leading, spacing: store.fontSize * 0.5) {
                                ForEach(Array(store.currentVerses.enumerated()), id: \.offset) { index, verse in
                                    verseLine(number: index + 1, text: verse)
                                        .id("v\(index + 1)")
                                }
                            }
                        }
                        .padding(.horizontal, size == .regular ? 40 : 22)
                        .padding(.top, 8)
                        .padding(.bottom, pickStart == nil ? 20 : 140)
                        .frame(maxWidth: size == .regular ? 880 : 720, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: store.focusVerse) { _, verse in
                        guard let verse else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo("v\(verse)", anchor: .center)
                            }
                        }
                    }
                }
                .background(ChapterSwipe(back: { turn(-1) }, forward: { turn(1) }))
                .simultaneousGesture(chapterDrag)
                .onChange(of: store.chapter) { _, _ in
                    clearPick()
                    showPlaces = false
                    showChapterMaps = false
                }

                if showPlaces, pickStart == nil {
                    ZStack(alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.32, bounce: 0.2)) {
                                    showPlaces = false
                                }
                            }
                        VStack {
                            placesCard
                            Spacer().allowsHitTesting(false)
                        }
                        .padding(.horizontal, 16)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let start = pickStart, let end = pickEnd {
                    VStack {
                        Spacer().allowsHitTesting(false)
                        selectionBar(start: start, end: end)
                    }
                }
            }
            .animation(.spring(duration: 0.38, bounce: 0.22), value: showPlaces)
            .animation(.spring(duration: 0.38, bounce: 0.22), value: store.isAtPlace)
            .navigationBarTitleDisplayMode(.inline)
            .quietBar()
            .background {
                HStack {
                    Button("Previous chapter") { turn(-1) }
                        .keyboardShortcut(.leftArrow, modifiers: .command)
                    Button("Next chapter") { turn(1) }
                        .keyboardShortcut(.rightArrow, modifiers: .command)
                }
                .opacity(0.001)
                .accessibilityHidden(true)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { tapPlace() } label: {
                        Image(systemName: store.isAtPlace ? "book.fill" : "book")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(placeIconColor)
                            .contentTransition(.symbolEffect(.replace.downUp))
                            .symbolEffect(.bounce, value: markPulse)
                            .frame(width: 22, height: 22)
                            .overlay(alignment: .topTrailing) {
                                if store.bookmarks.count > 0 {
                                    placeBadge
                                }
                            }
                            .padding(8)
                    }
                    .accessibilityLabel(placeAccess)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .sheet(item: $verseNote) { anchor in
                VerseNoteSheet(
                    verse: anchor.start,
                    verseEnd: anchor.end,
                    startKind: anchor.kind,
                    wordStart: anchor.wordStart,
                    wordEnd: anchor.wordEnd,
                    wordText: anchor.wordText
                )
                    .environmentObject(store)
                    .presentationDetents([.medium, .large], selection: $noteHeight)
                    .onAppear { noteHeight = .large }
            }
            .sheet(isPresented: $showChapterMaps) {
                ChapterMapSheet(maps: chapterMaps, heading: store.placeTitle)
                    .environmentObject(store)
            }
        }
    }

    private var placeIconColor: Color {
        if store.isAtPlace { return store.theme.gold }
        if store.theme.scheme == .light {
            return store.theme.ink.opacity(store.savedPlace == nil ? 0.62 : 0.82)
        }
        return store.theme.mute.opacity(store.savedPlace == nil ? 0.7 : 0.9)
    }

    private var placeBadge: some View {
        let count = store.bookmarks.count
        return Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: count > 9 ? 8 : 9, weight: .bold))
            .foregroundStyle(.black)
            .frame(minWidth: 15, minHeight: 15)
            .padding(.horizontal, count > 9 ? 3 : 0)
            .background(store.theme.gold, in: Capsule())
            .offset(x: 5, y: -5)
            .accessibilityHidden(true)
    }

    private var chapterMaps: [BibleMap] {
        BibleMaps.forChapter(bookId: store.bookId, chapter: store.chapter)
    }

    private var mapAccess: String {
        if chapterMaps.count == 1, let only = chapterMaps.first {
            return "Map: \(only.title)"
        }
        return "\(chapterMaps.count) maps for this chapter"
    }

    private var placeAccess: String {
        showPlaces ? "Close places" : "Places"
    }

    private func tapPlace() {
        withAnimation(.spring(duration: 0.38, bounce: 0.22)) {
            showPlaces.toggle()
        }
    }

    private func addPlace() {
        withAnimation(.spring(duration: 0.38, bounce: 0.22)) {
            store.markPlace(verse: pickStart ?? store.focusVerse)
            markPulse += 1
            showPlaces = true
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private var placesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: addPlace) {
                Text(store.isAtPlace ? "Place saved" : "Mark this place")
                    .font(QuietFont.display(17))
                    .foregroundStyle(store.theme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(store.theme.dark, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(store.theme.gold, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            if store.bookmarks.isEmpty {
                Text("Nothing marked yet.")
                    .font(QuietFont.small(13))
                    .foregroundStyle(store.theme.mute)
            } else {
                ForEach(store.bookmarks, id: \.self) { place in
                    HStack(spacing: 10) {
                        Button {
                            store.open(place)
                            withAnimation(.spring(duration: 0.32, bounce: 0.2)) { showPlaces = false }
                        } label: {
                            HStack {
                                Text(store.bookmarkLabel(place))
                                    .font(QuietFont.body(17))
                                    .foregroundStyle(store.theme.ink)
                                Spacer()
                                if place.bookId == store.bookId && place.chapter == store.chapter {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 11, weight: .ultraLight))
                                        .foregroundStyle(store.theme.mute)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        Button {
                            withAnimation(.spring(duration: 0.32, bounce: 0.2)) {
                                store.removePlace(place)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(store.theme.mute.opacity(0.55))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(store.bookmarkLabel(place))")
                    }
                }
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(store.theme.page)
                .shadow(color: store.theme.ink.opacity(0.14), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(store.theme.ink.opacity(0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var swipeHint: some View {
        HStack(spacing: 8) {
            hintChevron(-1)
            Text("swipe")
                .font(.system(size: 11, weight: .ultraLight))
                .foregroundStyle(store.theme.mute.opacity(0.38))
            hintChevron(1)
        }
        .padding(.top, 4)
    }

    private func hintChevron(_ delta: Int) -> some View {
        let title = store.neighborTitle(delta)
        return Button { turn(delta) } label: {
            Image(systemName: delta < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 11, weight: .ultraLight))
                .foregroundStyle(store.theme.mute.opacity(title == nil ? 0.15 : 0.38))
        }
        .buttonStyle(.plain)
        .disabled(title == nil)
        .accessibilityLabel(delta < 0 ? "Previous chapter" : "Next chapter")
    }

    private var chapterDrag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let width = value.translation.width
                let height = value.translation.height
                guard abs(width) > 70, abs(width) > abs(height) * 1.4 else { return }
                turn(width < 0 ? 1 : -1)
            }
    }

    private func turn(_ delta: Int) {
        guard store.neighborTitle(delta) != nil else { return }
        clearPick()
        store.go(delta)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func clearPick() {
        pickStart = nil
        pickEnd = nil
        pickWordStart = nil
        pickWordEnd = nil
    }

    private func tapVerse(_ number: Int) {
        store.focusVerse = number
        if let start = pickStart, let end = pickEnd {
            pickStart = min(start, number)
            pickEnd = max(end, number)
        } else {
            pickStart = number
            pickEnd = number
        }
        if pickStart != pickEnd {
            pickWordStart = nil
            pickWordEnd = nil
        }
    }

    private func tapWord(verse: Int, index: Int) {
        if pickStart == nil {
            if let item = store.familyOn(bookId: store.bookId, chapter: store.chapter, verse: verse).first(where: { item in
                guard let start = item.entry.wordIndex else { return false }
                let end = item.entry.wordEnd ?? start
                return index >= min(start, end) && index <= max(start, end)
            }) {
                verseNote = VerseAnchor(
                    start: verse,
                    end: verse,
                    kind: .comment,
                    wordStart: item.entry.wordIndex,
                    wordEnd: item.entry.wordEnd,
                    wordText: item.entry.wordText
                )
            }
            return
        }
        if pickStart == verse, pickEnd == verse {
            if let first = pickWordStart {
                let last = pickWordEnd ?? first
                if index == first, index == last {
                    pickWordStart = nil
                    pickWordEnd = nil
                } else {
                    pickWordStart = min(first, index)
                    pickWordEnd = max(last, index)
                }
            } else {
                pickWordStart = index
                pickWordEnd = index
            }
            return
        }
        tapVerse(verse)
    }

    private func pickedWordText(in verse: Int) -> String? {
        guard pickStart == verse, pickEnd == verse, let first = pickWordStart else { return nil }
        let last = pickWordEnd ?? first
        let verses = store.currentVerses
        guard verse >= 1, verse <= verses.count else { return nil }
        let tokens = VerseWords.split(verses[verse - 1])
        guard first < tokens.count else { return nil }
        return tokens[first...min(last, tokens.count - 1)].joined(separator: " ")
    }

    private func noteAnchor(start: Int, end: Int, kind: JournalKind) -> VerseAnchor {
        var word: String?
        var w0 = pickWordStart
        var w1 = pickWordEnd
        if start == end, let text = pickedWordText(in: start) {
            word = text
        } else {
            w0 = nil
            w1 = nil
        }
        return VerseAnchor(start: start, end: end, kind: kind, wordStart: w0, wordEnd: w1, wordText: word)
    }

    private func outlinedAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(QuietFont.small(15))
                .foregroundStyle(store.theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(store.theme.dark, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(store.theme.gold, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func selectionBar(start: Int, end: Int) -> some View {
        let word = start == end ? pickedWordText(in: start) : nil
        let label = store.placeLabel(bookId: store.bookId, chapter: store.chapter, verse: start, verseEnd: end, word: word)
        return VStack(spacing: 10) {
            Text(label)
                .font(QuietFont.display(18))
                .foregroundStyle(store.theme.ink)
            Text(start == end
                 ? (word == nil ? "Tap a word in the verse, or tap another verse." : "Note or comment will sit on that word.")
                 : "Tap another verse to widen the range.")
                .font(QuietFont.small(13))
                .foregroundStyle(store.theme.mute)
            HStack(spacing: 10) {
                outlinedAction("Clear") { clearPick() }
                outlinedAction("Note") {
                    verseNote = noteAnchor(start: start, end: end, kind: .note)
                }
                outlinedAction("Comment") {
                    verseNote = noteAnchor(start: start, end: end, kind: .comment)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(store.theme.page)
                .shadow(color: store.theme.ink.opacity(0.16), radius: 18, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(store.theme.ink.opacity(0.08), lineWidth: 1)
        )
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func verseLine(number: Int, text: String) -> some View {
        let focused = pickStart.map { number >= $0 && number <= (pickEnd ?? $0) } ?? false
        let noted = store.hasNote(verse: number)
        let comments = store.commentsOn(verse: number)
        let marks = store.wordMarks(verse: number)
        let pickingWords = pickStart == number && pickEnd == number
        var selected = Set<Int>()
        if pickingWords, let first = pickWordStart {
            let last = pickWordEnd ?? first
            for n in min(first, last)...max(first, last) { selected.insert(n) }
        }
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number)")
                    .font(.system(size: store.fontSize * 0.62, weight: .medium, design: .serif))
                    .foregroundStyle(noted ? store.theme.gold : store.theme.mute)
                    .frame(width: store.fontSize * 1.15, alignment: .trailing)
                if pickingWords || !marks.isEmpty {
                    WordFlow(
                        tokens: VerseWords.split(text),
                        fontSize: store.fontSize,
                        ink: store.theme.ink,
                        gold: store.theme.gold,
                        selected: selected,
                        marked: marks,
                        onTap: { tapWord(verse: number, index: $0) }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(text)
                        .font(QuietFont.body(store.fontSize))
                        .foregroundStyle(store.theme.ink)
                        .lineSpacing(store.fontSize * 0.28)
                        .multilineTextAlignment(.leading)
                }
                if noted {
                    Image(systemName: comments.isEmpty ? "pencil.circle.fill" : "text.bubble.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(store.theme.gold)
                }
            }
            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comments) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(item.profile.name)
                                    .font(QuietFont.small(12))
                                    .foregroundStyle(store.theme.accent)
                                if let word = item.entry.wordText, !word.isEmpty {
                                    Text("on “\(word)”")
                                        .font(QuietFont.small(12))
                                        .foregroundStyle(store.theme.gold)
                                }
                            }
                            if !item.entry.body.isEmpty {
                                Text(item.entry.body)
                                    .font(QuietFont.body(store.fontSize * 0.86))
                                    .italic()
                                    .foregroundStyle(store.theme.mute)
                            }
                        }
                    }
                }
                .padding(.leading, store.fontSize * 1.15 + 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    verseNote = VerseAnchor(start: number, end: number, kind: .comment)
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            focused ? store.theme.gold.opacity(0.14) : (noted ? store.theme.gold.opacity(0.08) : .clear),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(focused ? store.theme.gold : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if pickStart != nil { tapVerse(number) }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            tapVerse(number)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .accessibilityLabel(comments.isEmpty
            ? "Verse \(number). Hold one second for the note menu, then tap a word."
            : "Verse \(number), \(comments.count) comment\(comments.count == 1 ? "" : "s"). Hold one second for the note menu, then tap a word.")
    }
}

struct VerseAnchor: Identifiable {
    var id: String { "\(start)-\(end)-\(kind.rawValue)-\(wordStart ?? -1)-\(wordEnd ?? -1)" }
    let start: Int
    let end: Int
    var kind: JournalKind = .note
    var wordStart: Int?
    var wordEnd: Int?
    var wordText: String?
}

struct VerseNoteSheet: View {
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss
    let verse: Int
    var verseEnd: Int
    var startKind: JournalKind = .note
    var wordStart: Int?
    var wordEnd: Int?
    var wordText: String?
    @State private var bodyText = ""
    @State private var kind: JournalKind = .note
    @State private var photos: [String] = []
    @State private var createdPhotos: [String] = []
    @State private var saved = false

    private var lastVerse: Int { max(verse, verseEnd) }
    private var firstVerse: Int { min(verse, verseEnd) }

    private var reference: String {
        store.placeLabel(bookId: store.bookId, chapter: store.chapter, verse: firstVerse, verseEnd: lastVerse, word: wordText)
    }

    private var datedTitle: String {
        store.datedReference(bookId: store.bookId, chapter: store.chapter, verse: firstVerse, verseEnd: lastVerse, word: wordText)
    }

    private var existing: [FamilyNote] {
        store.familyOn(bookId: store.bookId, chapter: store.chapter, verse: firstVerse)
    }

    private var selectedTexts: [String] {
        guard firstVerse >= 1, lastVerse <= store.currentVerses.count else { return [] }
        return Array(store.currentVerses[(firstVerse - 1)..<lastVerse])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(reference)
                        .font(QuietFont.display(22))
                        .foregroundStyle(store.theme.ink)
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(QuietFont.small(14))
                        .foregroundStyle(store.theme.accent)
                    ForEach(Array(selectedTexts.enumerated()), id: \.offset) { index, text in
                        Text("\(firstVerse + index)  \(text)")
                            .font(QuietFont.body(16))
                            .foregroundStyle(store.theme.mute)
                    }
                    if let word = wordText, !word.isEmpty {
                        Text("On “\(word)”")
                            .font(QuietFont.small(14))
                            .foregroundStyle(store.theme.gold)
                    }
                }

                if !existing.isEmpty {
                    Section(firstVerse == lastVerse ? "On this verse" : "On this range") {
                        ForEach(existing) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.profile.name)
                                        .font(QuietFont.small(12))
                                        .foregroundStyle(store.theme.accent)
                                    Text(item.entry.kind.singular)
                                        .font(QuietFont.small(12))
                                        .foregroundStyle(store.theme.mute)
                                    if let word = item.entry.wordText, !word.isEmpty {
                                        Text("“\(word)”")
                                            .font(QuietFont.small(12))
                                            .foregroundStyle(store.theme.gold)
                                    }
                                }
                                Text(item.entry.title)
                                    .font(QuietFont.display(16))
                                if !item.entry.body.isEmpty {
                                    Text(item.entry.body)
                                        .font(QuietFont.body(15))
                                        .foregroundStyle(store.theme.mute)
                                }
                                Text(item.entry.created.formatted(date: .abbreviated, time: .shortened))
                                    .font(QuietFont.small(12))
                                    .foregroundStyle(store.theme.accent)
                                NotePhotoFilm(ids: item.entry.photoIds)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section(kind == .comment ? "New comment" : kind == .devotion ? "New devotion" : kind == .prayer ? "New prayer" : "New note") {
                    Picker("Save as", selection: $kind) {
                        Text("Note").tag(JournalKind.note)
                        Text("Comment").tag(JournalKind.comment)
                        Text("Devotion").tag(JournalKind.devotion)
                        Text("Prayer").tag(JournalKind.prayer)
                    }
                    .pickerStyle(.segmented)
                    TextEditor(text: $bodyText)
                        .font(QuietFont.body(17))
                        .frame(minHeight: 140)
                    NotePhotoComposer(ids: $photos, created: $createdPhotos)
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(kind == .comment ? "Comment" : "Verse note")
            .navigationBarTitleDisplayMode(.inline)
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        Image(systemName: "checkmark")
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                    .accessibilityLabel("Save")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text(saveLabel)
                        .font(QuietFont.display(18))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.theme.accent)
                .disabled(!canSave)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(store.theme.page.ignoresSafeArea())
            }
            .onAppear {
                kind = startKind
            }
            .onDisappear {
                if saved {
                    NotePhotos.delete(createdPhotos.filter { !photos.contains($0) })
                } else {
                    NotePhotos.delete(createdPhotos)
                }
            }
        }
    }

    private var canSave: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !photos.isEmpty
    }

    private var saveLabel: String {
        switch kind {
        case .comment: return "Save comment"
        case .devotion: return "Save devotion"
        case .prayer: return "Save prayer"
        default: return "Save note"
        }
    }

    private func save() {
        var entry = JournalEntry.blank(
            .note,
            bookId: store.bookId,
            chapter: store.chapter,
            verse: firstVerse,
            verseEnd: lastVerse == firstVerse ? nil : lastVerse
        )
        entry.kind = kind
        entry.title = datedTitle
        entry.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.photoIds = photos
        entry.wordIndex = wordStart
        entry.wordEnd = wordEnd
        entry.wordText = wordText
        store.upsert(entry)
        store.focusVerse = firstVerse
        saved = true
        dismiss()
    }
}

private struct ChapterSwipe: UIViewRepresentable {
    var back: () -> Void
    var forward: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(back: back, forward: forward)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.back = back
        context.coordinator.forward = forward
        context.coordinator.attach(from: view)
    }

    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var back: () -> Void
        var forward: () -> Void
        weak var host: UIView?
        private var leftSwipe: UISwipeGestureRecognizer?
        private var rightSwipe: UISwipeGestureRecognizer?

        init(back: @escaping () -> Void, forward: @escaping () -> Void) {
            self.back = back
            self.forward = forward
        }

        func attach(from probe: UIView) {
            DispatchQueue.main.async { [weak self, weak probe] in
                guard let self, let host = probe?.superview else { return }
                if self.host === host { return }
                self.detach()
                let left = UISwipeGestureRecognizer(target: self, action: #selector(goForward))
                left.direction = .left
                left.delegate = self
                let right = UISwipeGestureRecognizer(target: self, action: #selector(goBack))
                right.direction = .right
                right.delegate = self
                host.addGestureRecognizer(left)
                host.addGestureRecognizer(right)
                self.leftSwipe = left
                self.rightSwipe = right
                self.host = host
            }
        }

        func detach() {
            if let leftSwipe { host?.removeGestureRecognizer(leftSwipe) }
            if let rightSwipe { host?.removeGestureRecognizer(rightSwipe) }
            leftSwipe = nil
            rightSwipe = nil
            host = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        @objc func goForward() { forward() }
        @objc func goBack() { back() }
    }
}

enum VerseWords {
    static func split(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }
}

private struct WordFlow: View {
    let tokens: [String]
    let fontSize: Double
    let ink: Color
    let gold: Color
    let selected: Set<Int>
    let marked: Set<Int>
    let onTap: (Int) -> Void

    var body: some View {
        WordWrap(spacing: fontSize * 0.28, lineSpacing: fontSize * 0.28) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                let hot = selected.contains(index)
                let noted = marked.contains(index)
                Button {
                    onTap(index)
                } label: {
                    Text(token)
                        .font(QuietFont.body(fontSize))
                        .foregroundStyle(ink)
                        .padding(.horizontal, hot || noted ? 3 : 0)
                        .background(
                            (hot ? gold.opacity(0.38) : noted ? gold.opacity(0.2) : Color.clear),
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(hot ? gold : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(noted ? "\(token), has a note" : token)
            }
        }
    }
}

private struct WordWrap: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (sub, origin) in zip(subviews, result.origins) {
            sub.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var width: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
            width = max(width, x - spacing)
        }
        return (CGSize(width: width, height: y + lineHeight), origins)
    }
}
