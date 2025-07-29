import Foundation
import SendbirdChatSDK
import UIKit

// MARK: - AI Message Types

enum AIMessageType: String, CaseIterable {
    case flaggedMessage = "flagged_message"
    case geminiFlaggedMessage = "gemini_flagged_message"
    case receiverResponse = "receiver_response"
    case regular = "regular"
    
    init(from rawValue: String?) {
        self = AIMessageType(rawValue: rawValue ?? "") ?? .regular
    }
    
    var description: String {
        switch self {
        case .flaggedMessage: return "Flagged Message"
        case .geminiFlaggedMessage: return "Gemini Flagged Message"
        case .receiverResponse: return "Receiver Response"
        case .regular: return "Regular Message"
        }
    }
}

// MARK: - Message Role

enum AIMessageRole {
    case sender      // I sent this message
    case receiver    // Someone else sent this message to me
    case selfResponse // I sent a response message (should be ignored)
    
    var description: String {
        switch self {
        case .sender: return "Sender"
        case .receiver: return "Receiver"
        case .selfResponse: return "Self Response"
        }
    }
}

// MARK: - AI Message Context

struct AIMessageContext {
    let message: UserMessage
    let type: AIMessageType
    let role: AIMessageRole
    let interactionId: String?
    let senderId: String
    let currentUserId: String
    
    init(message: UserMessage, currentUserId: String) {
        self.message = message
        self.currentUserId = currentUserId
        self.senderId = message.sender?.userId ?? "unknown"
        self.type = AIMessageType(from: message.customType)
        
        // Determine role based on sender
        let isSender = (self.senderId == currentUserId)
        
        switch self.type {
        case .flaggedMessage:
            self.role = isSender ? .sender : .receiver
        case .geminiFlaggedMessage:
            self.role = isSender ? .sender : .receiver
        case .receiverResponse:
            self.role = isSender ? .selfResponse : .receiver
        case .regular:
            self.role = isSender ? .sender : .receiver
        }
        
        // Extract interaction ID from message data
        if let data = message.data.data(using: .utf8),
           let messageData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = messageData["interaction_id"] as? String {
            self.interactionId = id
        } else {
            self.interactionId = nil
        }
    }
    
    var debugDescription: String {
        return """
        AIMessageContext:
          - Type: \(type.description)
          - Role: \(role.description)  
          - InteractionID: \(interactionId ?? "nil")
          - Sender: \(senderId)
          - Current User: \(currentUserId)
          - Message: '\(message.message)'
        """
    }
}

// MARK: - AI Message Router

class AIMessageRouter {
    
    static let shared = AIMessageRouter()
    
    private init() {}
    
    /// Route AI Guardian messages based on context
    func routeMessage(context: AIMessageContext, channel: BaseChannel) -> AIMessageAction {
        print("[DEBUG] 🧭 AIMessageRouter: Routing message")
        print("[DEBUG] \(context.debugDescription)")
        
        switch (context.type, context.role) {
        
        case (.flaggedMessage, .receiver):
            print("[DEBUG] 🚨 Router: Receiver should see flagged message alert")
            return .showReceiverAlert(context: context, channel: channel)
            
        case (.geminiFlaggedMessage, .receiver):
            print("[DEBUG] 🤖 Router: Receiver should see Gemini flagged message alert")
            return .showGeminiReceiverAlert(context: context, channel: channel)
            
        case (.receiverResponse, .sender):
            print("[DEBUG] ℹ️ Router: Receiver response messages no longer used - responses recorded silently")
            return .ignore
            
        case (.receiverResponse, .receiver):
            print("[DEBUG] ℹ️ Router: Receiver response messages no longer used - responses recorded silently")
            return .ignore
            
        case (.receiverResponse, .selfResponse):
            print("[DEBUG] ℹ️ Router: Receiver response messages no longer used - responses recorded silently")
            return .ignore
            
        case (.flaggedMessage, .sender), (.geminiFlaggedMessage, .sender):
            print("[DEBUG] 🔄 Router: Sender's own flagged message (usually handled before sending)")
            return .ignore
            
        case (.regular, .sender):
            print("[DEBUG] ✅ Router: Regular message, no action needed")
            return .ignore
            
        case (.regular, .receiver):
            print("[DEBUG] ✅ Router: Regular message, no action needed")
            return .ignore
            
        case (.regular, .selfResponse):
            print("[DEBUG] ✅ Router: Regular message, no action needed")
            return .ignore
            
        case (.flaggedMessage, .selfResponse), (.geminiFlaggedMessage, .selfResponse):
            print("[DEBUG] ⚠️ Router: Unexpected case - flagged message marked as self response")
            return .ignore
        }
    }
}

// MARK: - AI Message Actions

enum AIMessageAction {
    case showReceiverAlert(context: AIMessageContext, channel: BaseChannel)
    case showGeminiReceiverAlert(context: AIMessageContext, channel: BaseChannel)
    case ignore
    
    var description: String {
        switch self {
        case .showReceiverAlert: return "Show Receiver Alert"
        case .showGeminiReceiverAlert: return "Show Gemini Receiver Alert"
        case .ignore: return "Ignore"
        }
    }
}

// MARK: - UI Helper Extensions

extension AIMessageRouter {
    
    /// Get the topmost view controller for presenting alerts
    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topViewController = keyWindow.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
}

// MARK: - Localization Support (Future Enhancement)

extension AIMessageRouter {
    
    /// Get localized text for AI Guardian messages
    func localizedText(for key: String) -> String {
        // TODO: Implement localization
        switch key {
        case "ai_guardian_title": return "⚠️ AI Guardian Alert"
        case "ai_guardian_message": return "A message has been flagged by AI Guardian. How do you feel about this interaction?"
        case "response_acceptable": return "Acceptable"
        case "response_uncomfortable": return "Uncomfortable but continue"
        case "response_exit": return "Exit now"
        default: return key
        }
    }
} 
