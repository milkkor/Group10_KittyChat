import Foundation
import SendbirdChatSDK

// Strike record for tracking violations
struct StrikeRecord: Codable {
    let timestamp: Date
    let ruleType: String
    let severity: Int
    let message: String
    let senderResponse: String?
    let receiverResponse: String?
    let strikes: Double
    
    init(ruleType: String, severity: DetectionSeverity, message: String, interactionResult: InteractionResult? = nil) {
        self.timestamp = Date()
        self.ruleType = ruleType
        self.severity = severity.rawValue
        self.message = message
        self.senderResponse = interactionResult?.senderResponse.rawValue
        self.receiverResponse = interactionResult?.receiverResponse.rawValue
        self.strikes = interactionResult?.strikes ?? 0.0
    }
}

// Pending interaction for tracking incomplete responses
struct PendingInteraction: Codable {
    let id: String
    let timestamp: Date
    let senderId: String
    let receiverId: String
    let message: String
    let detectionResult: String // JSON encoded DetectionResult
    var senderResponse: String?
    var receiverResponse: String?
    
    init(senderId: String, receiverId: String, message: String, detectionResult: DetectionResult) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.senderId = senderId
        self.receiverId = receiverId
        self.message = message
        
        // Encode detection result as JSON string
        let encoder = JSONEncoder()
        if let data = try? encoder.encode([
            "type": detectionResult.rule.type,
            "keyword": detectionResult.rule.keyword,
            "matchedText": detectionResult.matchedText,
            "severity": String(detectionResult.severity.rawValue)
        ]) {
            self.detectionResult = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            self.detectionResult = "{}"
        }
    }
    
    var isComplete: Bool {
        return senderResponse != nil && receiverResponse != nil
    }
}

struct PendingGeminiInteraction: Codable {
    let id: String
    let timestamp: Date
    let senderId: String
    let receiverId: String
    let message: String
    let geminiAnalysis: String // JSON encoded Gemini analysis
    var senderResponse: String?
    var receiverResponse: String?
    
    init(senderId: String, receiverId: String, message: String, geminiAnalysis: [String: Any]) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.senderId = senderId
        self.receiverId = receiverId
        self.message = message
        
        // Encode Gemini analysis as JSON string
        if let data = try? JSONSerialization.data(withJSONObject: geminiAnalysis, options: []) {
            self.geminiAnalysis = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            self.geminiAnalysis = "{}"
        }
    }
    
    var isComplete: Bool {
        return senderResponse != nil && receiverResponse != nil
    }
}

class StrikeManager {
    static let shared = StrikeManager()
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    let maxStrikes = 3.0
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        setupInitialUserData()
    }
    
    /// Setup initial user data from bundle
    private func setupInitialUserData() {
        let mockDataPath = "MockData/Users"
        guard let bundleURL = Bundle.main.url(forResource: mockDataPath, withExtension: nil),
              let userFiles = try? fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil) else {
            print("Could not find mock user data in bundle.")
            return
        }
        
        for userFile in userFiles {
            let destinationURL = documentsDirectory.appendingPathComponent(userFile.lastPathComponent)
            if !fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    try fileManager.copyItem(at: userFile, to: destinationURL)
                    print("Copied \(userFile.lastPathComponent) to Documents directory.")
                } catch {
                    print("Error copying user data: \(error)")
                }
            }
        }
    }
    
    /// Create a pending interaction when message is flagged
    func createPendingInteraction(senderId: String, receiverId: String, message: String, detectionResult: DetectionResult) -> String {
        let interaction = PendingInteraction(senderId: senderId, receiverId: receiverId, message: message, detectionResult: detectionResult)
        savePendingInteraction(interaction)
        return interaction.id
    }
    
    /// Create a pending Gemini interaction when message is flagged by Gemini
    func createPendingGeminiInteraction(senderId: String, receiverId: String, message: String, geminiAnalysis: [String: Any]) -> String {
        let interaction = PendingGeminiInteraction(senderId: senderId, receiverId: receiverId, message: message, geminiAnalysis: geminiAnalysis)
        savePendingGeminiInteraction(interaction)
        return interaction.id
    }
    
    /// Record sender's response to flagged message
    func recordSenderResponse(interactionId: String, response: SenderResponse, completion: @escaping (Bool) -> Void) {
        // Try to find in regular interactions first
        if var interaction = loadPendingInteraction(id: interactionId) {
            interaction.senderResponse = response.rawValue
            savePendingInteraction(interaction)
            print("Recorded sender response: \(response.displayText)")
            completion(true)
            return
        }
        
        // Try to find in Gemini interactions
        if var interaction = loadPendingGeminiInteraction(id: interactionId) {
        interaction.senderResponse = response.rawValue
            savePendingGeminiInteraction(interaction)
            print("Recorded Gemini sender response: \(response.displayText)")
        completion(true)
            return
        }
        
        completion(false)
    }
    
    /// Record receiver's response and calculate final strikes
    func recordReceiverResponse(interactionId: String, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        // Check if this is a local regular interaction (same device)
        if let interaction = loadPendingInteraction(id: interactionId) {
            print("[DEBUG] ✅ Found local pending interaction - processing locally")
            processLocalInteraction(interaction, response: response, completion: completion)
            return
        }
        
        // Check if this is a local Gemini interaction (same device)
        if let interaction = loadPendingGeminiInteraction(id: interactionId) {
            print("[DEBUG] ✅ Found local pending Gemini interaction - processing locally")
            processLocalGeminiInteraction(interaction, response: response, completion: completion)
            return
        }
        
        // This is a cross-device interaction - use webhook
        print("[DEBUG] 🌐 Cross-device interaction detected - using webhook")
        processCrossDeviceInteraction(interactionId: interactionId, response: response, completion: completion)
    }
    
    /// Process local interaction (same device testing)
    private func processLocalInteraction(_ interaction: PendingInteraction, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        var updatedInteraction = interaction
        updatedInteraction.receiverResponse = response.rawValue
        
        // Calculate strikes if both responses are available
        if let senderResponseStr = interaction.senderResponse,
           let senderResponse = SenderResponse(rawValue: senderResponseStr) {
            
            let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: response)
            
            // Check if this is cross-user scenario (receiver trying to add strikes to sender)
            if let currentUser = SendbirdChat.getCurrentUser(),
               currentUser.userId != interaction.senderId {
                
                print("[DEBUG] 🌐 Cross-user scenario: \(currentUser.userId) adding strikes to \(interaction.senderId)")
                
                // Send custom event to notify sender about the response
                sendStrikeNotificationEvent(
                    senderId: interaction.senderId,
                    interactionId: interaction.id,
                    response: response,
                    strikes: interactionResult.strikes
                ) { [weak self] success in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        if success {
                            print("[DEBUG] ✅ Strike notification sent to sender via webhook")
                        } else {
                            print("[DEBUG] ⚠️ Failed to send strike notification to sender")
                        }
                        
                        // Clean up pending interaction
                        self?.deletePendingInteraction(id: interaction.id)
                        completion(interactionResult.strikes, interactionResult.strikes >= self?.maxStrikes ?? 5.0)
                    }
                }
            } else {
                // Same user scenario (for testing or self-interaction)
                addStrikesToUser(userId: interaction.senderId, strikes: interactionResult.strikes, interaction: interaction) { [weak self] newTotal, limitReached in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        // Clean up pending interaction
                        self?.deletePendingInteraction(id: interaction.id)
                        completion(newTotal, limitReached)
                    }
                }
            }
        } else {
            // Save and wait for sender response
            savePendingInteraction(updatedInteraction)
            completion(0, false)
        }
    }
    
    /// Process local Gemini interaction (same device testing)
    private func processLocalGeminiInteraction(_ interaction: PendingGeminiInteraction, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        var updatedInteraction = interaction
        updatedInteraction.receiverResponse = response.rawValue
        
        // Calculate strikes if both responses are available
        if let senderResponseStr = interaction.senderResponse,
           let senderResponse = SenderResponse(rawValue: senderResponseStr) {
            
            let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: response)
            
            // Check if this is cross-user scenario (receiver trying to add strikes to sender)
            if let currentUser = SendbirdChat.getCurrentUser(),
               currentUser.userId != interaction.senderId {
                
                print("[DEBUG] 🌐 Cross-user scenario: \(currentUser.userId) adding strikes to \(interaction.senderId)")
                
                // Send custom event to notify sender about the response
                sendStrikeNotificationEvent(
                    senderId: interaction.senderId,
                    interactionId: interaction.id,
                    response: response,
                    strikes: interactionResult.strikes
                ) { [weak self] success in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        if success {
                            print("[DEBUG] ✅ Strike notification sent to sender via webhook")
                        } else {
                            print("[DEBUG] ⚠️ Failed to send strike notification to sender")
                        }
                        
                        // Clean up pending interaction
                        self?.deletePendingGeminiInteraction(id: interaction.id)
                        completion(interactionResult.strikes, interactionResult.strikes >= self?.maxStrikes ?? 5.0)
                    }
                }
            } else {
                // Same user scenario (for testing or self-interaction)
                addStrikesToUser(userId: interaction.senderId, strikes: interactionResult.strikes, interaction: interaction) { [weak self] newTotal, limitReached in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        // Clean up pending interaction
                        self?.deletePendingGeminiInteraction(id: interaction.id)
                        completion(newTotal, limitReached)
                    }
                }
            }
        } else {
            // Save and wait for sender response
            savePendingGeminiInteraction(updatedInteraction)
            completion(0, false)
        }
    }
    
    /// Process cross-device interaction using webhook (with sender context)
    func processCrossDeviceInteractionWithContext(interactionId: String, senderId: String, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        guard let currentUser = SendbirdChat.getCurrentUser() else {
            print("[DEBUG] ❌ No current user for cross-device interaction")
            completion(0, false)
            return
        }
        
        let strikes = calculateStrikesForResponse(response)
        
        print("[DEBUG] 🌐 Processing cross-device interaction via webhook:")
        print("[DEBUG]   - Interaction ID: \(interactionId)")
        print("[DEBUG]   - Sender ID: \(senderId)")
        print("[DEBUG]   - Response: \(response.rawValue)")
        print("[DEBUG]   - Calculated strikes: \(strikes)")
        print("[DEBUG]   - Responding user: \(currentUser.userId)")
        
        // Send webhook directly with all the necessary context
        sendStrikeNotificationEvent(
            senderId: senderId,
            interactionId: interactionId,
            response: response,
            strikes: strikes
        ) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("[DEBUG] ✅ Cross-device webhook sent successfully")
                    
                    // Also update Sendbird metadata locally for immediate UI feedback
                    self?.updateSendbirdMetadataForUser(userId: senderId, additionalStrikes: strikes) { updateSuccess in
                        if updateSuccess {
                            print("[DEBUG] ✅ Sendbird metadata updated locally after webhook")
                        } else {
                            print("[DEBUG] ⚠️ Failed to update Sendbird metadata locally")
                        }
                    }
                    
                    completion(strikes, strikes >= self?.maxStrikes ?? 3.0)
                } else {
                    print("[DEBUG] ❌ Cross-device webhook failed")
                    completion(0, false)
                }
            }
        }
    }
    
    /// Process cross-device interaction using webhook (legacy method)
    private func processCrossDeviceInteraction(interactionId: String, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        // This method lacks sender context - it should not be used for real cross-device scenarios
        print("[DEBUG] ⚠️ Legacy cross-device method called - missing sender context")
        let strikes = calculateStrikesForResponse(response)
        completion(strikes, false)
    }
    
    /// Calculate strikes based on receiver response
    private func calculateStrikesForResponse(_ response: ReceiverResponse) -> Double {
        switch response {
        case .acceptable:
            return 0.0
        case .uncomfortable:
            return 1.5
        case .exit:
            return 2.0
        }
    }
    
    /// Send strike notification directly to webhook endpoint
    private func sendStrikeNotificationEvent(senderId: String, interactionId: String, response: ReceiverResponse, strikes: Double, completion: @escaping (Bool) -> Void) {
        
        guard let currentUser = SendbirdChat.getCurrentUser() else {
            print("[DEBUG] ❌ No current user to send strike notification")
            completion(false)
            return
        }
        
        // Create webhook payload matching the expected format
        let dataPayload = [
            "interaction_id": interactionId,
            "receiver_response": response.rawValue,
            "strikes": String(strikes),
            "target_user_id": senderId,
            "responding_user_id": currentUser.userId,
            "timestamp": String(Date().timeIntervalSince1970)
        ]
        
        guard let dataJsonData = try? JSONSerialization.data(withJSONObject: dataPayload),
              let dataString = String(data: dataJsonData, encoding: .utf8) else {
            print("[DEBUG] ❌ Failed to serialize webhook data payload")
            completion(false)
            return
        }
        
        let webhookPayload = [
            "category": "channel:message.create",
            "payload": [
                "custom_type": "ai_guardian_strike",
                "data": dataString
            ]
        ] as [String: Any]
        
        print("[DEBUG] 📡 Sending strike notification directly to webhook endpoint")
        print("[DEBUG] 📨 Webhook payload: \(webhookPayload)")
        
        // Send POST request to webhook endpoint
        sendWebhookRequest(payload: webhookPayload) { [weak self] success in
            if success {
                print("[DEBUG] ✅ Strike notification sent to webhook successfully")
                completion(true)
            } else {
                print("[DEBUG] ⚠️ Failed to send webhook request, falling back to local processing")
                // Fallback: Process strikes locally
                self?.processStrikesLocally(senderId: senderId, strikes: strikes, interactionId: interactionId, completion: completion)
            }
        }
    }
    
    /// Send POST request to webhook endpoint
    private func sendWebhookRequest(payload: [String: Any], completion: @escaping (Bool) -> Void) {
        // Use configured webhook URL
        let webhookURL = StrikeManager.getWebhookURL()
        
        guard let url = URL(string: webhookURL) else {
            print("[DEBUG] ❌ Invalid webhook URL")
            completion(false)
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("[DEBUG] ❌ Failed to serialize webhook payload")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[DEBUG] 🌐 Sending POST request to webhook: \(webhookURL)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] ❌ Webhook request error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[DEBUG] ❌ Invalid webhook response")
                completion(false)
                return
            }
            
            print("[DEBUG] 🌐 Webhook response status: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] 📨 Webhook response: \(responseString)")
            }
            
            let success = (200...299).contains(httpResponse.statusCode)
            if success {
                print("[DEBUG] ✅ Webhook request successful")
            } else {
                print("[DEBUG] ❌ Webhook request failed with status: \(httpResponse.statusCode)")
            }
            
            completion(success)
        }.resume()
    }
    

    
    /// Fallback method to process strikes locally when webhook is unavailable
    private func processStrikesLocally(senderId: String, strikes: Double, interactionId: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] 🔄 Processing strikes locally as fallback")
        
        // Find the pending interaction
        guard let interaction = loadPendingInteraction(id: interactionId) else {
            print("[DEBUG] ❌ No pending interaction found for local processing")
            completion(false)
            return
        }
        
        // Process strikes locally
        addStrikesToUser(userId: senderId, strikes: strikes, interaction: interaction) { [weak self] finalStrikes, limitReached in
            print("[DEBUG] ✅ Local strike processing complete: \(finalStrikes) strikes")
            self?.deletePendingInteraction(id: interactionId)
            completion(true)
        }
    }
    
    /// Add strikes to a specific user
    private func addStrikesToUser(userId: String, strikes: Double, interaction: PendingInteraction, completion: @escaping (Double, Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("Could not load profile to add strikes.")
            completion(0, false)
            return
        }
        
        let previousStrikes = Double(profile.strikes)
        let newStrikes = previousStrikes + strikes
        profile.strikes = Int(ceil(newStrikes)) // Round up for integer storage
        
        // Create interaction result for record
        let senderResponse = SenderResponse(rawValue: interaction.senderResponse ?? "") ?? .retract
        let receiverResponse = ReceiverResponse(rawValue: interaction.receiverResponse ?? "") ?? .exit
        let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: receiverResponse)
        
        // Record the strike with interaction details
        let record = StrikeRecord(
            ruleType: "interaction", // Will be parsed from detectionResult if needed
            severity: .medium, // Default severity
            message: interaction.message,
            interactionResult: interactionResult
        )
        saveStrikeRecord(record, for: userId)
        
        // Save to local file
        saveProfile(profile, to: fileURL)
        
        let limitReached = newStrikes >= maxStrikes
        if limitReached {
            print("User \(userId) has reached the strike limit (\(newStrikes)/\(maxStrikes)).")
        } else {
            print("User \(userId) received \(strikes) strike(s). Total: \(newStrikes)/\(maxStrikes)")
        }
        
        // Sync strikes to Sendbird metadata
        syncStrikesToSendbird(userId: userId, newStrikes: newStrikes) { [weak self] success in
            if success {
                print("[DEBUG] ✅ Strikes synced to Sendbird metadata: \(newStrikes)")
            } else {
                print("[DEBUG] ⚠️ Failed to sync strikes to Sendbird, but local update succeeded")
            }
            
            // Always call completion regardless of Sendbird sync result
            completion(newStrikes, limitReached)
        }
    }
    
    /// Add strikes to a specific user (Gemini interaction version)
    private func addStrikesToUser(userId: String, strikes: Double, interaction: PendingGeminiInteraction, completion: @escaping (Double, Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("Could not load profile to add strikes.")
            completion(0, false)
            return
        }
        
        let previousStrikes = Double(profile.strikes)
        let newStrikes = previousStrikes + strikes
        profile.strikes = Int(ceil(newStrikes)) // Round up for integer storage
        
        // Create interaction result for record
        let senderResponse = SenderResponse(rawValue: interaction.senderResponse ?? "") ?? .retract
        let receiverResponse = ReceiverResponse(rawValue: interaction.receiverResponse ?? "") ?? .exit
        let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: receiverResponse)
        
        // Record the strike with interaction details
        let record = StrikeRecord(
            ruleType: "gemini_interaction", // Mark as Gemini interaction
            severity: .medium, // Default severity
            message: interaction.message,
            interactionResult: interactionResult
        )
        saveStrikeRecord(record, for: userId)
        
        // Save to local file
        saveProfile(profile, to: fileURL)
        
        let limitReached = newStrikes >= maxStrikes
        if limitReached {
            print("User \(userId) has reached the strike limit (\(newStrikes)/\(maxStrikes)).")
        } else {
            print("User \(userId) received \(strikes) strike(s). Total: \(newStrikes)/\(maxStrikes)")
        }
        
        // Sync strikes to Sendbird metadata
        syncStrikesToSendbird(userId: userId, newStrikes: newStrikes) { [weak self] success in
            if success {
                print("[DEBUG] ✅ Strikes synced to Sendbird metadata: \(newStrikes)")
            } else {
                print("[DEBUG] ⚠️ Failed to sync strikes to Sendbird, but local update succeeded")
            }
            
            // Always call completion regardless of Sendbird sync result
            completion(newStrikes, limitReached)
        }
    }
    
    /// Sync strikes to Sendbird user metadata
    private func syncStrikesToSendbird(userId: String, newStrikes: Double, completion: @escaping (Bool) -> Void) {
        // Only sync if the user is the current user (for security)
        guard let currentUser = SendbirdChat.getCurrentUser(),
              currentUser.userId == userId else {
            print("[DEBUG] 🔒 Can only sync strikes for current user. Skipping Sendbird sync.")
            completion(false)
            return
        }
        
        let metadataToUpdate = [
            "strikes": String(Int(ceil(newStrikes)))
        ]
        
        print("[DEBUG] 🔄 Syncing strikes to Sendbird metadata: \(metadataToUpdate)")
        
        currentUser.updateMetaData(metadataToUpdate) { metadata, error in
            if let error = error {
                print("[DEBUG] ❌ Failed to sync strikes to Sendbird: \(error.localizedDescription)")
                completion(false)
            } else {
                print("[DEBUG] ✅ Successfully synced strikes to Sendbird metadata")
                if let metadata = metadata {
                    print("[DEBUG] 📊 Updated metadata: \(metadata)")
                }
                completion(true)
            }
        }
    }
    
    /// Legacy method for single-user strikes
    func addStrike(for userId: String, detectionResult: DetectionResult, completion: @escaping (Int, Bool) -> Void) {
        let strikesToAdd = Double(detectionResult.severity.strikeCount)
        let legacyInteraction = PendingInteraction(senderId: userId, receiverId: "system", message: "", detectionResult: detectionResult)
        addStrikesToUser(userId: userId, strikes: strikesToAdd, interaction: legacyInteraction) { strikes, limitReached in
            completion(Int(ceil(strikes)), limitReached)
        }
    }
    
    /// Reset strikes for a user (after education completion)
    func resetStrikes(for userId: String, completion: @escaping (Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("Could not load profile to reset strikes.")
            completion(false)
            return
        }
        
        let previousStrikes = profile.strikes
        profile.strikes = 0
        saveProfile(profile, to: fileURL)
        
        print("Reset strikes for user \(userId): \(previousStrikes) → 0")
        
        // Sync reset to Sendbird metadata
        syncStrikesToSendbird(userId: userId, newStrikes: 0.0) { success in
            if success {
                print("[DEBUG] ✅ Strike reset synced to Sendbird metadata")
            } else {
                print("[DEBUG] ⚠️ Failed to sync strike reset to Sendbird, but local reset succeeded")
            }
            
            // Always return success if local reset worked
            completion(true)
        }
    }
    
    /// Get current strike count for a user
    func getCurrentStrikes(for userId: String) -> Double {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        guard let profile = loadProfile(for: userId, from: fileURL) else {
            return 0
        }
        return Double(profile.strikes)
    }
    
    // MARK: - Private Helpers
    
    private func loadProfile(for userId: String, from url: URL) -> UserProfile? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("Failed to load profile for \(userId): \(error)")
            return nil
        }
    }
    
    private func saveProfile(_ profile: UserProfile, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            try data.write(to: url)
            print("Successfully saved profile for \(profile.userId) with \(profile.strikes) strikes.")
        } catch {
            print("Failed to save profile for \(profile.userId): \(error)")
        }
    }
    
    private func saveStrikeRecord(_ record: StrikeRecord, for userId: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId)_strikes.json")
        
        var records = getStrikeHistory(for: userId)
        records.append(record)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
            print("Saved strike record for \(userId): \(record.strikes) strikes")
        } catch {
            print("Failed to save strike record: \(error)")
        }
    }
    
    private func savePendingInteraction(_ interaction: PendingInteraction) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        
        var interactions = loadPendingInteractions()
        interactions.removeAll { $0.id == interaction.id }
        interactions.append(interaction)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save pending interaction: \(error)")
        }
    }
    
    private func savePendingGeminiInteraction(_ interaction: PendingGeminiInteraction) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_gemini_interactions.json")
        
        var interactions = loadPendingGeminiInteractions()
        interactions.removeAll { $0.id == interaction.id }
        interactions.append(interaction)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save pending Gemini interaction: \(error)")
        }
    }
    
    private func loadPendingInteraction(id: String) -> PendingInteraction? {
        return loadPendingInteractions().first { $0.id == id }
    }
    
    func loadPendingGeminiInteraction(id: String) -> PendingGeminiInteraction? {
        return loadPendingGeminiInteractions().first { $0.id == id }
    }
    
    private func loadPendingInteractions() -> [PendingInteraction] {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingInteraction].self, from: data)) ?? []
    }
    
    private func loadPendingGeminiInteractions() -> [PendingGeminiInteraction] {
        let fileURL = documentsDirectory.appendingPathComponent("pending_gemini_interactions.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingGeminiInteraction].self, from: data)) ?? []
    }
    
    private func deletePendingInteraction(id: String) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        var interactions = loadPendingInteractions()
        interactions.removeAll { $0.id == id }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to delete pending interaction: \(error)")
        }
    }
    
    private func deletePendingGeminiInteraction(id: String) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_gemini_interactions.json")
        var interactions = loadPendingGeminiInteractions()
        interactions.removeAll { $0.id == id }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to delete pending Gemini interaction: \(error)")
        }
    }
    
    /// Get strike history for a user
    func getStrikeHistory(for userId: String) -> [StrikeRecord] {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId)_strikes.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([StrikeRecord].self, from: data))?.sorted { $0.timestamp > $1.timestamp } ?? []
    }
    
    // MARK: - Webhook Integration Methods
    
    /// Process strike update received from webhook
    /// Called when Firebase Functions processes a receiver response and calculates strikes
    /// - Parameters:
    ///   - userId: Target user who should receive strikes
    ///   - strikes: Number of strikes to add
    ///   - interactionId: ID of the original interaction
    ///   - receiverResponse: The response that triggered the strikes
    ///   - completion: Callback with success status
    func processWebhookStrikeUpdate(userId: String, strikes: Double, interactionId: String, receiverResponse: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] 🌐 StrikeManager: Processing webhook strike update")
        print("[DEBUG] 📊 User: \(userId), Strikes: \(strikes), Interaction: \(interactionId)")
        
        // Find the original pending interaction
        guard let interaction = loadPendingInteraction(id: interactionId) else {
            print("[DEBUG] ❌ No pending interaction found for webhook processing")
            // Still process the strikes even if we can't find the original interaction
            let mockInteraction = PendingInteraction(
                senderId: userId,
                receiverId: "webhook",
                message: "Webhook processed response",
                detectionResult: DetectionResult(
                    rule: DetectionRule(keyword: "webhook", type: "belittling"),
                    matchedText: "webhook"
                )
            )
            
            processWebhookStrikesForUser(userId: userId, strikes: strikes, interaction: mockInteraction, receiverResponse: receiverResponse, completion: completion)
            return
        }
        
        processWebhookStrikesForUser(userId: userId, strikes: strikes, interaction: interaction, receiverResponse: receiverResponse) { [weak self] success in
            if success {
                // Clean up the pending interaction
                self?.deletePendingInteraction(id: interactionId)
                print("[DEBUG] ✅ Webhook strike processing complete, pending interaction cleaned up")
            }
            completion(success)
        }
    }
    
    /// Internal method to process strikes for webhook updates
    private func processWebhookStrikesForUser(userId: String, strikes: Double, interaction: PendingInteraction, receiverResponse: String, completion: @escaping (Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("[DEBUG] ❌ Could not load profile for webhook strike processing")
            completion(false)
            return
        }
        
        let previousStrikes = Double(profile.strikes)
        let newStrikes = previousStrikes + strikes
        profile.strikes = Int(ceil(newStrikes))
        
        // Create interaction result for record
        let senderResponse = SenderResponse(rawValue: interaction.senderResponse ?? "") ?? .retract
        let receiverResponseEnum = ReceiverResponse(rawValue: receiverResponse) ?? .exit
        let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: receiverResponseEnum)
        
        // Record the strike with webhook source
        let record = StrikeRecord(
            ruleType: "webhook_processed",
            severity: .medium,
            message: interaction.message,
            interactionResult: interactionResult
        )
        saveStrikeRecord(record, for: userId)
        
        // Save profile locally
        saveProfile(profile, to: fileURL)
        
        let limitReached = newStrikes >= maxStrikes
        if limitReached {
            print("[DEBUG] ⚠️ Webhook: User \(userId) has reached the strike limit (\(newStrikes)/\(maxStrikes))")
        } else {
            print("[DEBUG] ✅ Webhook: User \(userId) received \(strikes) strike(s). Total: \(newStrikes)/\(maxStrikes)")
        }
        
        // Sync to Sendbird metadata (only if it's the current user)
        if let currentUser = SendbirdChat.getCurrentUser(), currentUser.userId == userId {
            syncStrikesToSendbird(userId: userId, newStrikes: newStrikes) { success in
                if success {
                    print("[DEBUG] ✅ Webhook strikes synced to Sendbird metadata")
                } else {
                    print("[DEBUG] ⚠️ Failed to sync webhook strikes to Sendbird")
                }
                completion(true) // Always succeed locally even if Sendbird sync fails
            }
        } else {
            print("[DEBUG] ℹ️ Webhook: Skipping Sendbird sync for non-current user")
            completion(true)
        }
    }
    
    /// Get webhook endpoint URL
    /// - Returns: The current webhook endpoint URL
    static func getWebhookURL() -> String {
        return WebhookEndpointURL.getWebhookURL()
    }
    
    /// Update Sendbird user metadata for any user (cross-device support)
    private func updateSendbirdMetadataForUser(userId: String, additionalStrikes: Double, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] 🔄 Updating Sendbird metadata for user: \(userId), additional strikes: \(additionalStrikes)")
        
        // First get the current user metadata from Sendbird to calculate new total
        getUserMetadataFromSendbird(userId: userId) { [weak self] currentMetadata in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Calculate new strikes total
            let currentStrikes = Double(currentMetadata["strikes"] as? String ?? "0") ?? 0.0
            let newStrikes = currentStrikes + additionalStrikes
            let newStrikesString = String(Int(ceil(newStrikes)))
            
            print("[DEBUG] 📊 User \(userId): \(currentStrikes) + \(additionalStrikes) = \(newStrikes) strikes")
            
            // Update metadata
            var updatedMetadata = currentMetadata
            updatedMetadata["strikes"] = newStrikesString
            
            // Use Sendbird API to update the user metadata
            self.updateUserMetadataViaSendbirdAPI(userId: userId, metadata: updatedMetadata, completion: completion)
        }
    }
    
    /// Get user metadata from Sendbird via API
    private func getUserMetadataFromSendbird(userId: String, completion: @escaping ([String: String]) -> Void) {
        let urlString = "https://api-\(SendbirdAPI.appId).sendbird.com/v3/users/\(userId)"
        guard let url = URL(string: urlString) else {
            print("[DEBUG] ❌ Invalid Sendbird API URL")
            completion([:])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SendbirdAPI.apiToken, forHTTPHeaderField: "Api-Token")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] ❌ Error fetching user metadata: \(error)")
                completion([:])
                return
            }
            
            guard let data = data else {
                print("[DEBUG] ❌ No data received from Sendbird API")
                completion([:])
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let metadata = json["metadata"] as? [String: String] {
                print("[DEBUG] ✅ Retrieved user metadata: \(metadata)")
                completion(metadata)
            } else {
                print("[DEBUG] ⚠️ No metadata found, using empty metadata")
                completion([:])
            }
        }.resume()
    }
    
    /// Update user metadata via Sendbird API
    private func updateUserMetadataViaSendbirdAPI(userId: String, metadata: [String: String], completion: @escaping (Bool) -> Void) {
        let urlString = "https://api-\(SendbirdAPI.appId).sendbird.com/v3/users/\(userId)/metadata"
        guard let url = URL(string: urlString) else {
            print("[DEBUG] ❌ Invalid Sendbird metadata API URL")
            completion(false)
            return
        }
        
        let payload = ["metadata": metadata]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(SendbirdAPI.apiToken, forHTTPHeaderField: "Api-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("[DEBUG] ❌ Error serializing metadata payload: \(error)")
            completion(false)
            return
        }
        
        print("[DEBUG] 🔄 Updating Sendbird metadata via API for user: \(userId)")
        print("[DEBUG] 📊 New metadata: \(metadata)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] ❌ Error updating user metadata: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[DEBUG] ❌ Invalid HTTP response")
                completion(false)
                return
            }
            
            print("[DEBUG] 🌐 Sendbird metadata update status: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] 📨 Sendbird metadata response: \(responseString)")
            }
            
            let success = (200...299).contains(httpResponse.statusCode)
            if success {
                print("[DEBUG] ✅ Sendbird metadata updated successfully")
            } else {
                print("[DEBUG] ❌ Sendbird metadata update failed with status: \(httpResponse.statusCode)")
            }
            
            completion(success)
        }.resume()
    }
} 