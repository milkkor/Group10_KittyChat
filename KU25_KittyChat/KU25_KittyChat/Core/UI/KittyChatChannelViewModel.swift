import Foundation
import SendbirdUIKit
import SendbirdChatSDK

/// Custom ViewModel to filter out silent feedback messages from the UI
class KittyChatChannelViewModel: SBUGroupChannelViewModel {
    
    /// Override to filter out silent feedback messages when receiving new messages
    override func channel(_ channel: BaseChannel, didReceive message: BaseMessage) {
        // Filter out silent feedback messages
        if let userMessage = message as? UserMessage,
           userMessage.customType == "receiver_response_silent" {
            print("[DEBUG] 🚫 ViewModel Filter: Blocking silent feedback message from UI")
            // Don't call super, effectively hiding the message from UI
            return
        }
        
        // Process normal messages
        super.channel(channel, didReceive: message)
    }
    
    /// Override to filter out silent feedback messages when loading message collection
    override func messageCollection(_ collection: MessageCollection, context: MessageContext, channel: GroupChannel, addedMessages messages: [BaseMessage]) {
        // Filter out silent feedback messages from added messages
        let filteredMessages = messages.filter { message in
            if let userMessage = message as? UserMessage,
               userMessage.customType == "receiver_response_silent" {
                print("[DEBUG] 🚫 ViewModel Filter: Blocking silent feedback message from message collection")
                return false
            }
            return true
        }
        
        // Only call super if there are filtered messages to process
        if !filteredMessages.isEmpty {
            super.messageCollection(collection, context: context, channel: channel, addedMessages: filteredMessages)
        }
    }
    
    /// Override to filter out silent feedback messages when updating message collection
    override func messageCollection(_ collection: MessageCollection, context: MessageContext, channel: GroupChannel, updatedMessages messages: [BaseMessage]) {
        // Filter out silent feedback messages from updated messages
        let filteredMessages = messages.filter { message in
            if let userMessage = message as? UserMessage,
               userMessage.customType == "receiver_response_silent" {
                print("[DEBUG] 🚫 ViewModel Filter: Blocking silent feedback message from updated messages")
                return false
            }
            return true
        }
        
        // Only call super if there are filtered messages to process
        if !filteredMessages.isEmpty {
            super.messageCollection(collection, context: context, channel: channel, updatedMessages: filteredMessages)
        }
    }
} 