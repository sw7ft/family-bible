import SwiftUI
import UIKit

struct BibleMap: Identifiable, Hashable {
    let id: String
    let title: String
    let blurb: String
}

struct MapAssignment {
    let mapId: String
    let bookId: String
    let chapters: Set<Int>

    init(_ mapId: String, _ bookId: String, _ range: ClosedRange<Int>) {
        self.mapId = mapId
        self.bookId = bookId
        self.chapters = Set(range)
    }

    init(_ mapId: String, _ bookId: String, _ chapters: [Int]) {
        self.mapId = mapId
        self.bookId = bookId
        self.chapters = Set(chapters)
    }
}

enum BibleMaps {
    static let all: [BibleMap] = [
        BibleMap(id: "egypt", title: "Egyptian Empire", blurb: "Egypt and Canaan, about 1450 BC."),
        BibleMap(id: "before", title: "Before Israel", blurb: "Palestine before the coming of Israel."),
        BibleMap(id: "judges", title: "Settlement and Judges", blurb: "The land in the days of the Judges."),
        BibleMap(id: "saul", title: "Saul", blurb: "Israel under the first king."),
        BibleMap(id: "david", title: "David and Solomon", blurb: "Palestine under the united kingdom."),
        BibleMap(id: "elijah", title: "Elijah and Elisha", blurb: "The northern kingdom in the days of the prophets."),
        BibleMap(id: "exile", title: "To the exile", blurb: "From 720 BC to the exile of Judah."),
        BibleMap(id: "babylon", title: "Babylonian Empire", blurb: "The world of the exile, about 560 BC."),
        BibleMap(id: "persians", title: "Under the Persians", blurb: "Palestine in the Persian period."),
        BibleMap(id: "persia", title: "Persian Empire", blurb: "The wider empire, about 525 BC."),
        BibleMap(id: "alexander", title: "Alexander", blurb: "The Greek world, about 325 BC."),
        BibleMap(id: "asia", title: "Western Asia", blurb: "The wider world in the 4th–2nd centuries BC."),
        BibleMap(id: "maccabees", title: "The Maccabees", blurb: "Palestine in the Maccabean period."),
        BibleMap(id: "pompey", title: "After Pompey", blurb: "The land after Rome’s first settlement."),
        BibleMap(id: "herod", title: "Herod the Great", blurb: "Palestine under Herod."),
        BibleMap(id: "christ", title: "The time of Christ", blurb: "Palestine under Herod’s will."),
        BibleMap(id: "procurators", title: "Roman procurators", blurb: "The land in the time of the Gospels and Acts."),
        BibleMap(id: "agrippa1", title: "Agrippa I", blurb: "Palestine in the days of Acts 12."),
        BibleMap(id: "agrippa2", title: "Agrippa II", blurb: "The land before the fall of Jerusalem."),
        BibleMap(id: "paul", title: "Paul’s travels", blurb: "The journeys of the apostle."),
        BibleMap(id: "churches", title: "Seven churches", blurb: "Asia Minor in the Revelation to John."),
        BibleMap(id: "church", title: "The early church", blurb: "How the gospel spread."),
        BibleMap(id: "rome", title: "Roman Empire", blurb: "The world of the early church."),
        BibleMap(id: "jerusalem", title: "Jerusalem, 1915", blurb: "The city as drawn for the atlas.")
    ]

    static let assignments: [MapAssignment] = [
        MapAssignment("before", "genesis", 10...36),
        MapAssignment("egypt", "genesis", 12...13),
        MapAssignment("egypt", "genesis", 37...50),
        MapAssignment("egypt", "exodus", 1...40),
        MapAssignment("egypt", "leviticus", 1...27),
        MapAssignment("egypt", "numbers", 1...36),
        MapAssignment("judges", "numbers", 13...14),
        MapAssignment("judges", "numbers", 21...36),
        MapAssignment("egypt", "deuteronomy", 1...34),
        MapAssignment("judges", "deuteronomy", 1...34),
        MapAssignment("judges", "joshua", 1...24),
        MapAssignment("judges", "judges", 1...21),
        MapAssignment("judges", "ruth", 1...4),
        MapAssignment("judges", "1samuel", 1...8),
        MapAssignment("saul", "1samuel", 9...31),
        MapAssignment("david", "1samuel", 16...31),
        MapAssignment("david", "2samuel", 1...24),
        MapAssignment("jerusalem", "2samuel", 5...7),
        MapAssignment("david", "1kings", 1...11),
        MapAssignment("jerusalem", "1kings", 5...8),
        MapAssignment("elijah", "1kings", 12...22),
        MapAssignment("elijah", "2kings", 1...16),
        MapAssignment("exile", "2kings", 15...25),
        MapAssignment("babylon", "2kings", 24...25),
        MapAssignment("david", "1chronicles", 10...29),
        MapAssignment("jerusalem", "1chronicles", 11...16),
        MapAssignment("jerusalem", "1chronicles", 21...29),
        MapAssignment("david", "2chronicles", 1...9),
        MapAssignment("jerusalem", "2chronicles", 2...7),
        MapAssignment("elijah", "2chronicles", 17...24),
        MapAssignment("exile", "2chronicles", 28...36),
        MapAssignment("babylon", "2chronicles", 36...36),
        MapAssignment("persians", "ezra", 1...10),
        MapAssignment("persia", "ezra", 1...10),
        MapAssignment("jerusalem", "ezra", 1...6),
        MapAssignment("persians", "nehemiah", 1...13),
        MapAssignment("persia", "nehemiah", 1...2),
        MapAssignment("jerusalem", "nehemiah", 1...7),
        MapAssignment("jerusalem", "nehemiah", 11...13),
        MapAssignment("persia", "esther", 1...10),
        MapAssignment("jerusalem", "psalms", [2, 9, 15, 24, 46, 48, 51, 76, 79, 84, 87, 102, 122, 125, 128, 132, 147]),
        MapAssignment("babylon", "psalms", [137]),
        MapAssignment("jerusalem", "isaiah", 1...12),
        MapAssignment("exile", "isaiah", 7...10),
        MapAssignment("babylon", "isaiah", 13...14),
        MapAssignment("egypt", "isaiah", 19...20),
        MapAssignment("jerusalem", "isaiah", 22...22),
        MapAssignment("exile", "isaiah", 20...20),
        MapAssignment("jerusalem", "isaiah", 28...33),
        MapAssignment("exile", "isaiah", 36...39),
        MapAssignment("babylon", "isaiah", 39...39),
        MapAssignment("persia", "isaiah", 41...45),
        MapAssignment("babylon", "isaiah", 47...48),
        MapAssignment("jerusalem", "isaiah", 52...52),
        MapAssignment("jerusalem", "isaiah", 60...62),
        MapAssignment("exile", "jeremiah", 1...52),
        MapAssignment("jerusalem", "jeremiah", 1...7),
        MapAssignment("babylon", "jeremiah", 20...29),
        MapAssignment("jerusalem", "jeremiah", 26...26),
        MapAssignment("jerusalem", "jeremiah", 32...39),
        MapAssignment("babylon", "jeremiah", 39...44),
        MapAssignment("babylon", "jeremiah", 50...52),
        MapAssignment("exile", "lamentations", 1...5),
        MapAssignment("jerusalem", "lamentations", 1...5),
        MapAssignment("babylon", "ezekiel", 1...48),
        MapAssignment("jerusalem", "ezekiel", 8...11),
        MapAssignment("jerusalem", "ezekiel", 40...48),
        MapAssignment("babylon", "daniel", 1...7),
        MapAssignment("persia", "daniel", 5...6),
        MapAssignment("persia", "daniel", 9...10),
        MapAssignment("alexander", "daniel", [2, 7, 8, 11]),
        MapAssignment("asia", "daniel", [8, 11]),
        MapAssignment("maccabees", "daniel", [8, 11]),
        MapAssignment("elijah", "hosea", 1...14),
        MapAssignment("jerusalem", "joel", 2...3),
        MapAssignment("elijah", "amos", 1...9),
        MapAssignment("judges", "obadiah", 1...1),
        MapAssignment("babylon", "jonah", 1...4),
        MapAssignment("jerusalem", "micah", [1, 3, 4, 5]),
        MapAssignment("exile", "micah", 1...1),
        MapAssignment("babylon", "nahum", 1...3),
        MapAssignment("babylon", "habakkuk", 1...3),
        MapAssignment("jerusalem", "zephaniah", 1...3),
        MapAssignment("exile", "zephaniah", 1...1),
        MapAssignment("persians", "haggai", 1...2),
        MapAssignment("jerusalem", "haggai", 1...2),
        MapAssignment("persians", "zechariah", 1...14),
        MapAssignment("jerusalem", "zechariah", 1...8),
        MapAssignment("jerusalem", "zechariah", 12...14),
        MapAssignment("persians", "malachi", 1...4),
        MapAssignment("pompey", "matthew", 1...2),
        MapAssignment("herod", "matthew", [2, 14]),
        MapAssignment("christ", "matthew", 1...28),
        MapAssignment("jerusalem", "matthew", 21...25),
        MapAssignment("procurators", "matthew", 27...28),
        MapAssignment("christ", "mark", 1...16),
        MapAssignment("herod", "mark", 6...6),
        MapAssignment("jerusalem", "mark", 11...13),
        MapAssignment("procurators", "mark", 15...16),
        MapAssignment("herod", "luke", [1, 2, 3, 9, 13, 23]),
        MapAssignment("christ", "luke", 1...24),
        MapAssignment("jerusalem", "luke", [2, 13, 19, 20, 21, 22, 23, 24]),
        MapAssignment("procurators", "luke", 23...24),
        MapAssignment("christ", "john", 1...21),
        MapAssignment("jerusalem", "john", [2, 5, 7, 8, 9, 10, 12, 13, 14, 18, 19]),
        MapAssignment("procurators", "john", 18...19),
        MapAssignment("church", "acts", 1...28),
        MapAssignment("jerusalem", "acts", [1, 2, 3, 4, 5, 6, 7, 8, 15, 21]),
        MapAssignment("paul", "acts", 9...28),
        MapAssignment("agrippa1", "acts", 12...12),
        MapAssignment("churches", "acts", 19...20),
        MapAssignment("rome", "acts", [18, 19, 21, 22, 23, 24, 25, 26, 27, 28]),
        MapAssignment("agrippa2", "acts", 25...26),
        MapAssignment("rome", "romans", 1...16),
        MapAssignment("paul", "romans", 1...16),
        MapAssignment("paul", "1corinthians", 1...16),
        MapAssignment("rome", "1corinthians", 16...16),
        MapAssignment("paul", "2corinthians", 1...13),
        MapAssignment("paul", "galatians", 1...6),
        MapAssignment("paul", "ephesians", 1...6),
        MapAssignment("churches", "ephesians", 1...6),
        MapAssignment("paul", "philippians", 1...4),
        MapAssignment("rome", "philippians", 1...4),
        MapAssignment("paul", "colossians", 1...4),
        MapAssignment("churches", "colossians", 1...4),
        MapAssignment("paul", "1thessalonians", 1...5),
        MapAssignment("paul", "2thessalonians", 1...3),
        MapAssignment("paul", "1timothy", 1...6),
        MapAssignment("paul", "2timothy", 1...4),
        MapAssignment("rome", "2timothy", 1...4),
        MapAssignment("paul", "titus", 1...3),
        MapAssignment("paul", "philemon", 1...1),
        MapAssignment("jerusalem", "hebrews", 7...10),
        MapAssignment("rome", "1peter", 1...5),
        MapAssignment("churches", "revelation", 1...3),
        MapAssignment("rome", "revelation", 13...18)
    ]

    static func forChapter(bookId: String, chapter: Int) -> [BibleMap] {
        let ids = assignments
            .filter { $0.bookId == bookId && $0.chapters.contains(chapter) }
            .map(\.mapId)
        var seen = Set<String>()
        return all.filter { ids.contains($0.id) && seen.insert($0.id).inserted }
    }

    static func hasMap(bookId: String, chapter: Int) -> Bool {
        assignments.contains { $0.bookId == bookId && $0.chapters.contains(chapter) }
    }
}

struct MapsView: View {
    @EnvironmentObject private var store: ReadingStore

    var body: some View {
        List {
            Section {
                Text("George Adam Smith’s 1915 Atlas of the Historical Geography of the Holy Land. Public domain in the United States.")
                    .font(QuietFont.small(13))
                    .foregroundStyle(store.theme.mute)
            }
            ForEach(BibleMaps.all) { item in
                NavigationLink {
                    MapPage(item: item)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(QuietFont.display(20))
                            .foregroundStyle(store.theme.ink)
                        Text(item.blurb)
                            .font(QuietFont.small(13))
                            .foregroundStyle(store.theme.mute)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(store.theme.page)
        .navigationTitle("Maps")
        .navigationBarTitleDisplayMode(.inline)
        .quietBar()
    }
}

struct MapPage: View {
    @EnvironmentObject private var store: ReadingStore
    let item: BibleMap
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                ZoomableImage(image: image)
            } else {
                Text("This map is missing from the bundle.")
                    .font(QuietFont.body(16))
                    .foregroundStyle(store.theme.mute)
                    .padding()
            }
        }
        .background(store.theme.page)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .quietBar()
        .onAppear {
            if image == nil {
                image = loadMap()
            }
        }
    }

    private func loadMap() -> UIImage? {
        guard let url = Bundle.main.url(forResource: item.id, withExtension: "jpg"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct ChapterMapSheet: View {
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss
    let maps: [BibleMap]
    let heading: String

    var body: some View {
        NavigationStack {
            Group {
                if maps.count == 1, let only = maps.first {
                    MapPage(item: only)
                } else {
                    List {
                        Section {
                            Text(heading)
                                .font(QuietFont.small(13))
                                .foregroundStyle(store.theme.mute)
                        }
                        ForEach(maps) { item in
                            NavigationLink {
                                MapPage(item: item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(QuietFont.display(20))
                                        .foregroundStyle(store.theme.ink)
                                    Text(item.blurb)
                                        .font(QuietFont.small(13))
                                        .foregroundStyle(store.theme.mute)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(store.theme.page)
                    .navigationTitle("Maps")
                    .navigationBarTitleDisplayMode(.inline)
                    .quietBar()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}
