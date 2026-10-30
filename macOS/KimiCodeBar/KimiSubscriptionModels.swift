import Foundation

struct KimiWebCredential: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let userId: String?
    var authorizedAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case authorizedAt = "authorized_at"
    }
}

struct KimiMonthlyBreakdown: Equatable {
    let kimiPercentage: Int
    let codePercentage: Int
}

enum KimiMonthlyQuotaCalculator {
    static func breakdown(totalRatio: Double, codeRatio: Double?) -> KimiMonthlyBreakdown? {
        guard let codeRatio else { return nil }
        return KimiMonthlyBreakdown(
            kimiPercentage: percentage(max(0, totalRatio - codeRatio)),
            codePercentage: percentage(codeRatio)
        )
    }

    private static func percentage(_ ratio: Double) -> Int {
        max(0, min(100, Int((ratio * 100).rounded())))
    }
}
