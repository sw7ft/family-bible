import Foundation

struct Translation: Identifiable, Hashable {
    let id: String
    let label: String
    let notice: String
    let books: [Book]
}

struct Book: Identifiable, Hashable {
    let id: String
    let name: String
    let testament: String
    let chapters: [[String]]

    var chapterCount: Int { chapters.count }

    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Passage: Hashable {
    var translation: String
    var bookId: String
    var chapter: Int
    var verse: Int?

    var label: String { "\(bookId) \(chapter)" }
}

enum BibleLibrary {
    static let translationIds = ["webu", "bbe", "kjv"]

    static func load(_ id: String) -> Translation {
        guard let url = Bundle.main.url(forResource: id, withExtension: "json") else {
            return Translation(id: id, label: id.uppercased(), notice: "", books: [])
        }
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode(RawTranslation.self, from: data)
            return Translation(
                id: raw.id,
                label: raw.label,
                notice: raw.notice,
                books: raw.books.map {
                    Book(id: $0.id, name: $0.name, testament: $0.testament, chapters: $0.chapters)
                }
            )
        } catch {
            return Translation(id: id, label: id.uppercased(), notice: error.localizedDescription, books: [])
        }
    }

    private struct RawTranslation: Decodable {
        let id: String
        let label: String
        let notice: String
        let books: [RawBook]
    }

    private struct RawBook: Decodable {
        let id: String
        let name: String
        let testament: String
        let chapters: [[String]]
    }
}
