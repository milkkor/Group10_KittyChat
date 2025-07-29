import Foundation

/// WebhookEndpointURL manages the webhook endpoint URL configuration
class WebhookEndpointURL {
    
    /// Get webhook endpoint URL
    /// - Returns: The current webhook endpoint URL
    static func getWebhookURL() -> String {
        // You can move this to a configuration file or make it configurable
        return "<URL>"
    }
    
    /// Set webhook endpoint URL
    /// - Parameter url: The new webhook endpoint URL
    static func setWebhookURL(_ url: String) {
        // TODO: Implement URL storage (UserDefaults, configuration file, etc.)
        // For now, this is a placeholder for future implementation
        print("[DEBUG] WebhookEndpointURL: Setting new URL: \(url)")
    }
    
    /// Validate webhook endpoint URL format
    /// - Parameter url: The URL to validate
    /// - Returns: True if the URL is valid, false otherwise
    static func isValidURL(_ url: String) -> Bool {
        guard let url = URL(string: url) else {
            return false
        }
        return url.scheme == "https" || url.scheme == "http"
    }
    
    /// Get webhook endpoint URL with validation
    /// - Returns: The current webhook endpoint URL if valid, nil otherwise
    static func getValidWebhookURL() -> String? {
        let url = getWebhookURL()
        return isValidURL(url) ? url : nil
    }
}
