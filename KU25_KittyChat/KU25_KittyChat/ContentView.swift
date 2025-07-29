//  Hello
//  ContentView.swift
//  KittyChat
//
//  Created by yujuliao on 2025/07/22.
//

import SwiftUI
import SendbirdUIKit
import SendbirdChatSDK

class MainTabViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingChannelURL: String? = nil
}

struct ContentView: View {
    @StateObject private var tabViewModel = MainTabViewModel()
    @State private var isLoggedIn: Bool = false
    @State private var loggedInUserId: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var analyzedProfile: UserProfile? = nil
    @State private var analysisResult: ThreadsAnalysisResult? = nil
    @State private var showAnalysis: Bool = false
    @State private var customThreadsHandle: String = ""
    @State private var showChannelList: Bool = false
    @State private var showMatchingSheet: Bool = false

    var body: some View {
        ZStack {
            if isLoggedIn {
                MainTabView(
                    tabViewModel: tabViewModel,
                    onLogout: {
                        // Handle logout - reset to login state
                        DispatchQueue.main.async {
                            self.isLoggedIn = false
                            self.loggedInUserId = ""
                            self.analyzedProfile = nil
                            self.analysisResult = nil
                            self.showAnalysis = false
                            self.customThreadsHandle = ""
                            self.showChannelList = false
                            self.showMatchingSheet = false
                        }
                    }
                )
            } else if let profile = analyzedProfile, showAnalysis {
                // Use unified analysis view for both AI analysis and local data
                ProfileAnalysisView(
                    analysisResult: analysisResult,
                    profile: profile, 
                    customThreadsHandle: customThreadsHandle
                ) { displayName in
                    handleSignUp(userId: profile.userId, profile: profile, displayName: displayName)
                    showAnalysis = false
                }
            } else {
                OnboardingView(
                    onLoginTapped: handleLogin,
                    onSignUpTapped: analyzeUser
                )
            }
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Connecting...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert(item: $errorMessage) { message in
            Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
    
    // Existing user direct login
    private func handleLogin(userId: String) {
        print("handleLogin called with userId:", userId)
        self.isLoading = true
        self.errorMessage = nil
        SendbirdAPI.checkUserExists(userId: userId) { exists in
            DispatchQueue.main.async {
                if exists {
                    self.doLogin(userId: userId)
                } else {
                    self.isLoading = false
                    self.errorMessage = "This user ID is not registered. Please sign up first."
                }
            }
        }
    }
    
    // Actual login process
    private func doLogin(userId: String) {
        // No need to initialize again - already done in KittyChatApp.swift
        SendbirdChat.connect(userId: userId) { user, error in
            guard let user = user, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to connect to Sendbird: \(error?.localizedDescription ?? "Unknown error")"
                    self.isLoading = false
                }
                return
            }
            
            // Key: Set SBUGlobals.currentUser
            SBUGlobals.currentUser = SBUUser(userId: user.userId, nickname: user.nickname)
            print("[DEBUG] SBUGlobals.currentUser:", SBUGlobals.currentUser?.userId ?? "nil")
            print("[DEBUG] SendbirdChat.getCurrentUser:", SendbirdChat.getCurrentUser()?.userId ?? "nil")
            
            // Register GlobalMessageMonitor after successful connection
            print("[DEBUG] 🔗 Registering GlobalMessageMonitor after user connection")
            GlobalMessageMonitor.shared.registerMonitor()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loggedInUserId = user.userId
                self.isLoggedIn = true
                self.showChannelList = true
            }
        }
    }
    
    // New user registration process
    private func handleSignUp(userId: String, profile: UserProfile, displayName: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        // No need to initialize again - already done in KittyChatApp.swift
        SendbirdChat.connect(userId: userId) { user, error in
            guard let user = user, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to connect to Sendbird: \(error?.localizedDescription ?? "Unknown error")"
                    self.isLoading = false
                }
                return
            }
            
            print("Successfully connected to Sendbird as \(user.userId).")
            
            // Set SBUGlobals.currentUser for signup too
            SBUGlobals.currentUser = SBUUser(userId: user.userId, nickname: user.nickname)
            
            // Register GlobalMessageMonitor after successful connection
            print("[DEBUG] 🔗 Registering GlobalMessageMonitor after user signup")
            GlobalMessageMonitor.shared.registerMonitor()
            
            updateUserMetadata(for: profile, displayName: displayName)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loggedInUserId = user.userId
                self.isLoggedIn = true
                self.showChannelList = true
            }
        }
    }

    private func updateUserMetadata(for profile: UserProfile, displayName: String) {
        let metadataToUpdate = [
            "interests": profile.interests.joined(separator: ","),
            "personality": profile.personality,
            "misogyny_risk": profile.misogynyRisk,
            "strikes": String(profile.strikes)
        ]
        // First update nickname
        let params = UserUpdateParams()
        params.nickname = displayName
        SendbirdUI.updateUserInfo(params: params) { error in
            if let error = error {
                print("Failed to update nickname: \(error.localizedDescription)")
            } else {
                print("Nickname updated: \(displayName)")
            }
        }
        // Then update metaData
        SendbirdChat.getCurrentUser()?.updateMetaData(metadataToUpdate, completionHandler: { metaData, error in
            if let error = error {
                print("Failed to update user metadata: \(error.localizedDescription)")
            } else {
                print("User metadata updated: \(metaData ?? [:])")
            }
        })
    }
    
    private func analyzeUser(userId: String, threadsHandle: String) {
        print("[DEBUG] 🧵 Starting Threads analysis for userId: \(userId), handle: \(threadsHandle)")
        
        self.isLoading = true
        self.errorMessage = nil
        
        Task {
            do {
                // Use real Threads analysis service
                let analysisResult = try await ThreadsAnalysisService.shared.analyzeThreadsAccount(
                    threadsHandle: threadsHandle,
                    userId: userId
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.analysisResult = analysisResult
                    self.analyzedProfile = analysisResult.userProfile
                    self.customThreadsHandle = threadsHandle
                    self.showAnalysis = true
                    
                    // Debug: Check what data we're passing to ProfileAnalysisView
                    let totalPosts = analysisResult.profile.posts.count
                    let markedPosts = analysisResult.profile.posts.filter { 
                        $0.content.contains("[MISOGYNISTIC]") || $0.content.contains("[FLAGGED]") 
                    }.count
                    print("[DEBUG] ✅ Threads analysis completed successfully")
                    print("[DEBUG] 📊 ContentView: Passing \(totalPosts) total posts to ProfileAnalysisView")
                    print("[DEBUG] 📊 ContentView: \(markedPosts) posts are marked as flagged")
                    print("[DEBUG] 📊 ContentView: Misogyny risk: \(analysisResult.userProfile.misogynyRisk)")
                }
                
            } catch {
                print("[DEBUG] ❌ Threads analysis failed: \(error)")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Fallback to local JSON for testing
                    self.analyzeFallbackLocal(userId: userId, threadsHandle: threadsHandle, originalError: error)
        }
            }
        }
    }
    
    /// Fallback method using local JSON data
    private func analyzeFallbackLocal(userId: String, threadsHandle: String, originalError: Error) {
        print("[DEBUG] 🔄 Falling back to local JSON analysis")
        
        // Provide specific error message for URL parsing errors
        if let threadsError = originalError as? ThreadsAnalysisError {
            switch threadsError {
            case .invalidURL, .invalidUsername:
                self.errorMessage = threadsError.localizedDescription
                return
            default:
                break
            }
        }
        
        guard let url = Bundle.main.url(forResource: userId, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            self.errorMessage = "Threads analysis failed: \(originalError.localizedDescription)\n\nFor testing, you can use: user1, user2, user3, user4, or user5"
            return
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.analyzedProfile = profile
            self.customThreadsHandle = threadsHandle
            self.showAnalysis = true
            print("[DEBUG] ✅ Using local fallback data for \(userId)")
        } catch {
            print("[DEBUG] ❌ Local fallback also failed: \(error)")
            self.errorMessage = "Threads analysis failed: \(originalError.localizedDescription)\n\nPlease check your URL format or try again later."
        }
    }
}

// QuickStart standard three-tab architecture
struct MainTabView: View {
    @ObservedObject var tabViewModel: MainTabViewModel
    var onLogout: () -> Void
    
    var body: some View {
        TabView(selection: $tabViewModel.selectedTab) {
            // Matching
            MatchingView(onEnterChannel: { channelURL in
                tabViewModel.pendingChannelURL = channelURL
                tabViewModel.selectedTab = 1 // 切換到 Chat 分頁
            })
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Matching")
                }
                .tag(0)

            // Chat
            ChannelListTabWrapper(pendingChannelURL: $tabViewModel.pendingChannelURL)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .tag(1)

            // Education
            EducationView()
                .tabItem {
                    Image(systemName: "graduationcap.fill")
                    Text("Education")
                }
                .tag(2)

            // Profile
            ProfileView(onLogout: onLogout)
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(3)
        }
    }
}

// Chat room list wrapped with UINavigationController, supports cross-tab push to chat room
struct ChannelListTabWrapper: UIViewControllerRepresentable {
    @Binding var pendingChannelURL: String?
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = KittyChatChannelListViewController()
        return UINavigationController(rootViewController: vc)
    }
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let channelURL = pendingChannelURL {
            if let listVC = uiViewController.viewControllers.first as? KittyChatChannelListViewController {
                listVC.showChannel(channelURL: channelURL)
            }
            // Clear pendingChannelURL to avoid duplicate push
            DispatchQueue.main.async {
                pendingChannelURL = nil
            }
        }
    }
}

// SwiftUI wrapper for UIKit chat room list, supports presenting MatchingView
struct ChannelListViewWrapper: UIViewControllerRepresentable {
    @Binding var showMatching: Bool
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = KittyChatChannelListViewController()
        // Wrap with UINavigationController here
        return UINavigationController(rootViewController: vc)
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

// Custom channel list VC, pushes KittyChatChannelViewController on tap
import SendbirdUIKit
class KittyChatChannelListViewController: SBUGroupChannelListViewController {
    override func showChannel(channelURL: String, messageListParams: MessageListParams? = nil) {
        let chatVC = KittyChatChannelViewController(channelURL: channelURL)
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    // QuickStart recommended: Safe override to ensure cell tap always enters chat room
    override func baseChannelListModule(
        _ listComponent: SBUBaseChannelListModule.List,
        didSelectRowAt indexPath: IndexPath
    ) {
        let channel = self.channelList[indexPath.row]
        self.showChannel(channelURL: channel.channelURL)
    }
}

// Simple Identifiable wrapper for alert messages
extension String: Identifiable {
    public var id: String { self }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
