import Foundation

struct VerseRef: Equatable {
    let book: Book
    let chapter: Int
    let verse: Int?
    var heading: String {
        if let verse {
            return "\(book.name) \(chapter):\(verse)"
        }
        return "\(book.name) \(chapter)"
    }
}

enum ScriptureLookup {
    static func parse(_ raw: String, books: [Book]) -> VerseRef? {
        var text = raw.lowercased()
        text = text.replacingOccurrences(of: ",", with: " ")
        text = text.replacingOccurrences(of: ";", with: " ")
        text = text.replacingOccurrences(of: ".", with: "")
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let numbered = #"^(1st|2nd|3rd|first|second|third|iii|ii|i|3|2|1)\s+([a-z]+)\s+(\d+)(?:\s*[:\s]\s*(\d+))?$"#
        if let match = first(numbered, in: text) {
            let prefix = normalizeNumber(match[1])
            if let book = resolve("\(prefix)\(match[2])", books: books)
                ?? resolve("\(prefix) \(match[2])", books: books) {
                return clamped(book, match[3], match.count > 4 ? match[4] : nil)
            }
        }

        let plain = #"^([a-z]+)(?:\s+(\d+)(?:\s*[:\s]\s*(\d+))?)?$"#
        if let match = first(plain, in: text) {
            guard let book = resolve(match[1], books: books) else { return nil }
            if match.count > 2, !match[2].isEmpty {
                return clamped(book, match[2], match.count > 3 ? match[3] : nil)
            }
            return VerseRef(book: book, chapter: 1, verse: nil)
        }

        let jammedVerse = #"^([a-z]+)(\d+):(\d+)$"#
        if let match = first(jammedVerse, in: text), let book = resolve(match[1], books: books) {
            return clamped(book, match[2], match[3])
        }
        let jammedChapter = #"^([a-z]+)(\d+)$"#
        if let match = first(jammedChapter, in: text), let book = resolve(match[1], books: books) {
            return clamped(book, match[2], nil)
        }
        return nil
    }

    static func resolve(_ token: String, books: [Book]) -> Book? {
        let key = token.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ".", with: "")
        if let id = aliases[key] {
            return books.first { $0.id == id }
        }
        if let exact = books.first(where: { $0.id == key || compact($0.name) == key }) {
            return exact
        }
        guard key.count >= 3 else { return nil }
        let prefix = books.filter { $0.id.hasPrefix(key) || compact($0.name).hasPrefix(key) }
        return prefix.count == 1 ? prefix[0] : nil
    }

    private static func clamped(_ book: Book, _ chapterText: String, _ verseText: String?) -> VerseRef? {
        guard let chapter = Int(chapterText), chapter >= 1, chapter <= book.chapterCount else { return nil }
        let verses = book.chapters[chapter - 1]
        var verse: Int?
        if let verseText, let value = Int(verseText), value >= 1 {
            verse = min(value, verses.count)
        }
        return VerseRef(book: book, chapter: chapter, verse: verse)
    }

    private static func compact(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func normalizeNumber(_ raw: String) -> String {
        switch raw {
        case "i", "1st", "first": return "1"
        case "ii", "2nd", "second": return "2"
        case "iii", "3rd", "third": return "3"
        default: return raw
        }
    }

    private static func first(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        var parts: [String] = []
        for index in 0..<match.numberOfRanges {
            guard let loop = Range(match.range(at: index), in: text) else {
                parts.append("")
                continue
            }
            parts.append(String(text[loop]))
        }
        return parts
    }

    private static let aliases: [String: String] = [
        "gen": "genesis", "gn": "genesis", "ge": "genesis",
        "ex": "exodus", "exo": "exodus", "exod": "exodus",
        "lev": "leviticus", "le": "leviticus", "lv": "leviticus",
        "num": "numbers", "nu": "numbers", "nm": "numbers", "nb": "numbers",
        "deut": "deuteronomy", "dt": "deuteronomy", "de": "deuteronomy",
        "josh": "joshua", "jos": "joshua",
        "judg": "judges", "jdg": "judges", "jdgs": "judges",
        "ru": "ruth",
        "1sam": "1samuel", "1sa": "1samuel", "1sm": "1samuel",
        "2sam": "2samuel", "2sa": "2samuel", "2sm": "2samuel",
        "1kgs": "1kings", "1ki": "1kings", "1king": "1kings",
        "2kgs": "2kings", "2ki": "2kings", "2king": "2kings",
        "1chr": "1chronicles", "1ch": "1chronicles",
        "2chr": "2chronicles", "2ch": "2chronicles",
        "ezr": "ezra",
        "neh": "nehemiah", "ne": "nehemiah",
        "est": "esther", "es": "esther",
        "job": "job", "jb": "job",
        "ps": "psalms", "psa": "psalms", "psalm": "psalms", "pss": "psalms",
        "prov": "proverbs", "prv": "proverbs", "pr": "proverbs",
        "eccl": "ecclesiastes", "ecc": "ecclesiastes", "ec": "ecclesiastes",
        "song": "songofsolomon", "sos": "songofsolomon",
        "ss": "songofsolomon", "cant": "songofsolomon",
        "isa": "isaiah",
        "jer": "jeremiah", "je": "jeremiah",
        "lam": "lamentations", "la": "lamentations",
        "ezek": "ezekiel", "eze": "ezekiel", "ezk": "ezekiel",
        "dan": "daniel", "da": "daniel", "dn": "daniel",
        "hos": "hosea", "ho": "hosea",
        "joel": "joel", "jl": "joel",
        "amos": "amos",
        "obad": "obadiah", "ob": "obadiah",
        "jon": "jonah", "jnh": "jonah",
        "mic": "micah",
        "nah": "nahum", "na": "nahum",
        "hab": "habakkuk",
        "zeph": "zephaniah", "zep": "zephaniah",
        "hag": "haggai",
        "zech": "zechariah", "zec": "zechariah",
        "mal": "malachi",
        "mt": "matthew", "matt": "matthew", "mat": "matthew",
        "mk": "mark", "mrk": "mark", "mar": "mark",
        "lk": "luke", "luk": "luke", "lu": "luke",
        "jn": "john", "joh": "john", "jhn": "john",
        "act": "acts", "ac": "acts",
        "rom": "romans", "ro": "romans", "rm": "romans",
        "1cor": "1corinthians", "1co": "1corinthians",
        "2cor": "2corinthians", "2co": "2corinthians",
        "gal": "galatians", "ga": "galatians",
        "eph": "ephesians",
        "phil": "philippians", "php": "philippians", "phpil": "philippians",
        "col": "colossians",
        "1thess": "1thessalonians", "1th": "1thessalonians", "1thes": "1thessalonians",
        "2thess": "2thessalonians", "2th": "2thessalonians", "2thes": "2thessalonians",
        "1tim": "1timothy", "1ti": "1timothy",
        "2tim": "2timothy", "2ti": "2timothy",
        "tit": "titus",
        "phlm": "philemon", "phm": "philemon",
        "heb": "hebrews",
        "jas": "james", "jam": "james", "jm": "james",
        "1pet": "1peter", "1pe": "1peter", "1pt": "1peter",
        "2pet": "2peter", "2pe": "2peter", "2pt": "2peter",
        "1jn": "1john", "1jhn": "1john", "1j": "1john",
        "2jn": "2john", "2jhn": "2john",
        "3jn": "3john", "3jhn": "3john",
        "jud": "jude",
        "rev": "revelation", "re": "revelation", "rv": "revelation", "apoc": "revelation",
    ]
}
