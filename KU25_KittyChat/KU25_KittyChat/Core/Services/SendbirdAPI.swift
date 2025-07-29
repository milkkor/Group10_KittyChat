import Foundation

// MARK: - Sendbird Configuration
// Centralized configuration for all Sendbird services
// TODO: Replace with actual credentials for production

struct SendbirdAPI {
    // Application ID used for SendbirdUI initialization and API calls
    // TODO: For GitHub upload safety, using placeholder
    // Contact Liao YUJU for actual credentials
    static let appId = "YOUR_SENDBIRD_APP_ID_HERE"
    
    // Production App ID (uncomment and replace when deploying):
    // static let appId = "your-actual-sendbird-app-id"
    
    // API Token for server-side API calls
    // TODO: For GitHub upload safety, using placeholder
    // Contact Liao YUJU for actual credentials
    static let apiToken = "YOUR_SENDBIRD_API_TOKEN_HERE"
    
    // Production API Token (uncomment and replace when deploying):
    // static let apiToken = "your-actual-sendbird-api-token"
    
    // Alternative: Load from environment variables
    // static let appId = ProcessInfo.processInfo.environment["SENDBIRD_APP_ID"] ?? ""
    // static let apiToken = ProcessInfo.processInfo.environment["SENDBIRD_API_TOKEN"] ?? ""

    /// 檢查 userId 是否存在於 Sendbird
    static func checkUserExists(userId: String, completion: @escaping (Bool) -> Void) {
        // Use centralized appId for URL construction
        guard let url = URL(string: "https://api-\(appId).sendbird.com/v3/users/\(userId)") else {
            print("SendbirdAPI.checkUserExists: URL 產生失敗")
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiToken, forHTTPHeaderField: "Api-Token")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("SendbirdAPI.checkUserExists statusCode:", httpResponse.statusCode)
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("SendbirdAPI.checkUserExists response body:", body)
                }
                completion(httpResponse.statusCode == 200)
            } else {
                print("SendbirdAPI.checkUserExists: no valid HTTPURLResponse")
                completion(false)
            }
        }
        task.resume()
    }
} 
