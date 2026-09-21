import SwiftUI
import UniformTypeIdentifiers

enum FamilyPackError: LocalizedError {
    case unsupported
    case unreadable

    var errorDescription: String? {
        switch self {
        case .unsupported: return "This file is from a newer Family Bible."
        case .unreadable: return "That file is not a Family Bible export."
        }
    }
}

struct FamilyPackFile: Codable {
    var format: Int
    var app: String
    var exported: Date
    var profileId: UUID
    var profiles: [FamilyPersonFile]
    var photos: [String: String]
}

struct FamilyPersonFile: Codable {
    var id: UUID
    var name: String
    var bookId: String
    var chapter: Int
    var bookmarks: [StoredPassage]
    var entries: [JournalEntry]
}

struct FamilyBibleDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw FamilyPackError.unreadable
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
