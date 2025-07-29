import SwiftUI

struct ProfileAnalysisView: View {
    let analysisResult: ThreadsAnalysisResult?
    let profile: UserProfile
    let customThreadsHandle: String
    let onContinue: (String) -> Void
    @State private var displayName: String = ""
    @State private var isNameFocused: Bool = false
    @FocusState private var focusedField: Bool
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "fef9ff")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo + 標題 (固定在上方)
                HeaderView(userId: profile.userId, threadsHandle: customThreadsHandle)
                
                // 中間可滾動內容區域
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                // 統計數據視覺化卡片
                        StatsGridView(profile: profile, analysisResult: analysisResult)
                
                // 總結判斷區塊
                        SummaryBadge(
                            isSafe: profile.misogynyRisk == "Safe",
                            safetyScore: analysisResult?.analysisDetails.overallSafetyScore,
                            analysisDetails: analysisResult?.analysisDetails
                        )
                    }
                    .padding(.horizontal)
                }
                
                // 使用者輸入暱稱 + 按鈕 (固定在下方)
                NicknameInputView(
                    displayName: $displayName,
                    isNameFocused: $isNameFocused,
                    focusedField: $focusedField,
                    onContinue: { onContinue(displayName) }
                )
            }
            .padding()
        }
    }
}

// MARK: - HeaderView
struct HeaderView: View {
    let userId: String
    let threadsHandle: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(hex: "c084fc"))
            }
            
            Text("Threads Analysis")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "374151"))
            
            VStack(spacing: 4) {
                Text("User ID: \(userId)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6b7280"))
                Text("Threads: @\(threadsHandle)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6b7280"))
            }
        }
    }
}

// MARK: - StatsGridView
struct StatsGridView: View {
    let profile: UserProfile
    let analysisResult: ThreadsAnalysisResult?
    
    // Real analysis data or fallback values
    private var contentTone: String {
        analysisResult?.analysisDetails.contentTone.rawValue ?? "Neutral"
    }
    
    private var safetyScore: Double {
        analysisResult?.analysisDetails.overallSafetyScore ?? 0.5
    }
    
    private var postCount: Int {
        analysisResult?.profile.posts.count ?? Int.random(in: 80...200)
    }
    
    private var flaggedPosts: [ThreadsPost] {
        // Get posts that were specifically flagged for misogynistic content by AI
        let posts = analysisResult?.profile.posts ?? []
        let flagged = posts.filter { post in
            post.content.contains("[MISOGYNISTIC]") || post.content.contains("[FLAGGED]")
        }
        
        // Debug: Show what we're working with
        print("[DEBUG] 🔍 ProfileAnalysisView: Total posts: \(posts.count)")
        print("[DEBUG] 🔍 ProfileAnalysisView: Flagged posts found: \(flagged.count)")
        
        for (index, post) in posts.enumerated() {
            let isMarked = post.content.contains("[MISOGYNISTIC]") || post.content.contains("[FLAGGED]")
            print("[DEBUG] 🔍 Post \(index + 1) marked: \(isMarked) - \(String(post.content.prefix(60)))...")
        }
        
        return flagged
    }
    
    private var misogynyPercentage: Double {
        guard postCount > 0 else { return 0.0 }
        let percentage = Double(flaggedPosts.count) / Double(postCount) * 100
        return Double(round(percentage * 10) / 10)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "Content Tone",
                    value: contentTone,
                    bgColor: toneBackgroundColor,
                    valueColor: toneTextColor,
                    icon: toneIcon,
                    isTextValue: true
                )
                
                ProfileStatCard(
                    title: "Personality",
                    value: profile.personality,
                    bgColor: Color(hex: "f3e8ff"),
                    valueColor: Color(hex: "7c3aed"),
                    icon: "person.fill",
                    isTextValue: true
                )
            }
            
            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "Flagged Posts",
                    value: "\(flaggedPosts.count)",
                    bgColor: flaggedPosts.count > 0 ? Color(hex: "fef2f2") : Color(hex: "f0fdf4"),
                    valueColor: flaggedPosts.count > 0 ? Color(hex: "ef4444") : Color(hex: "22c55e"),
                    icon: "flag.fill"
                )
                
                ProfileStatCard(
                    title: "Misogyny %",
                    value: "\(misogynyPercentage)%",
                    bgColor: misogynyPercentage > 5 ? Color(hex: "fef2f2") : Color(hex: "f0fdf4"),
                    valueColor: misogynyPercentage > 5 ? Color(hex: "ef4444") : Color(hex: "22c55e"),
                    icon: "chart.pie.fill"
                )
            }
            
            // Interest tags
            InterestsView(interests: profile.interests)
            
            // Removed PersonalityTraitsView - personality is now shown in the stats card only
            
            // Flagged posts section (if any)
            if !flaggedPosts.isEmpty {
                FlaggedPostsView(flaggedPosts: flaggedPosts)
            }
        }
    }
    
    // Content tone styling
    private var toneBackgroundColor: Color {
        switch contentTone.lowercased() {
        case "positive": return Color(hex: "f0fdf4")
        case "negative": return Color(hex: "fef2f2")
        case "mixed": return Color(hex: "fff7ed")
        case "enthusiastic": return Color(hex: "fef3c7")
        case "calm": return Color(hex: "f0f9ff")
        case "sarcastic": return Color(hex: "f3e8ff")
        case "humorous": return Color(hex: "fef7cd")
        case "serious": return Color(hex: "f1f5f9")
        case "emotional": return Color(hex: "fce7f3")
        case "analytical": return Color(hex: "e0f2fe")
        case "creative": return Color(hex: "f3e8ff")
        case "philosophical": return Color(hex: "f8fafc")
        case "casual": return Color(hex: "f0fdf4")
        case "professional": return Color(hex: "f1f5f9")
        case "passionate": return Color(hex: "fdf2f8")
        default: return Color(hex: "f3f4f6")
        }
    }
    
    private var toneTextColor: Color {
        switch contentTone.lowercased() {
        case "positive": return Color(hex: "22c55e")
        case "negative": return Color(hex: "ef4444")
        case "mixed": return Color(hex: "f97316")
        case "enthusiastic": return Color(hex: "f59e0b")
        case "calm": return Color(hex: "0ea5e9")
        case "sarcastic": return Color(hex: "8b5cf6")
        case "humorous": return Color(hex: "eab308")
        case "serious": return Color(hex: "64748b")
        case "emotional": return Color(hex: "ec4899")
        case "analytical": return Color(hex: "06b6d4")
        case "creative": return Color(hex: "a855f7")
        case "philosophical": return Color(hex: "6b7280")
        case "casual": return Color(hex: "10b981")
        case "professional": return Color(hex: "475569")
        case "passionate": return Color(hex: "f43f5e")
        default: return Color(hex: "374151")
        }
    }
    
    private var toneIcon: String {
        switch contentTone.lowercased() {
        case "positive": return "face.smiling.fill"
        case "negative": return "face.dashed.fill"
        case "mixed": return "face.dashed"
        case "enthusiastic": return "flame.fill"
        case "calm": return "leaf.fill"
        case "sarcastic": return "eye.fill"
        case "humorous": return "theatermasks.fill"
        case "serious": return "briefcase.fill"
        case "emotional": return "heart.fill"
        case "analytical": return "chart.bar.fill"
        case "creative": return "paintbrush.fill"
        case "philosophical": return "brain.head.profile"
        case "casual": return "figure.walk"
        case "professional": return "person.badge.plus"
        case "passionate": return "bolt.heart.fill"
        default: return "face.dashed"
        }
    }
}



// MARK: - InterestsView
struct InterestsView: View {
    let interests: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "f472b6"))
                Text("Interests")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "374151"))
                Spacer()
            }
            
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text("#\(interest)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "7c3aed"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "f3e8ff"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

// MARK: - SummaryBadge
struct SummaryBadge: View {
    let isSafe: Bool
    let safetyScore: Double?
    let analysisDetails: ThreadsAnalysisDetails?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: safetyIcon)
                .foregroundColor(safetyColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(safetyTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(safetyColor)
                
                Text(safetyDescription)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6b7280"))
                
                // Show additional details if available
                if let analysisDetails = analysisDetails {
                    HStack(spacing: 8) {
                        Text("Content: \(analysisDetails.contentTone.rawValue)")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "6b7280"))
                        
                        if let score = safetyScore {
                            let misogynyScore = Int((1.0 - score) * 100)
                            Text("Misogyny: \(misogynyScore)%")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(safetyBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(safetyColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var safetyColor: Color {
        if let score = safetyScore {
            if score >= 0.8 { return Color(hex: "22c55e") }
            if score >= 0.6 { return Color(hex: "f97316") }
            return Color(hex: "ef4444")
        }
        return isSafe ? Color(hex: "22c55e") : Color(hex: "ef4444")
    }
    
    private var safetyBackgroundColor: Color {
        if let score = safetyScore {
            if score >= 0.8 { return Color(hex: "f0fdf4") }
            if score >= 0.6 { return Color(hex: "fff7ed") }
            return Color(hex: "fef2f2")
        }
        return isSafe ? Color(hex: "f0fdf4") : Color(hex: "fef2f2")
    }
    
    private var safetyIcon: String {
        if let score = safetyScore {
            if score >= 0.8 { return "checkmark.shield.fill" }
            if score >= 0.6 { return "exclamationmark.shield.fill" }
            return "xmark.shield.fill"
        }
        return isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
    }
    
    private var safetyTitle: String {
        if let score = safetyScore {
            let misogynyScore = 1.0 - score
            if misogynyScore <= 0.1 { return "Safe - No Misogyny Detected" }
            if misogynyScore <= 0.3 { return "Moderate Risk - Some Concerns" }
            return "High Risk - Misogynistic Content"
        }
        return isSafe ? "Safe User Verified" : "Potential Risk Detected"
    }
    
    private var safetyDescription: String {
        if let score = safetyScore {
            let misogynyScore = 1.0 - score
            if misogynyScore <= 0.1 { return "No misogynistic content patterns detected" }
            if misogynyScore <= 0.3 { return "Some potentially concerning language detected" }
            return "Multiple misogynistic content patterns detected"
        }
        return isSafe ? "This user passed safety verification" : "Recommend cautious interaction"
    }
}

// MARK: - NicknameInputView
struct NicknameInputView: View {
    @Binding var displayName: String
    @Binding var isNameFocused: Bool
    @FocusState.Binding var focusedField: Bool
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Nickname", text: $displayName)
                .textFieldStyle(CustomTextFieldStyle(isFocused: isNameFocused))
                .focused($focusedField)
                .onChange(of: focusedField) { newValue in
                    isNameFocused = newValue
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color(hex: "c084fc").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            .disabled(displayName.isEmpty)
        }
    }
}

// PersonalityTraitsView removed - using simple personality keyword in stats card instead

// MARK: - FlaggedPostsView
struct FlaggedPostsView: View {
    let flaggedPosts: [ThreadsPost]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "ef4444"))
                Text("Misogynistic Content Detected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "374151"))
                Spacer()
                Text("\(flaggedPosts.count) posts")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6b7280"))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(flaggedPosts.prefix(3), id: \.id) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        // Clean content for display (remove markers)
                        let cleanContent = post.content
                            .replacingOccurrences(of: "[MISOGYNISTIC]", with: "")
                            .replacingOccurrences(of: "[FLAGGED]", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .decodedUnicode
                        
                        Text(cleanContent)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "374151"))
                            .lineLimit(3)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "fef2f2"))
                            .cornerRadius(6)
                        
                        HStack {
                            Text("🚫 Misogynistic content")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "ef4444"))
                            
                            Spacer()
                            
                        }
                    }
                    
                    if post.id != flaggedPosts.prefix(3).last?.id {
                        Divider()
                            .background(Color(hex: "e5e7eb"))
                    }
                }
                
                if flaggedPosts.count > 3 {
                    Text("... and \(flaggedPosts.count - 3) more concerning posts")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "6b7280"))
                        .italic()
                }
            }
            
            // AI analysis summary
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Color(hex: "ef4444"))
                    .font(.system(size: 12))
                
                Text("AI-detected patterns suggesting potential misogynistic attitudes")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "6b7280"))
                    .italic()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "ef4444").opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

struct ProfileAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAnalysisView(
            analysisResult: nil,
            profile: UserProfile(
                userId: "user_123", 
                threadsHandle: "fake_handle",
                interests: ["Literature", "Writing", "History"],
                personality: "Introspective",
                misogynyRisk: "Safe",
                strikes: 0
            ),
            customThreadsHandle: "abcdefghijklmnop",
            onContinue: { _ in }
        )
    }
} 
