import Foundation

// Detection rule structure matching JSON
struct DetectionRule: Codable {
    let keyword: String
    let type: String
    
    // Severity levels for different rule types
    var severity: DetectionSeverity {
        switch type.lowercased() {
        case "offensive": return .high
        case "belittling": return .medium
        case "stereotype": return .low
        default: return .low
        }
    }
}

// Severity levels for flagged content
enum DetectionSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    
    var description: String {
        switch self {
        case .low: return "Mild concern"
        case .medium: return "Inappropriate content" 
        case .high: return "Highly offensive"
        }
    }
    
    var strikeCount: Int {
        return self.rawValue
    }
}

// Sender's response options
enum SenderResponse: String, CaseIterable {
    case retract = "retract"
    case edit = "edit"
    case justJoking = "just_joking"
    
    var displayText: String {
        switch self {
        case .retract: return "Retract Message"
        case .edit: return "Edit Message"
        case .justJoking: return "Just Joking"
        }
    }
}

// Receiver's response options
enum ReceiverResponse: String, CaseIterable {
    case acceptable = "acceptable"
    case uncomfortable = "uncomfortable"
    case exit = "exit"
    
    var displayText: String {
        switch self {
        case .acceptable: return "Acceptable"
        case .uncomfortable: return "Uncomfortable but continue"
        case .exit: return "Exit now"
        }
    }
}

// Interaction result for strike calculation
struct InteractionResult {
    let senderResponse: SenderResponse
    let receiverResponse: ReceiverResponse
    let strikes: Double
    
    init(senderResponse: SenderResponse, receiverResponse: ReceiverResponse) {
        self.senderResponse = senderResponse
        self.receiverResponse = receiverResponse
        self.strikes = InteractionResult.calculateStrikes(sender: senderResponse, receiver: receiverResponse)
    }
    
    private static func calculateStrikes(sender: SenderResponse, receiver: ReceiverResponse) -> Double {
        switch (sender, receiver) {
        // Just joking responses - only these will actually trigger receiver interaction
        case (.justJoking, .acceptable): return 0.5
        case (.justJoking, .uncomfortable): return 1.0
        case (.justJoking, .exit): return 2.0
            
        // Edit responses - these should not reach this point in normal flow
        // but included for completeness if somehow invoked
        case (.edit, .acceptable): return 0.0
        case (.edit, .uncomfortable): return 0.0
        case (.edit, .exit): return 0.0
            
        // Retract responses - these should not reach this point in normal flow
        // but included for completeness if somehow invoked
        case (.retract, .acceptable): return 0.0
        case (.retract, .uncomfortable): return 0.0
        case (.retract, .exit): return 0.0
        }
    }
    
    var description: String {
        return "Sender: \(senderResponse.displayText), Receiver: \(receiverResponse.displayText) → \(strikes) strikes"
    }
}

// Detection result with additional context
struct DetectionResult {
    let rule: DetectionRule
    let matchedText: String
    let severity: DetectionSeverity
    let suggestion: String
    
    init(rule: DetectionRule, matchedText: String) {
        self.rule = rule
        self.matchedText = matchedText
        self.severity = rule.severity
        self.suggestion = DetectionResult.generateSuggestion(for: rule)
    }
    
    private static func generateSuggestion(for rule: DetectionRule) -> String {
        switch rule.type.lowercased() {
        case "offensive":
            return "Consider expressing your thoughts in a more respectful way."
        case "belittling":
            return "Try rephrasing this to show respect for others' capabilities."
        case "stereotype":
            return "Consider avoiding generalizations about groups of people."
        default:
            return "Please consider if this message might be hurtful to others."
        }
    }
}

class DetectionEngine {
    static let shared = DetectionEngine()
    
    private var rules: [DetectionRule] = []
    
    private init() {
        loadRules()
    }
    
    private func loadRules() {
        print("[DEBUG] Starting to load detection rules...")
        
        guard let url = Bundle.main.url(forResource: "DetectionRules", withExtension: "json") else {
            print("[ERROR] Could not find DetectionRules.json in bundle. Bundle path: \(Bundle.main.bundlePath)")
            return
        }
        
        print("[DEBUG] Found DetectionRules.json at: \(url.path)")
        
        do {
            let data = try Data(contentsOf: url)
            print("[DEBUG] Read \(data.count) bytes from DetectionRules.json")
            
            self.rules = try JSONDecoder().decode([DetectionRule].self, from: data)
            print("[SUCCESS] Successfully loaded \(rules.count) detection rules.")
            
            // Print first few rules for verification
            for (index, rule) in rules.prefix(5).enumerated() {
                print("[DEBUG] Rule \(index + 1): '\(rule.keyword)' -> \(rule.type)")
            }
        } catch {
            print("[ERROR] Failed to load or decode detection rules: \(error)")
        }
    }
    
    /// Enhanced message checking with detailed results
    /// - Parameter message: The message content to analyze
    /// - Returns: DetectionResult if flagged, nil if safe
    func analyzeMessage(_ message: String) -> DetectionResult? {
        print("[DEBUG] Analyzing message: '\(message)'")
        print("[DEBUG] Available rules count: \(rules.count)")
        
        let lowercasedMessage = message.lowercased()
        print("[DEBUG] Lowercased message: '\(lowercasedMessage)'")
        
        // Find the most severe rule that matches
        var detectedRules: [(rule: DetectionRule, range: Range<String.Index>)] = []
        
        for rule in rules {
            let keyword = rule.keyword.lowercased()
            if let range = lowercasedMessage.range(of: keyword) {
                print("[DEBUG] MATCH FOUND! Keyword: '\(keyword)' in message")
                detectedRules.append((rule: rule, range: range))
            }
        }
        
        if detectedRules.isEmpty {
            print("[DEBUG] No matches found in message")
            return nil
        }
        
        // Return the most severe detection
        if let mostSevere = detectedRules.max(by: { $0.rule.severity.rawValue < $1.rule.severity.rawValue }) {
            let originalMessage = message
            let matchedText = String(originalMessage[mostSevere.range])
            
            let result = DetectionResult(rule: mostSevere.rule, matchedText: matchedText)
            print("[DETECTION] Message flagged: \(result.severity.description) - \(result.rule.type)")
            return result
        }
        
        return nil
    }
    
    /// Legacy method for backward compatibility
    func check(message: String) -> DetectionRule? {
        return analyzeMessage(message)?.rule
    }
    
    /// Get statistics about detection rules
    func getRuleStatistics() -> [String: Int] {
        let typeGroups = Dictionary(grouping: rules, by: { $0.type })
        return typeGroups.mapValues { $0.count }
    }
} 