import SwiftUI
import SendbirdUIKit
import SendbirdChatSDK

@main
struct KittyChatApp: App {
    
    init() {
        // Initialize Sendbird
        self.initializeSendbird()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func initializeSendbird() {
        // Initialize SendBird using centralized configuration from SendbirdAPI
        SendbirdUI.initialize(
            applicationId: SendbirdAPI.appId,
            startHandler: {
                print("Sendbird UI initialization started")
            },
            migrationHandler: {
                print("Sendbird migration started")
            },
            completionHandler: { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Sendbird initialization failed: \(error)")
                    } else {
                        print("Sendbird initialized successfully")
                        
                        // Register global AI Guardian message monitor after successful initialization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            GlobalMessageMonitor.shared.registerMonitor()
                        }
                    }
                }
            }
        )
    }
} 
