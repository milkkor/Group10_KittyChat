import UIKit
import SendbirdUIKit
import SwiftUI
import SendbirdChatSDK

/// Simplified KittyChatChannelViewController that focuses only on sender-side AI Guardian logic
/// Receiver-side logic is handled by GlobalMessageMonitor with AIMessageRouter
class KittyChatChannelViewController: SBUGroupChannelViewController {
    
    private lazy var interactionManager: BiDirectionalInteractionManager = {
        let manager = BiDirectionalInteractionManager(presentingViewController: self)
        manager.delegate = self
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationItem()
        print("[DEBUG] 📱 KittyChatChannelViewController: Entered chat room, current userId:", SendbirdChat.getCurrentUser()?.userId ?? "nil")
        
        // Test DetectionEngine initialization
        self.testDetectionEngine()
        
        // Register this controller as a receiver response handler for active channel
        GlobalMessageMonitor.shared.setReceiverResponseHandler(self)
        
        print("[DEBUG] ✅ KittyChatChannelViewController: Now uses GlobalMessageMonitor for message interception")
        print("[DEBUG] ✅ KittyChatChannelViewController: Focused on sender-side logic only")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear receiver response handler when leaving the chat
        GlobalMessageMonitor.shared.clearReceiverResponseHandler()
        print("[DEBUG] 🔗 KittyChatChannelViewController: Receiver response handler cleared")
    }
    
    private func testDetectionEngine() {
        print("[DEBUG] 🧪 Testing DetectionEngine...")
        
        // Test a known keyword
        let testMessage = "calm down"
        if let result = DetectionEngine.shared.analyzeMessage(testMessage) {
            print("[DEBUG] ✅ Detection working! Found: \(result.rule.keyword) -> \(result.rule.type)")
        } else {
            print("[DEBUG] ❌ Detection failed for test message: '\(testMessage)'")
        }
        
        // Test bundle resource
        if let url = Bundle.main.url(forResource: "DetectionRules", withExtension: "json") {
            print("[DEBUG] ✅ DetectionRules.json found at: \(url.path)")
        } else {
            print("[DEBUG] ❌ DetectionRules.json NOT found in bundle!")
        }
    }
    
    // MARK: - Sender-side Message Handling
    
    override func baseChannelModule(
        _ inputComponent: SBUBaseChannelModule.Input,
        didTapSend text: String,
        parentMessage: BaseMessage?
    ) {
        print("[DEBUG] 🚀 KittyChatChannelViewController: didTapSend called!")
        print("[DEBUG] 📝 Input text: '\(text)'")
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { 
            print("[DEBUG] ⚠️ Empty text, returning")
            return 
        }
        
        print("[DEBUG] 🔍 Analyzing message from userId:", SendbirdChat.getCurrentUser()?.userId ?? "nil")
        print("[DEBUG] 📝 Message content: '\(trimmedText)'")
        
        // Use Gemini API for AI-powered message analysis
        Task {
            do {
                let geminiResult = try await GeminiService.shared.analyzeMessageViaGemini(trimmedText)
                
                DispatchQueue.main.async {
                    if geminiResult.shouldFlag {
                        print("[DEBUG] ⚠️ Gemini flagged message! Severity: \(geminiResult.severity.description)")
                        self.handleGeminiFlaggedMessage(
                            message: trimmedText,
                            geminiResult: geminiResult,
                            parentMessage: parentMessage
                        )
        } else {
                        print("[DEBUG] ✅ Gemini: Message is safe, sending normally")
            // Message is safe, send normally
            super.baseChannelModule(inputComponent, didTapSend: text, parentMessage: parentMessage)
                    }
                }
            } catch {
                print("[DEBUG] ❌ Gemini analysis error: \(error)")
                DispatchQueue.main.async {
                    // Fallback to local detection if Gemini fails
                    if let detectionResult = DetectionEngine.shared.analyzeMessage(trimmedText) {
                        print("[DEBUG] ⚠️ Fallback: Local detection flagged message!")
                        self.handleFlaggedMessage(originalMessage: trimmedText, detectionResult: detectionResult, parentMessage: parentMessage)
                    } else {
                        print("[DEBUG] ✅ Fallback: Local detection passed, sending normally")
                        super.baseChannelModule(inputComponent, didTapSend: text, parentMessage: parentMessage)
                    }
                }
            }
        }
    }
    
    /// Handle flagged message using the interaction manager (sender-side only)
    private func handleFlaggedMessage(originalMessage: String, detectionResult: DetectionResult, parentMessage: BaseMessage?) {
        guard let currentUser = SBUGlobals.currentUser,
              let channel = self.channel,
              let receiverUserId = channel.members.first(where: { $0.userId != currentUser.userId })?.userId else {
            print("[DEBUG] ❌ Could not determine receiver for interaction")
            return
        }
        
        print("[DEBUG] 🎭 Delegating to interaction manager for sender-side handling")
        
        // Delegate to interaction manager
        interactionManager.handleFlaggedMessage(
            originalMessage: originalMessage,
            detectionResult: detectionResult,
            senderId: currentUser.userId,
            receiverId: receiverUserId,
            parentMessage: parentMessage
        )
    }
    
    /// Handle Gemini-flagged message with simplified flow
    private func handleGeminiFlaggedMessage(message: String, geminiResult: GeminiResult, parentMessage: BaseMessage?) {
        print("[DEBUG] 🤖 Gemini: Handling flagged message with severity: \(geminiResult.severity)")
        
        guard let currentUser = SBUGlobals.currentUser,
              let channel = self.channel,
              let receiverUserId = channel.members.first(where: { $0.userId != currentUser.userId })?.userId else {
            print("[DEBUG] ❌ Could not determine receiver for Gemini interaction")
            return
        }
        
        // Prepare Gemini analysis data
        let geminiAnalysis: [String: Any] = [
                "shouldFlag": geminiResult.shouldFlag,
                "reason": geminiResult.reason,
                "severity": geminiResult.severity.rawValue,
            "suggestion": geminiResult.suggestion,
            "flagged_content": message,
            "flagged_reason": geminiResult.reason
        ]
        
        print("[DEBUG] 🤖 Delegating to interaction manager for Gemini sender-side handling")
        
        // Delegate to interaction manager for Gemini
        interactionManager.handleGeminiFlaggedMessage(
            originalMessage: message,
            geminiAnalysis: geminiAnalysis,
            senderId: currentUser.userId,
            receiverId: receiverUserId,
            parentMessage: parentMessage
        )
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationItem() {
        // Navigation setup - summary functionality removed
    }

    

}

// MARK: - ReceiverResponseHandler

extension KittyChatChannelViewController: ReceiverResponseHandler {
    
    func recordReceiverResponse(_ response: ReceiverResponse, interactionId: String) {
        print("[DEBUG] 📝 KittyChatChannelViewController: Recording receiver response '\(response.rawValue)' for interaction \(interactionId)")
        
        // Record the response directly without sending any chat messages
        StrikeManager.shared.recordReceiverResponse(interactionId: interactionId, response: response) { [weak self] finalStrikes, limitReached in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("[DEBUG] 🎯 KittyChatChannelViewController: Response recorded - \(finalStrikes) strikes, limit reached: \(limitReached)")
                
                // Handle consequences silently
                if limitReached {
                    print("[DEBUG] ⚠️ KittyChatChannelViewController: Strike limit reached - education module disabled")
                    // Education module has been removed
                } else if response == .exit {
                    print("[DEBUG] 🚪 KittyChatChannelViewController: User chose to exit")
                    self.showConversationExitAlert()
                }
            }
        }
        
        print("[DEBUG] ✅ KittyChatChannelViewController: Receiver response recorded silently")
    }
    
    private func showConversationExitAlert() {
        let alert = UIAlertController(
            title: "Conversation Ended",
            message: "You have chosen to exit this conversation due to inappropriate content.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Could navigate back or handle conversation exit
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - BiDirectionalInteractionDelegate

extension KittyChatChannelViewController: BiDirectionalInteractionDelegate {
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didSendMessage message: String, parentMessage: BaseMessage?) {
        print("[DEBUG] 📤 Sender: Sending flagged message with native Sendbird approach")
        print("[DEBUG] Message: '\(message)'")
        print("[DEBUG] Interaction ID: \(manager.getCurrentInteractionId() ?? "nil")")
        
        // Send flagged message using customType
        let messageParams = UserMessageCreateParams(message: message)
        messageParams.customType = "flagged_message"
        
        let flaggedData: [String: Any] = [
            "interaction_id": manager.getCurrentInteractionId() ?? UUID().uuidString,
            "flagged_type": "interaction_pending",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("[DEBUG] Flagged data to attach: \(flaggedData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: flaggedData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            messageParams.data = jsonString
            print("[DEBUG] ✅ Flagged message data attached: \(jsonString ?? "nil")")
        } catch {
            print("[DEBUG] ❌ Error serializing flagged data: \(error)")
        }

        print("[DEBUG] Sending flagged message via viewModel...")
        self.viewModel?.sendUserMessage(messageParams: messageParams, parentMessage: parentMessage)
        print("[DEBUG] ✅ Flagged message sent with customType 'flagged_message'")
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didSendGeminiMessage message: String, geminiAnalysis: String, parentMessage: BaseMessage?) {
        print("[DEBUG] 🤖 Sender: Sending Gemini flagged message")
        print("[DEBUG] Message: '\(message)'")
        print("[DEBUG] Interaction ID: \(manager.getCurrentInteractionId() ?? "nil")")
        
        // Send Gemini flagged message using customType
        let messageParams = UserMessageCreateParams(message: message)
        messageParams.customType = "gemini_flagged_message"
        
        // Parse Gemini analysis back to dictionary
        var geminiAnalysisDict: [String: Any] = [:]
        if let data = geminiAnalysis.data(using: .utf8),
           let analysis = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            geminiAnalysisDict = analysis
        }
        
        let flaggedData: [String: Any] = [
            "interaction_id": manager.getCurrentInteractionId() ?? UUID().uuidString,
            "gemini_analysis": geminiAnalysisDict,
            "flagged_type": "gemini_interaction_pending",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("[DEBUG] Gemini flagged data to attach: \(flaggedData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: flaggedData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            messageParams.data = jsonString
            print("[DEBUG] ✅ Gemini flagged message data attached: \(jsonString ?? "nil")")
        } catch {
            print("[DEBUG] ❌ Error serializing Gemini flagged data: \(error)")
        }

        print("[DEBUG] Sending Gemini flagged message via viewModel...")
        self.viewModel?.sendUserMessage(messageParams: messageParams, parentMessage: parentMessage)
        print("[DEBUG] ✅ Gemini flagged message sent with customType 'gemini_flagged_message'")
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didCompleteInteractionWithStrikes strikes: Double, limitReached: Bool) {
        // Handle strike completion - already shown by manager
        print("Interaction completed with \(strikes) strikes, limit reached: \(limitReached)")
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestEducationModule completion: @escaping () -> Void) {
        // Show education recommendation and navigate to education tab
        let alert = UIAlertController(
            title: "🎓 Education Recommended",
            message: "We recommend checking out our education modules to improve your communication skills and understand how AI Guardian works.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Go to Education", style: .default) { _ in
            // Navigate to education tab (tab index 2)
            if let tabBarController = self.tabBarController {
                tabBarController.selectedIndex = 2
            }
            completion()
        })
        
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel) { _ in
        completion()
        })
        
        present(alert, animated: true)
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestConversationExit reason: String) {
        let alert = UIAlertController(
            title: "Conversation Ended",
            message: reason,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didShowMessage title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Auto dismiss informational messages after 3 seconds (except strike limit alerts)
        if !title.contains("Strike Limit") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didClearMessageInput: Void) {
        messageInputView?.textView?.text = ""
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRestoreMessageInput message: String) {
        messageInputView?.textView?.text = message
    }
    
}

 
