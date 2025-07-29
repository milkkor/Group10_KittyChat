import SwiftUI
import SendbirdUIKit
import SendbirdChatSDK

struct ProfileView: View {
    @State private var userProfile: UserProfile?
    @State private var currentStrikes: Double = 0
    @State private var isLoading: Bool = true
    @State private var aiPersonalityAnalysis: AIPersonalityAnalysis?
    @State private var showLogoutAlert: Bool = false
    
    var onLogout: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(hex: "fef9ff"),
                    Color(hex: "f3e8ff").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        headerSection
                        userInfoSection
                        topicPreferenceSection
                        safetyStatusSection
                        quickActionsSection
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserData()
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout? You'll need to login again to access your account.")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "c084fc").opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isLoading)
            }
            
            Text("Loading profile...")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6b7280"))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top navigation
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "374151"))
                }
                
                Spacer()
                
                Text("Profile")
                    .font(.headline)
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
                
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .foregroundColor(Color(hex: "374151"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // User avatar and basic info
            VStack(spacing: 16) {
                ZStack {
                    // Animated ring for premium feel
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text(userInitials)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "c084fc"))
                }
                
                VStack(spacing: 8) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "374151"))
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        ModernCard {
            VStack(spacing: 16) {
                // Simple header
                HStack {
                    Text("Basic Info")
                        .font(.headline)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Spacer()
                }
                
                // Simplified content
                VStack(spacing: 12) {
                    SimpleInfoRow(
                        title: "User ID",
                        value: userId,
                        isPrivate: true
                    )
                    
                    // Divider
                    Rectangle()
                        .fill(Color(hex: "f3f4f6"))
                        .frame(height: 1)
                    
                    SimpleInfoRow(
                        title: "Threads Account",
                        value: threadsHandle
                    )
                    
                    if let analysis = aiPersonalityAnalysis {
                        // Divider
                        Rectangle()
                            .fill(Color(hex: "f3f4f6"))
                            .frame(height: 1)
                        
                        AIPersonalityDisplay(analysis: analysis)
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Topic Preference Section (主打模組)
    
    private var topicPreferenceSection: some View {
        ModernCard {
            TopicPreferenceCard()
                .padding(24)
        }
    }
    
    // MARK: - Safety Status Section
    
    private var safetyStatusSection: some View {
        ModernCard {
            SafetySummaryCard(
                currentStrikes: currentStrikes,
                maxStrikes: StrikeManager.shared.maxStrikes
            )
            .padding(24)
        }
    }
    

    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ActionCard(
                    icon: "clock.arrow.circlepath",
                    title: "Interaction History",
                    subtitle: "View chat interaction history",
                    color: Color(hex: "3b82f6"),
                    action: { /* Show history */ }
                )
                
                ActionCard(
                    icon: "shield.checkerboard",
                    title: "Safety Settings",
                    subtitle: "Customize AI Guardian preferences",
                    color: Color(hex: "8b5cf6"),
                    action: { /* Show settings */ }
                )
                
                if currentStrikes > 0 {
                    ActionCard(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Reset Records",
                        subtitle: "Clear all warning records (dev only)",
                        color: Color(hex: "ef4444"),
                        action: { resetStrikes() }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var userInitials: String {
        let name = SBUGlobals.currentUser?.nickname ?? "User"
        return String(name.prefix(2)).uppercased()
    }
    
    private var userName: String {
        SBUGlobals.currentUser?.nickname ?? "Unknown User"
    }
    
    private var userId: String {
        SBUGlobals.currentUser?.userId ?? "unknown"
    }
    
    private var threadsHandle: String {
        userProfile?.threadsHandle ?? "unknown"
    }
    

    
    // MARK: - Helper Functions
    
    private func loadUserData() {
        guard let userId = SBUGlobals.currentUser?.userId else {
            print("[DEBUG] ❌ No current user found")
            isLoading = false
            return
        }
        
        currentStrikes = StrikeManager.shared.getCurrentStrikes(for: userId)
        loadUserProfileFromSendbird()
        loadAIPersonalityAnalysis()
        
        withAnimation(.easeInOut(duration: 0.8)) {
            isLoading = false
        }
        
        print("[DEBUG] ✅ Profile data loaded: \(currentStrikes) strikes")
    }
    
    private func loadUserProfileFromSendbird() {
        guard let currentUser = SendbirdChat.getCurrentUser() else { return }
        
        let metadata = currentUser.metaData
        let interests = metadata["interests"]?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        
        userProfile = UserProfile(
            userId: currentUser.userId,
            threadsHandle: currentUser.nickname,
            interests: interests,
            personality: metadata["personality"] ?? "Unknown",
            misogynyRisk: metadata["misogyny_risk"] ?? "Unknown",
            strikes: Int(metadata["strikes"] ?? "0") ?? 0
        )
    }
    
    private func loadAIPersonalityAnalysis() {
        // Mock data - In production, this would be generated by LLM based on recent chat history
        // Future: Integrate with GPT/Gemini API to analyze user's conversation patterns
        let mockAnalysis = AIPersonalityAnalysis(
            languageStyle: "You often use questions and emojis, with a gentle and polite tone.",
            communicationStyle: "You like to start with questions, prefer rational organization, and express views after emotional packaging.",
            personaSummary: PersonaSummary(
                label: "Rational & Gentle Observer",
                description: "You always understand before responding, speak logically but not coldly, and consider others' perspectives."
            )
        )
        
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.aiPersonalityAnalysis = mockAnalysis
        }
    }
    
    private func resetStrikes() {
        guard let userId = SBUGlobals.currentUser?.userId else { return }
        
        StrikeManager.shared.resetStrikes(for: userId) { success in
            if success {
                DispatchQueue.main.async {
                    withAnimation(.spring()) {
                        currentStrikes = 0
                    }
                    loadUserData()
                }
            }
        }
    }
    
    private func logout() {
        // Disconnect from Sendbird
        SendbirdChat.disconnect {
            DispatchQueue.main.async {
                // Clear local data
                self.clearLocalData()
                
                // Call logout callback to navigate back to login
                self.onLogout?()
                
                print("[DEBUG] ✅ User logged out successfully")
            }
        }
    }
    
    private func clearLocalData() {
        // Clear user profile
        userProfile = nil
        aiPersonalityAnalysis = nil
        currentStrikes = 0
        
        // Clear any cached data
        // You might want to clear UserDefaults, Core Data, etc.
        print("[DEBUG] 🧹 Local data cleared")
    }
}

#Preview {
    ProfileView(onLogout: {
        print("Logout callback triggered")
    })
} 