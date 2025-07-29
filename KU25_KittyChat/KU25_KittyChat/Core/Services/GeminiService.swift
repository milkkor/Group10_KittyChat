import Foundation

// MARK: - Gemini API Response Models

struct GeminiResult {
    let shouldFlag: Bool
    let reason: String
    let severity: DetectionSeverity
    let suggestion: String
    
    init(shouldFlag: Bool, reason: String, severity: String, suggestion: String = "") {
        self.shouldFlag = shouldFlag
        self.reason = reason
        self.severity = DetectionSeverity.fromString(severity)
        self.suggestion = suggestion.isEmpty ? GeminiResult.generateSuggestion(for: reason, severity: severity) : suggestion
    }
    
    private static func generateSuggestion(for reason: String, severity: String) -> String {
        switch severity.lowercased() {
        case "high":
            return "This message contains highly inappropriate content. Please reconsider your words."
        case "medium":
            return "This message may be hurtful to others. Consider rephrasing."
        case "low":
            return "This message might be interpreted negatively. Please be mindful."
        default:
            return "Please consider if this message might be hurtful to others."
        }
    }
}

// MARK: - Gemini API Service

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    private init() {
        // ⚠️ IMPORTANT: Replace with your actual Gemini API key
        // TODO: For GitHub upload safety, using placeholder
        // Contact YUJU for the API key or set up environment variables
        self.apiKey = "YOUR_GEMINI_API_KEY_HERE"
        
        // Production API Key (uncomment and replace when deploying):
        // self.apiKey = "your-actual-gemini-api-key"
        
        // Alternative: Load from environment variable
        // self.apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    }
    
    /// Analyze message content using Gemini API
    /// - Parameter message: The message to analyze
    /// - Returns: GeminiResult with analysis outcome
    func analyzeMessageViaGemini(_ message: String) async throws -> GeminiResult {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw GeminiError.invalidAPIKey
        }
        
        print("[DEBUG] 🔍 Gemini: Using API Key: \(String(apiKey.prefix(10)))...")
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        print("[DEBUG] 🔍 Gemini: Request URL: \(baseURL)?key=\(String(apiKey.prefix(10)))...")
        
        let prompt = """
        Analyze this chat message for offensive, belittling, misogynistic, or inappropriate content.
        
        Message: "\(message)"
        
        Return a JSON response with the following structure:
        {
            "shouldFlag": boolean,
            "reason": "string describing the issue",
            "severity": "low/medium/high",
            "suggestion": "helpful suggestion for the user"
        }
        
        Guidelines:
        - shouldFlag: true if the message contains problematic content
        - reason: specific description of the issue (e.g., "misogynistic", "belittling", "offensive")
        - severity: "low" for mild concerns, "medium" for inappropriate content, "high" for highly offensive
        - suggestion: constructive advice for the user
        
        Focus on detecting:
        - Gender discrimination or misogyny
        - Belittling or condescending language
        - Stereotypes about groups of people
        - Offensive or hostile language
        - Content that could make others uncomfortable
        
        Return only the JSON response, no additional text.
        """
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topK": 1,
                "topP": 0.8,
                "maxOutputTokens": 500
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[DEBUG] 🔍 Gemini: Analyzing message: '\(message)'")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("[DEBUG] 🔍 Gemini: HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[DEBUG] ❌ Gemini API Error: \(errorText)")
            throw GeminiError.apiError(httpResponse.statusCode, errorText)
        }
        
        // Parse Gemini response
        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates.first,
              let text = candidate.content.parts.first?.text else {
            throw GeminiError.noContentGenerated
        }
        
        print("[DEBUG] 🔍 Gemini: Raw response: \(text)")
        
        // Extract JSON from Gemini response
        let jsonString = extractJSONFromText(text)
        print("[DEBUG] 🔍 Gemini: Extracted JSON: \(jsonString)")
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidJSONFormat
        }
        
        let result = try JSONDecoder().decode(GeminiResult.self, from: jsonData)
        print("[DEBUG] ✅ Gemini: Analysis complete - shouldFlag: \(result.shouldFlag), severity: \(result.severity)")
        
        return result
    }
    
    /// Extract JSON string from Gemini's text response
    private func extractJSONFromText(_ text: String) -> String {
        // Look for JSON object in the response
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        // Fallback: return the entire text if no JSON brackets found
        return text
    }
    
    /// Call Gemini API with custom prompt and return raw text response
    /// Used by ThreadsAnalysisService for profile analysis
    /// - Parameter prompt: Custom prompt for analysis
    /// - Returns: Raw text response from Gemini
    func callGeminiAPI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw GeminiError.invalidAPIKey
        }
        
        print("[DEBUG] 🤖 GeminiService: Making custom API call")
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "topK": 40,
                "topP": 0.8,
                "maxOutputTokens": 2048
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[DEBUG] 🤖 GeminiService: Calling API with custom prompt...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[DEBUG] ❌ GeminiService: Invalid HTTP response")
            throw GeminiError.invalidResponse
        }
        
        print("[DEBUG] 🤖 GeminiService: API Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[DEBUG] ❌ GeminiService: API Error (\(httpResponse.statusCode)): \(errorText)")
            throw GeminiError.apiError(httpResponse.statusCode, errorText)
        }
        
        print("[DEBUG] 🤖 GeminiService: Parsing response...")
        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates.first,
              let text = candidate.content.parts.first?.text else {
            print("[DEBUG] ❌ GeminiService: No content in response")
            throw GeminiError.noContentGenerated
        }
        
        print("[DEBUG] 🤖 GeminiService: Response received (\(text.count) characters)")
        return text
    }
}

// MARK: - Gemini API Response Models

struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

// MARK: - Gemini Errors

enum GeminiError: Error, LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case apiError(Int, String)
    case noContentGenerated
    case invalidJSONFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid Gemini API key. Please contact YUJU for the correct API key."
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let code, let message):
            return "Gemini API error (\(code)): \(message)"
        case .noContentGenerated:
            return "No content generated by Gemini API"
        case .invalidJSONFormat:
            return "Invalid JSON format in Gemini response"
        }
    }
}

// MARK: - DetectionSeverity Extension

extension DetectionSeverity {
    static func fromString(_ severity: String) -> DetectionSeverity {
        switch severity.lowercased() {
        case "high":
            return .high
        case "medium":
            return .medium
        case "low":
            return .low
        default:
            return .low
        }
    }
}

// MARK: - Codable Conformance for GeminiResult

extension GeminiResult: Codable {
    enum CodingKeys: String, CodingKey {
        case shouldFlag
        case reason
        case severity
        case suggestion
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shouldFlag = try container.decode(Bool.self, forKey: .shouldFlag)
        reason = try container.decode(String.self, forKey: .reason)
        let severityString = try container.decode(String.self, forKey: .severity)
        severity = DetectionSeverity.fromString(severityString)
        suggestion = try container.decodeIfPresent(String.self, forKey: .suggestion) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shouldFlag, forKey: .shouldFlag)
        try container.encode(reason, forKey: .reason)
        try container.encode(severity.rawValue, forKey: .severity)
        try container.encode(suggestion, forKey: .suggestion)
    }
} 
