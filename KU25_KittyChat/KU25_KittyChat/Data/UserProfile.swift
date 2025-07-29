import Foundation

struct UserProfile: Codable {
    var userId: String // Made mutable for cache updates
    let threadsHandle: String
    let interests: [String]
    let personality: String
    let misogynyRisk: String
    var strikes: Int
    
    enum CodingKeys: String, CodingKey {
        case userId, threadsHandle, interests, personality, strikes
        case misogynyRisk = "misogyny_risk"
    }
} 