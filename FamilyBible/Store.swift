import Foundation
import SwiftUI

struct BibleProfile: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
}

@MainActor
final class ReadingStore: ObservableObject {
    @Published var translationId: String {
        didSet { UserDefaults.standard.set(translationId, forKey: "qb.translation") }
    }
    @Published var theme: ReadingTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "qb.theme") }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "qb.fontSize") }
    }
    @Published var bookId: String {
        didSet { persistPlace() }
    }
    @Published var chapter: Int {
        didSet { persistPlace() }
    }
    @Published var bookmarks: [Passage] {
        didSet { persistBookmarks() }
    }
    @Published var profiles: [BibleProfile] {
        didSet { persistProfiles() }
    }
    @Published var profileId: UUID {
        didSet { UserDefaults.standard.set(profileId.uuidString, forKey: "qb.profileId") }
    }
    @Published var tab: String {
        didSet { UserDefaults.standard.set(tab, forKey: "qb.tab") }
    }
    @Published var focusVerse: Int?
    @Published var entries: [JournalEntry] {
        didSet { persistJournal() }
    }
    @Published var journalOpen: JournalKind?
    @Published var journalAttachPlace = false
    @Published var journalVerse: Int?
    @Published private(set) var familyJournal: [FamilyNote] = []

    @Published private(set) var translation: Translation
    private var ready = false

    var currentProfile: BibleProfile? {
        profiles.first { $0.id == profileId } ?? profiles.first
    }

    init() {
        let tid = UserDefaults.standard.string(forKey: "qb.translation") ?? "webu"
        translationId = tid
        translation = BibleLibrary.load(tid)
        theme = ReadingTheme(rawValue: UserDefaults.standard.string(forKey: "qb.theme") ?? "") ?? .paper
        let savedSize = UserDefaults.standard.double(forKey: "qb.fontSize")
        fontSize = savedSize >= 16 ? savedSize : 21
        let loaded = Self.loadOrMigrateProfiles()
        profiles = loaded.profiles
        profileId = loaded.profileId
        bookmarks = []
        entries = []
        tab = UserDefaults.standard.string(forKey: "qb.tab") ?? "read"
        bookId = "john"
        chapter = 1
        applyProfileData(Self.readProfileBundle(id: loaded.profileId), persistLegacy: false)
        if book(id: bookId) == nil {
            bookId = translation.books.first?.id ?? "genesis"
            chapter = 1
        }
        clampChapter()
        ready = true
        if loaded.migrated {
            persistProfiles()
            persistProfileBundle()
        }
        refreshFamilyJournal()
    }

    var currentBook: Book? { book(id: bookId) }

    var currentVerses: [String] {
        guard let book = currentBook, chapter >= 1, chapter <= book.chapterCount else { return [] }
        return book.chapters[chapter - 1]
    }

    var placeTitle: String {
        guard let book = currentBook else { return "Family Bible" }
        return "\(book.name) \(chapter)"
    }

    func book(id: String) -> Book? {
        translation.books.first { $0.id == id }
    }

    func open(_ book: Book, chapter: Int = 1, verse: Int? = nil) {
        bookId = book.id
        self.chapter = min(max(1, chapter), book.chapterCount)
        focusVerse = verse
        tab = "read"
    }

    func open(_ ref: VerseRef) {
        open(ref.book, chapter: ref.chapter, verse: ref.verse)
    }

    func open(_ passage: Passage) {
        if passage.translation != translationId {
            setTranslation(passage.translation)
        }
        bookId = passage.bookId
        chapter = passage.chapter
        clampChapter()
        focusVerse = passage.verse
        tab = "read"
    }

    func setTranslation(_ id: String) {
        translationId = id
        translation = BibleLibrary.load(id)
        if book(id: bookId) == nil {
            bookId = translation.books.first?.id ?? "genesis"
            chapter = 1
        }
        clampChapter()
    }

    func go(_ delta: Int) {
        focusVerse = nil
        guard let step = neighbor(delta) else { return }
        bookId = step.book.id
        chapter = step.chapter
    }

    func neighborTitle(_ delta: Int) -> String? {
        guard let step = neighbor(delta) else { return nil }
        if step.book.id == bookId {
            return "\(step.chapter)"
        }
        return step.book.name
    }

    private func neighbor(_ delta: Int) -> (book: Book, chapter: Int)? {
        guard let book = currentBook,
              let index = translation.books.firstIndex(where: { $0.id == book.id }) else { return nil }
        let next = chapter + delta
        if next >= 1, next <= book.chapterCount {
            return (book, next)
        }
        if delta > 0, index + 1 < translation.books.count {
            return (translation.books[index + 1], 1)
        }
        if delta < 0, index > 0 {
            let previous = translation.books[index - 1]
            return (previous, previous.chapterCount)
        }
        return nil
    }

    var savedPlace: Passage? { bookmarks.first }

    var isAtPlace: Bool {
        bookmarks.contains { $0.bookId == bookId && $0.chapter == chapter }
    }

    func markPlace(verse: Int? = nil) {
        let here = Passage(translation: translationId, bookId: bookId, chapter: chapter, verse: verse)
        bookmarks.removeAll { $0 == here }
        bookmarks.insert(here, at: 0)
    }

    func removePlace(_ passage: Passage) {
        bookmarks.removeAll { $0 == passage }
    }

    func goToPlace() {
        guard let place = savedPlace else {
            markPlace(verse: focusVerse)
            return
        }
        if isAtPlace, let here = bookmarks.first(where: { $0.bookId == bookId && $0.chapter == chapter }) {
            if let verse = here.verse { focusVerse = verse }
            return
        }
        open(place)
    }

    func entries(for kind: JournalKind) -> [JournalEntry] {
        entries.filter { $0.kind == kind }.sorted { $0.updated > $1.updated }
    }

    func upsert(_ entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        refreshFamilyJournal()
    }

    func delete(_ entry: JournalEntry) {
        NotePhotos.delete(entry.photoIds)
        entries.removeAll { $0.id == entry.id }
        refreshFamilyJournal()
    }

    func markAnswered(_ entry: JournalEntry) {
        var next = entry
        next.kind = .answered
        next.updated = Date()
        upsert(next)
    }

    func switchProfile(_ id: UUID) {
        guard id != profileId, profiles.contains(where: { $0.id == id }) else { return }
        persistProfileBundle()
        ready = false
        profileId = id
        applyProfileData(Self.readProfileBundle(id: id), persistLegacy: false)
        if book(id: bookId) == nil {
            bookId = translation.books.first?.id ?? "genesis"
            chapter = 1
        }
        clampChapter()
        focusVerse = nil
        ready = true
        refreshFamilyJournal()
    }

    func addProfile(named name: String) {
        persistProfileBundle()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = BibleProfile(id: UUID(), name: trimmed.isEmpty ? nextProfileName() : trimmed)
        profiles.append(profile)
        ready = false
        profileId = profile.id
        bookmarks = []
        entries = []
        bookId = "john"
        chapter = 1
        ready = true
        persistProfileBundle()
        refreshFamilyJournal()
    }

    func renameProfile(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].name = trimmed
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1, let doomed = profiles.first(where: { $0.id == id }) else { return }
        let leftover = Self.readProfileBundle(id: doomed.id).entries
        NotePhotos.delete(leftover.flatMap(\.photoIds))
        if profileId == doomed.id, let next = profiles.first(where: { $0.id != doomed.id }) {
            ready = false
            profileId = next.id
            applyProfileData(Self.readProfileBundle(id: next.id), persistLegacy: false)
            if book(id: bookId) == nil {
                bookId = translation.books.first?.id ?? "genesis"
                chapter = 1
            }
            clampChapter()
            focusVerse = nil
            ready = true
        }
        Self.removeProfileKeys(doomed.id)
        profiles.removeAll { $0.id == doomed.id }
        refreshFamilyJournal()
    }

    private func nextProfileName() -> String {
        let used = Set(profiles.map(\.name))
        if !used.contains("Family") { return "Family" }
        var n = 2
        while used.contains("Profile \(n)") { n += 1 }
        return "Profile \(n)"
    }

    private struct ProfileBundle {
        var bookId: String
        var chapter: Int
        var bookmarks: [Passage]
        var entries: [JournalEntry]
    }

    private static func loadOrMigrateProfiles() -> (profiles: [BibleProfile], profileId: UUID, migrated: Bool) {
        if let data = UserDefaults.standard.data(forKey: "qb.profiles"),
           let items = try? JSONDecoder().decode([BibleProfile].self, from: data),
           !items.isEmpty {
            let raw = UserDefaults.standard.string(forKey: "qb.profileId").flatMap(UUID.init(uuidString:))
            let id = items.contains(where: { $0.id == raw }) ? raw! : items[0].id
            return (items, id, false)
        }
        let family = BibleProfile(id: UUID(), name: "Family")
        return ([family], family.id, true)
    }

    private static func readProfileBundle(id: UUID) -> ProfileBundle {
        let defaults = UserDefaults.standard
        let book = defaults.string(forKey: "qb.p.\(id.uuidString).book")
            ?? defaults.string(forKey: "qb.book")
            ?? "john"
        let savedChapter = defaults.object(forKey: "qb.p.\(id.uuidString).chapter") as? Int
            ?? defaults.integer(forKey: "qb.chapter")
        let bookmarkData = defaults.data(forKey: "qb.p.\(id.uuidString).bookmarks")
            ?? defaults.data(forKey: "qb.bookmarks")
        let journalData = defaults.data(forKey: "qb.p.\(id.uuidString).journal")
            ?? defaults.data(forKey: "qb.journal")
        let marks: [Passage]
        if let bookmarkData, let items = try? JSONDecoder().decode([StoredPassage].self, from: bookmarkData) {
            marks = items.map { Passage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse) }
        } else {
            marks = []
        }
        let notes: [JournalEntry]
        if let journalData, let items = try? JSONDecoder().decode([JournalEntry].self, from: journalData) {
            notes = items
        } else {
            notes = []
        }
        return ProfileBundle(bookId: book, chapter: max(1, savedChapter), bookmarks: marks, entries: notes)
    }

    private func applyProfileData(_ bundle: ProfileBundle, persistLegacy: Bool) {
        bookId = bundle.bookId
        chapter = bundle.chapter
        bookmarks = bundle.bookmarks
        entries = bundle.entries
        if persistLegacy {
            persistProfileBundle()
        }
    }

    private func persistProfiles() {
        guard ready else { return }
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: "qb.profiles")
        }
    }

    private func persistProfileBundle() {
        let defaults = UserDefaults.standard
        let prefix = "qb.p.\(profileId.uuidString)"
        defaults.set(bookId, forKey: "\(prefix).book")
        defaults.set(chapter, forKey: "\(prefix).chapter")
        let items = bookmarks.map { StoredPassage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse) }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: "\(prefix).bookmarks")
        }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: "\(prefix).journal")
        }
    }

    private static func removeProfileKeys(_ id: UUID) {
        let defaults = UserDefaults.standard
        let prefix = "qb.p.\(id.uuidString)"
        defaults.removeObject(forKey: "\(prefix).book")
        defaults.removeObject(forKey: "\(prefix).chapter")
        defaults.removeObject(forKey: "\(prefix).bookmarks")
        defaults.removeObject(forKey: "\(prefix).journal")
    }

    func startJournal(_ kind: JournalKind, attachPlace: Bool = false, verse: Int? = nil) {
        journalAttachPlace = attachPlace
        journalVerse = verse
        journalOpen = kind
        tab = "journal"
    }

    func notes(bookId: String, chapter: Int, verse: Int? = nil) -> [JournalEntry] {
        familyOn(bookId: bookId, chapter: chapter, verse: verse).map(\.entry)
    }

    func familyOn(bookId: String, chapter: Int, verse: Int? = nil) -> [FamilyNote] {
        familyJournal.filter { item in
            item.entry.bookId == bookId &&
            item.entry.chapter == chapter &&
            (verse == nil || item.entry.covers(verse: verse!))
        }.sorted { $0.entry.updated > $1.entry.updated }
    }

    func commentsOn(verse: Int) -> [FamilyNote] {
        familyOn(bookId: bookId, chapter: chapter, verse: verse).filter { $0.entry.kind == .comment }
    }

    func exportFamily() throws -> Data {
        persistProfileBundle()
        let people = profiles.map { profile -> FamilyPersonFile in
            let bundle = profile.id == profileId
                ? ProfileBundle(bookId: bookId, chapter: chapter, bookmarks: bookmarks, entries: entries)
                : Self.readProfileBundle(id: profile.id)
            return FamilyPersonFile(
                id: profile.id,
                name: profile.name,
                bookId: bundle.bookId,
                chapter: bundle.chapter,
                bookmarks: bundle.bookmarks.map {
                    StoredPassage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse)
                },
                entries: bundle.entries
            )
        }
        var photos: [String: String] = [:]
        for person in people {
            for entry in person.entries {
                for id in entry.photoIds where photos[id] == nil {
                    if let data = try? Data(contentsOf: NotePhotos.url(id)) {
                        photos[id] = data.base64EncodedString()
                    }
                }
            }
        }
        let pack = FamilyPackFile(
            format: 1,
            app: "Family Bible",
            exported: Date(),
            profileId: profileId,
            profiles: people,
            photos: photos
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(pack)
    }

    func importFamily(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(FamilyPackFile.self, from: data)
        guard pack.format == 1 else {
            throw FamilyPackError.unsupported
        }
        persistProfileBundle()
        for (id, encoded) in pack.photos {
            if let bytes = Data(base64Encoded: encoded) {
                try? bytes.write(to: NotePhotos.url(id), options: .atomic)
            }
        }
        ready = false
        for person in pack.profiles {
            if profiles.contains(where: { $0.id == person.id }) {
                if let idx = profiles.firstIndex(where: { $0.id == person.id }), !person.name.isEmpty {
                    profiles[idx].name = person.name
                }
            } else {
                profiles.append(BibleProfile(id: person.id, name: person.name.isEmpty ? nextProfileName() : person.name))
            }
            let incomingMarks = person.bookmarks.map {
                Passage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse)
            }
            if person.id == profileId {
                for mark in incomingMarks where !bookmarks.contains(mark) {
                    bookmarks.append(mark)
                }
                for entry in person.entries {
                    if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                        entries[idx] = entry
                    } else {
                        entries.append(entry)
                    }
                }
                if book(id: person.bookId) != nil {
                    bookId = person.bookId
                    chapter = max(1, person.chapter)
                }
            } else {
                let existing = Self.readProfileBundle(id: person.id)
                var marks = existing.bookmarks
                for mark in incomingMarks where !marks.contains(mark) {
                    marks.append(mark)
                }
                var notes = existing.entries
                for entry in person.entries {
                    if let idx = notes.firstIndex(where: { $0.id == entry.id }) {
                        notes[idx] = entry
                    } else {
                        notes.append(entry)
                    }
                }
                writeBundle(id: person.id, bookId: person.bookId, chapter: person.chapter, bookmarks: marks, entries: notes)
            }
        }
        ready = true
        persistProfiles()
        persistProfileBundle()
        refreshFamilyJournal()
    }

    private func writeBundle(id: UUID, bookId: String, chapter: Int, bookmarks: [Passage], entries: [JournalEntry]) {
        let defaults = UserDefaults.standard
        let prefix = "qb.p.\(id.uuidString)"
        defaults.set(bookId, forKey: "\(prefix).book")
        defaults.set(chapter, forKey: "\(prefix).chapter")
        let items = bookmarks.map { StoredPassage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse) }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: "\(prefix).bookmarks")
        }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: "\(prefix).journal")
        }
    }

    func hasNote(verse: Int) -> Bool {
        familyOn(bookId: bookId, chapter: chapter, verse: verse).isEmpty == false
    }

    private func refreshFamilyJournal() {
        familyJournal = profiles.flatMap { profile in
            let items = profile.id == profileId ? entries : Self.readProfileBundle(id: profile.id).entries
            return items.map { FamilyNote(profile: profile, entry: $0) }
        }
    }

    func datedReference(bookId: String, chapter: Int, verse: Int? = nil, verseEnd: Int? = nil, on date: Date = Date()) -> String {
        let when = date.formatted(date: .abbreviated, time: .omitted)
        return "\(placeLabel(bookId: bookId, chapter: chapter, verse: verse, verseEnd: verseEnd)) · \(when)"
    }

    func placeLabel(bookId: String, chapter: Int, verse: Int? = nil, verseEnd: Int? = nil) -> String {
        let name = book(id: bookId)?.name ?? bookId
        if let verse {
            let end = verseEnd ?? verse
            if end != verse {
                return "\(name) \(chapter):\(verse)–\(end)"
            }
            return "\(name) \(chapter):\(verse)"
        }
        return "\(name) \(chapter)"
    }

    func bookmarkLabel(_ passage: Passage) -> String {
        placeLabel(bookId: passage.bookId, chapter: passage.chapter, verse: passage.verse)
    }

    private func clampChapter() {
        guard let book = currentBook else { return }
        chapter = min(max(1, chapter), book.chapterCount)
    }

    private func persistPlace() {
        guard ready else { return }
        UserDefaults.standard.set(bookId, forKey: "qb.book")
        UserDefaults.standard.set(chapter, forKey: "qb.chapter")
        UserDefaults.standard.set(bookId, forKey: "qb.p.\(profileId.uuidString).book")
        UserDefaults.standard.set(chapter, forKey: "qb.p.\(profileId.uuidString).chapter")
    }

    private func persistJournal() {
        guard ready else { return }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "qb.journal")
            UserDefaults.standard.set(data, forKey: "qb.p.\(profileId.uuidString).journal")
        }
    }

    private func persistBookmarks() {
        guard ready else { return }
        let items = bookmarks.map { StoredPassage(translation: $0.translation, bookId: $0.bookId, chapter: $0.chapter, verse: $0.verse) }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "qb.bookmarks")
            UserDefaults.standard.set(data, forKey: "qb.p.\(profileId.uuidString).bookmarks")
        }
    }
}

struct FamilyNote: Identifiable, Equatable {
    var id: String { "\(profile.id.uuidString)-\(entry.id.uuidString)" }
    var profile: BibleProfile
    var entry: JournalEntry
}

enum JournalKind: String, Codable, CaseIterable, Identifiable {
    case note
    case comment
    case devotion
    case prayer
    case answered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note: return "Notes"
        case .comment: return "Comments"
        case .devotion: return "Devotions"
        case .prayer: return "Prayer requests"
        case .answered: return "Answered"
        }
    }

    var singular: String {
        switch self {
        case .note: return "Note"
        case .comment: return "Comment"
        case .devotion: return "Devotion"
        case .prayer: return "Prayer request"
        case .answered: return "Answered prayer"
        }
    }

    var symbol: String {
        switch self {
        case .note: return "square.and.pencil"
        case .comment: return "text.bubble"
        case .devotion: return "sun.max"
        case .prayer: return "heart"
        case .answered: return "checkmark.seal"
        }
    }

    var blurb: String {
        switch self {
        case .note: return "Thoughts, and pictures, from a chapter or a day."
        case .comment: return "A human word on a verse. It shows on the page under that person’s name."
        case .devotion: return "Write a short devotion, then come back and read it."
        case .prayer: return "What you are asking for."
        case .answered: return "Prayers you have seen through."
        }
    }
}

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: JournalKind
    var title: String
    var body: String
    var created: Date
    var updated: Date
    var bookId: String?
    var chapter: Int?
    var verse: Int?
    var verseEnd: Int?
    var photoIds: [String]
    var prayerLine: String
    var sitWith: String

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, created, updated, bookId, chapter, verse, verseEnd, photoIds, prayerLine, sitWith
    }

    init(
        id: UUID,
        kind: JournalKind,
        title: String,
        body: String,
        created: Date,
        updated: Date,
        bookId: String? = nil,
        chapter: Int? = nil,
        verse: Int? = nil,
        verseEnd: Int? = nil,
        photoIds: [String] = [],
        prayerLine: String = "",
        sitWith: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.created = created
        self.updated = updated
        self.bookId = bookId
        self.chapter = chapter
        self.verse = verse
        self.verseEnd = verseEnd
        self.photoIds = photoIds
        self.prayerLine = prayerLine
        self.sitWith = sitWith
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(JournalKind.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decode(String.self, forKey: .body)
        created = try c.decode(Date.self, forKey: .created)
        updated = try c.decode(Date.self, forKey: .updated)
        bookId = try c.decodeIfPresent(String.self, forKey: .bookId)
        chapter = try c.decodeIfPresent(Int.self, forKey: .chapter)
        verse = try c.decodeIfPresent(Int.self, forKey: .verse)
        verseEnd = try c.decodeIfPresent(Int.self, forKey: .verseEnd)
        photoIds = try c.decodeIfPresent([String].self, forKey: .photoIds) ?? []
        prayerLine = try c.decodeIfPresent(String.self, forKey: .prayerLine) ?? ""
        sitWith = try c.decodeIfPresent(String.self, forKey: .sitWith) ?? ""
    }

    func covers(verse n: Int) -> Bool {
        guard let start = verse else { return false }
        let end = verseEnd ?? start
        return n >= min(start, end) && n <= max(start, end)
    }

    static func blank(_ kind: JournalKind, bookId: String? = nil, chapter: Int? = nil, verse: Int? = nil, verseEnd: Int? = nil) -> JournalEntry {
        JournalEntry(
            id: UUID(),
            kind: kind,
            title: "",
            body: "",
            created: Date(),
            updated: Date(),
            bookId: bookId,
            chapter: chapter,
            verse: verse,
            verseEnd: verseEnd
        )
    }
}

struct StoredPassage: Codable {
    var translation: String
    var bookId: String
    var chapter: Int
    var verse: Int?
}
