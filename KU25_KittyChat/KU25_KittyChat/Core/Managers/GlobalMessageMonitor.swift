import Foundation
import SendbirdChatSDK
import SendbirdUIKit
import UIKit

// Protocol for handling receiver responses from active chat view controllers
protocol ReceiverResponseHandler: AnyObject {
    func recordReceiverResponse(_ response: ReceiverResponse, interactionId: String)
}

/// Global message monitor using SendbirdChat.addChannelDelegate for comprehensive message monitoring
class GlobalMessageMonitor: NSObject, BaseChannelDelegate, GroupChannelDelegate {
    
    static let shared = GlobalMessageMonitor()
    
    // Protocol for handling receiver responses in active chat view controllers
    weak var receiverResponseHandler: ReceiverResponseHandler?
    
    // Store the last received message context for webhook scenarios
    private var lastReceivedMessageContext: AIMessageContext?
    
    private override init() {
        super.init()
    }
    
    /// Register the global message monitor
    func registerMonitor() {
        SendbirdChat.addChannelDelegate(self, identifier: "global-ai-guardian-monitor")
        print("[DEBUG] 🌍 Global AI Guardian message monitor registered")
        print("[DEBUG] 🔍 Current user: \(SBUGlobals.currentUser?.userId ?? "nil")")
        print("[DEBUG] 🔍 SendbirdChat user: \(SendbirdChat.getCurrentUser()?.userId ?? "nil")")
    }
    
    /// Unregister the global message monitor
    func unregisterMonitor() {
        SendbirdChat.removeChannelDelegate(forIdentifier: "global-ai-guardian-monitor")
        print("[DEBUG] 🌍 Global AI Guardian message monitor unregistered")
    }
    
    /// Set the active receiver response handler
    func setReceiverResponseHandler(_ handler: ReceiverResponseHandler) {
        self.receiverResponseHandler = handler
        print("[DEBUG] 🔗 Global Monitor: Receiver response handler set")
    }
    
    /// Clear the receiver response handler
    func clearReceiverResponseHandler() {
        self.receiverResponseHandler = nil
        print("[DEBUG] 🔗 Global Monitor: Receiver response handler cleared")
    }
    
    // MARK: - BaseChannelDelegate
    
    func channel(_ channel: BaseChannel, didReceive message: BaseMessage) {
        print("[DEBUG] 🔥 GlobalMessageMonitor (BaseChannel): didReceive called!")
        handleIncomingMessage(message: message, channel: channel)
    }
    
    // MARK: - GroupChannelDelegate  
    
    func channel(_ channel: GroupChannel, didReceive message: BaseMessage) {
        print("[DEBUG] 🔥 GlobalMessageMonitor (GroupChannel): didReceive called!")
        handleIncomingMessage(message: message, channel: channel)
    }
    
    // MARK: - Shared Message Handler
    
    private func handleIncomingMessage(message: BaseMessage, channel: BaseChannel) {
        print("[DEBUG] 📝 Message type: \(type(of: message))")
        print("[DEBUG] 📝 Message ID: \(message.messageId)")
        print("[DEBUG] 📝 Message content: '\(message.message)'")
        print("[DEBUG] 📝 Channel URL: \(channel.channelURL)")
        print("[DEBUG] 📝 Current user: \(SBUGlobals.currentUser?.userId ?? "nil")")
        
        guard let userMessage = message as? UserMessage else {
            print("[DEBUG] ⚠️ Message is not UserMessage, ignoring")
            return
        }
        
        guard let currentUser = SBUGlobals.currentUser else {
            print("[DEBUG] ❌ No current user available")
            return
        }
        
        print("[DEBUG] 📥 Global Monitor: Received message in \(channel.channelURL)")
        print("[DEBUG] 📝 Sender: \(userMessage.sender?.userId ?? "unknown")")
        print("[DEBUG] 📝 CustomType: '\(userMessage.customType ?? "nil")'")
        
        // Create AI message context using the new router system
        let context = AIMessageContext(message: userMessage, currentUserId: currentUser.userId)
        
        // Store context for potential webhook scenarios
        self.lastReceivedMessageContext = context
        
        // Route message using the centralized router
        let action = AIMessageRouter.shared.routeMessage(context: context, channel: channel)
        
        // Execute the action
        executeAction(action)
    }
    
    // MARK: - Additional BaseChannelDelegate Methods
    
    func channel(_ channel: BaseChannel, didUpdate message: BaseMessage) {
        print("[DEBUG] 🔄 GlobalMessageMonitor: didUpdate message")
    }
    
    func channel(_ channel: BaseChannel, didDelete messageId: Int64) {
        print("[DEBUG] 🗑️ GlobalMessageMonitor: didDelete message")
    }
    
    func channel(_ channel: BaseChannel, userDidJoin user: User) {
        print("[DEBUG] 👋 GlobalMessageMonitor: user joined - \(user.userId)")
    }
    
    func channel(_ channel: BaseChannel, userDidLeave user: User) {
        print("[DEBUG] 👋 GlobalMessageMonitor: user left - \(user.userId)")
    }
    
    // MARK: - Action Execution
    
    private func executeAction(_ action: AIMessageAction) {
        print("[DEBUG] 🎬 Global Monitor: Executing action: \(action.description)")
        
        switch action {
        case .showReceiverAlert(let context, let channel):
            handleReceiverAlert(context: context, channel: channel)
            
        case .showGeminiReceiverAlert(let context, let channel):
            handleGeminiReceiverAlert(context: context, channel: channel)
            
        case .ignore:
            print("[DEBUG] ℹ️ Global Monitor: Action ignored")
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleReceiverAlert(context: AIMessageContext, channel: BaseChannel) {
        guard let interactionId = context.interactionId else {
            print("[DEBUG] ❌ Global: No interaction ID found in flagged message")
            return
        }
        
        print("[DEBUG] 🎯 Global: Showing receiver action sheet for interaction: \(interactionId)")
        
        DispatchQueue.main.async {
            guard let topViewController = AIMessageRouter.shared.getTopViewController() else {
                print("[DEBUG] ❌ Global: No top view controller found")
                return
            }
            
            // Use BiDirectionalInteractionManager for consistent behavior
            let interactionManager = BiDirectionalInteractionManager(presentingViewController: topViewController)
            interactionManager.handleReceivedFlaggedMessage(
                interactionId: interactionId,
                message: context.message.message
            )
        }
    }
    
    private func handleGeminiReceiverAlert(context: AIMessageContext, channel: BaseChannel) {
        print("[DEBUG] 🤖 Global: Showing Gemini receiver action sheet")
        
        // Extract Gemini analysis data from message
        var geminiAnalysis: [String: Any] = [:]
        if let data = context.message.data.data(using: .utf8),
           let messageData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let analysis = messageData["gemini_analysis"] as? [String: Any] {
            geminiAnalysis = analysis
        }
        
        DispatchQueue.main.async {
            guard let topViewController = AIMessageRouter.shared.getTopViewController() else {
                print("[DEBUG] ❌ Global: No top view controller found")
                return
            }
            
            // Use BiDirectionalInteractionManager for consistent Gemini behavior
            let interactionManager = BiDirectionalInteractionManager(presentingViewController: topViewController)
            interactionManager.handleReceivedGeminiFlaggedMessage(
                interactionId: context.interactionId ?? UUID().uuidString,
                message: context.message.message,
                geminiAnalysis: geminiAnalysis
            )
        }
    }
    
    // MARK: - UI Presentation
    
    private func presentReceiverActionSheet(on viewController: UIViewController, context: AIMessageContext, interactionId: String) {
        let router = AIMessageRouter.shared
        
        let alertController = UIAlertController(
            title: router.localizedText(for: "ai_guardian_title"),
            message: "\(router.localizedText(for: "ai_guardian_message"))\n\nMessage: \"\(context.message.message)\"",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_acceptable"), style: .default) { [weak self] _ in
            print("[DEBUG] 👍 Global: Receiver chose acceptable")
            self?.sendReceiverResponse(.acceptable, interactionId: interactionId)
        })
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_uncomfortable"), style: .default) { [weak self] _ in
            print("[DEBUG] 😐 Global: Receiver chose uncomfortable")
            self?.sendReceiverResponse(.uncomfortable, interactionId: interactionId)
        })
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_exit"), style: .destructive) { [weak self] _ in
            print("[DEBUG] 🚪 Global: Receiver chose exit")
            self?.sendReceiverResponse(.exit, interactionId: interactionId)
        })
        
        viewController.present(alertController, animated: true) {
            print("[DEBUG] ✅ Global: Receiver action sheet presented successfully!")
        }
    }
    
    private func sendReceiverResponse(_ response: ReceiverResponse, interactionId: String) {
        print("[DEBUG] 📤 Global: Recording response '\(response.rawValue)' for interaction \(interactionId)")
        
        // Always use webhook for cross-device scenarios when we have message context
        if let lastContext = self.lastReceivedMessageContext {
            print("[DEBUG] 📝 Global: Recording via webhook for cross-device interaction")
            
            StrikeManager.shared.processCrossDeviceInteractionWithContext(
                interactionId: interactionId,
                senderId: lastContext.senderId,
                response: response
            ) { finalStrikes, limitReached in
                DispatchQueue.main.async {
                    print("[DEBUG] 🎯 Webhook: Recorded response - \(finalStrikes) strikes, limit reached: \(limitReached)")
                    
                    // Handle consequences without sending messages
                    if limitReached {
                        print("[DEBUG] 🎓 Webhook: Strike limit reached - education recommended")
                    } else if response == .exit {
                        print("[DEBUG] 🚪 Webhook: User chose to exit conversation")
                    }
                }
            }
        } else {
            print("[DEBUG] ❌ Global: No message context available for webhook")
            
            // Fallback to old handler method for local scenarios
            if let handler = receiverResponseHandler {
                print("[DEBUG] ✅ Global: Delegating to active receiver response handler as fallback")
                handler.recordReceiverResponse(response, interactionId: interactionId)
            }
        }
        
        print("[DEBUG] ✅ Global: Response recorded silently - no messages sent to chat")
    }
} 