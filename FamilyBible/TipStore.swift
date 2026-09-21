import Foundation
import StoreKit

struct TipOffer: Identifiable {
    let id: String
    let name: String
    let fallbackPrice: String
}

@MainActor
final class TipStore: ObservableObject {
    static let offers: [TipOffer] = [
        TipOffer(id: "com.sw7ft.quietbible.tip.small", name: "Thank you", fallbackPrice: "$0.99"),
        TipOffer(id: "com.sw7ft.quietbible.tip.medium", name: "A coffee", fallbackPrice: "$2.99"),
        TipOffer(id: "com.sw7ft.quietbible.tip.large", name: "A meal", fallbackPrice: "$4.99")
    ]

    @Published private(set) var products: [Product] = []
    @Published var status = ""
    @Published var busy = false

    init() {
        Task { await load() }
        Task { await listen() }
    }

    func product(for offer: TipOffer) -> Product? {
        products.first { $0.id == offer.id }
    }

    func price(for offer: TipOffer) -> String {
        product(for: offer)?.displayPrice ?? offer.fallbackPrice
    }

    func buy(_ offer: TipOffer) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        if products.isEmpty {
            await load()
        }
        guard let product = product(for: offer) else {
            status = "Apple has to list this tip before a purchase can go through."
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checked(verification)
                await transaction.finish()
                status = "Thank you."
            case .userCancelled:
                status = ""
            case .pending:
                status = "Waiting on Apple."
            @unknown default:
                status = ""
            }
        } catch {
            status = error.localizedDescription
        }
    }

    func load() async {
        do {
            let found = try await Product.products(for: Set(Self.offers.map(\.id)))
            products = found.sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    private func listen() async {
        for await update in Transaction.updates {
            if let transaction = try? checked(update) {
                await transaction.finish()
            }
        }
    }

    private func checked<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipError.unverified
        case .verified(let value):
            return value
        }
    }
}

private enum TipError: LocalizedError {
    case unverified

    var errorDescription: String? {
        "Apple could not verify that purchase."
    }
}
