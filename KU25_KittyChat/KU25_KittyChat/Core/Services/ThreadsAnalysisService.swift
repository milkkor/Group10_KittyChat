import Foundation
import SwiftUI

// MARK: - Threads Analysis Models

struct ThreadsProfile {
    let username: String
    let displayName: String?
    let bio: String?
    let followerCount: Int?
    let followingCount: Int?
    let posts: [ThreadsPost]
    let isVerified: Bool
    let profileImageURL: String?
}

struct ThreadsPost {
    let id: String
    let content: String
    let timestamp: Date
    let likes: Int?
    let replies: Int?
    let reposts: Int?
    let mediaType: ThreadsMediaType
}

enum ThreadsMediaType {
    case text
    case image
    case video
    case carousel
}

struct ThreadsAnalysisResult {
    let profile: ThreadsProfile
    let userProfile: UserProfile
    let analysisDetails: ThreadsAnalysisDetails
}

struct ThreadsAnalysisDetails {
    let contentTone: ContentTone
    let topicAnalysis: [String: Double] // topic -> confidence score
    let riskFactors: [RiskFactor]
    let personalityTraits: [PersonalityTrait]
    let recommendedInterests: [String]
    let overallSafetyScore: Double // 0.0 - 1.0
}

enum ContentTone: String, CaseIterable {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    case mixed = "Mixed"
    case enthusiastic = "Enthusiastic"
    case calm = "Calm"
    case sarcastic = "Sarcastic"
    case humorous = "Humorous"
    case serious = "Serious"
    case emotional = "Emotional"
    case analytical = "Analytical"
    case creative = "Creative"
    case philosophical = "Philosophical"
    case casual = "Casual"
    case professional = "Professional"
    case passionate = "Passionate"
}

struct RiskFactor {
    let type: RiskType
    let severity: DetectionSeverity
    let description: String
    let examples: [String]
}

enum RiskType: String, CaseIterable {
    case misogyny = "Misogynistic Content"
    case harassment = "Harassment Patterns"
    case extremism = "Extremist Views"
    case toxicity = "Toxic Behavior"
    case none = "No Risk Detected"
}

struct PersonalityTrait {
    let trait: String
    let confidence: Double
    let description: String
}

// MARK: - Threads Analysis Service

class ThreadsAnalysisService {
    static let shared = ThreadsAnalysisService()
    
    // Cache for analysis results to avoid re-analyzing same accounts
    private var analysisCache: [String: ThreadsAnalysisResult] = [:]
    private let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    private var cacheTimestamps: [String: Date] = [:]
    
    // Token usage tracking
    private var totalTokensUsed: Int = 0
    private var totalAnalyses: Int = 0
    private var cacheHits: Int = 0
    
    private init() {}
    
    /// Main entry point for analyzing a Threads account
    /// - Parameters:
    ///   - threadsHandle: The Threads URL or username (with or without @)
    ///   - userId: The user ID for the UserProfile
    /// - Returns: Complete analysis result
    func analyzeThreadsAccount(threadsHandle: String, userId: String) async throws -> ThreadsAnalysisResult {
        print("[DEBUG] 🧵 ThreadsAnalysis: Starting analysis for input: \(threadsHandle)")
        
        // Step 1: Parse username from URL or handle
        let username = try parseUsernameFromInput(threadsHandle)
        print("[DEBUG] 🧵 ThreadsAnalysis: Extracted username: @\(username)")
        
        // Step 2: Check cache first
        if let cachedResult = checkCache(for: username, userId: userId) {
            cacheHits += 1
            print("[DEBUG] 🗄️ Using cached analysis for @\(username) (saves tokens!)")
            print("[DEBUG] 📊 Token Stats: Total: \(totalTokensUsed), Analyses: \(totalAnalyses), Cache Hits: \(cacheHits)")
            return cachedResult
        }
        
        print("[DEBUG] 💰 No cache found, performing new analysis (will consume tokens)")
        
        // Step 3: Scrape Threads profile data
        let threadsProfile = try await scrapeThreadsProfile(username: username)
        
        // Step 4: Analyze content with Gemini API
        let (analysisDetails, personality, flaggedProfile) = try await analyzeContentWithGemini(profile: threadsProfile)
        
        // Step 5: Generate UserProfile
        let userProfile = generateUserProfile(
            userId: userId,
            threadsHandle: username,
            analysisDetails: analysisDetails,
            personality: personality
        )
        
        let result = ThreadsAnalysisResult(
            profile: flaggedProfile, // Use the profile with flagged posts marked
            userProfile: userProfile,
            analysisDetails: analysisDetails
        )
        
        // Step 6: Cache the result and update stats
        cacheResult(result, for: username)
        totalAnalyses += 1
        
        // Estimate tokens used (rough calculation)
        let estimatedTokens = estimateTokenUsage(profile: threadsProfile)
        totalTokensUsed += estimatedTokens
        
        print("[DEBUG] ✅ ThreadsAnalysis: Analysis completed for @\(username)")
        print("[DEBUG] 💰 Estimated tokens used: \(estimatedTokens)")
        print("[DEBUG] 📊 Total Stats: Tokens: \(totalTokensUsed), Analyses: \(totalAnalyses), Cache Hits: \(cacheHits)")
        print("[DEBUG] 💡 Cache hit rate: \(cacheHits > 0 ? String(format: "%.1f", Double(cacheHits) / Double(cacheHits + totalAnalyses) * 100) : "0.0")%")
        
        return result
    }
    
    // MARK: - Cache Management
    
    /// Check if we have a valid cached result for this username
    private func checkCache(for username: String, userId: String) -> ThreadsAnalysisResult? {
        guard let cachedResult = analysisCache[username],
              let timestamp = cacheTimestamps[username] else {
            return nil
        }
        
        // Check if cache is still valid (within 24 hours)
        let timeElapsed = Date().timeIntervalSince(timestamp)
        if timeElapsed > cacheExpirationTime {
            // Cache expired, remove it
            analysisCache.removeValue(forKey: username)
            cacheTimestamps.removeValue(forKey: username)
            return nil
        }
        
        // Update the userId in cached result
        var updatedProfile = cachedResult.userProfile
        updatedProfile.userId = userId
        
        return ThreadsAnalysisResult(
            profile: cachedResult.profile,
            userProfile: updatedProfile,
            analysisDetails: cachedResult.analysisDetails
        )
    }
    
    /// Cache the analysis result
    private func cacheResult(_ result: ThreadsAnalysisResult, for username: String) {
        analysisCache[username] = result
        cacheTimestamps[username] = Date()
        
        // Clean up old cache entries (keep only recent 50 entries)
        if analysisCache.count > 50 {
            let sortedTimestamps = cacheTimestamps.sorted { $0.value < $1.value }
            let oldestEntries = sortedTimestamps.prefix(10) // Remove oldest 10
            
            for (usernameToRemove, _) in oldestEntries {
                analysisCache.removeValue(forKey: usernameToRemove)
                cacheTimestamps.removeValue(forKey: usernameToRemove)
            }
        }
        
        print("[DEBUG] 🗄️ Cached analysis for @\(username). Cache size: \(analysisCache.count)")
    }
    
    /// Estimate token usage for analysis
    private func estimateTokenUsage(profile: ThreadsProfile) -> Int {
        var tokenCount = 0
        
        // Bio tokens
        if let bio = profile.bio {
            tokenCount += min(200, bio.count) / 4 // Rough estimation: 4 chars = 1 token
        }
        
        // Posts tokens (max 10 posts, 280 chars each)
        let maxPosts = min(10, profile.posts.count)
        tokenCount += maxPosts * 280 / 4
        
        // Prompt tokens (fixed cost) - reduced due to simpler personality analysis
        tokenCount += 100 // Optimized prompt (was 150)
        
        // Response tokens (estimated) - reduced due to simpler JSON structure
        tokenCount += 120 // Simplified JSON response (was 200)
        
        return tokenCount
    }
    
    /// Get token usage statistics
    func getTokenStats() -> (totalTokens: Int, totalAnalyses: Int, cacheHits: Int, hitRate: Double) {
        let hitRate = cacheHits > 0 ? Double(cacheHits) / Double(cacheHits + totalAnalyses) * 100 : 0.0
        return (totalTokensUsed, totalAnalyses, cacheHits, hitRate)
    }
    
    // MARK: - URL Parsing Methods
    
    /// Parse username from various input formats (URL or username)
    /// - Parameter input: Threads URL, @username, or username
    /// - Returns: Clean username without @ symbol
    /// - Throws: ThreadsAnalysisError.invalidURL if input is invalid
    private func parseUsernameFromInput(_ input: String) throws -> String {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if input is a URL
        if trimmedInput.lowercased().contains("threads.com") {
            return try parseUsernameFromURL(trimmedInput)
        }
        
        // Check if input starts with @
        if trimmedInput.hasPrefix("@") {
            let username = String(trimmedInput.dropFirst())
            guard isValidUsername(username) else {
                throw ThreadsAnalysisError.invalidURL
            }
            return username
        }
        
        // Assume it's a plain username
        guard isValidUsername(trimmedInput) else {
            throw ThreadsAnalysisError.invalidURL
        }
        
        return trimmedInput
    }
    
    /// Parse username from Threads URL
    /// - Parameter urlString: Threads profile URL
    /// - Returns: Clean username
    /// - Throws: ThreadsAnalysisError.invalidURL if URL is invalid
    private func parseUsernameFromURL(_ urlString: String) throws -> String {
        guard let url = URL(string: urlString) else {
            throw ThreadsAnalysisError.invalidURL
        }
        
        // Expected URL format: https://www.threads.com/@username
        // or: https://threads.com/@username
        guard url.host?.contains("threads.com") == true else {
            throw ThreadsAnalysisError.invalidURL
        }
        
        let pathComponents = url.pathComponents
        
        // Look for path component starting with @
        for component in pathComponents {
            if component.hasPrefix("@") {
                let username = String(component.dropFirst())
                guard isValidUsername(username) else {
                    throw ThreadsAnalysisError.invalidURL
                }
                return username
            }
        }
        
        throw ThreadsAnalysisError.invalidURL
    }
    
    /// Validate username format
    /// - Parameter username: Username to validate
    /// - Returns: True if valid username format
    private func isValidUsername(_ username: String) -> Bool {
        // Username should be 1-30 characters, alphanumeric, underscores, dots
        let usernameRegex = "^[a-zA-Z0-9._]{1,30}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    // MARK: - Testing Helpers
    
    /// Test URL parsing functionality (for debugging)
    static func testURLParsing() {
        let testCases = [
            "https://www.threads.com/@zuck",
            "https://threads.com/@instagram",
            "@username123",
            "simple_username",
            "test.user",
            "https://www.threads.com/@test_user.123"
        ]
        
        let service = ThreadsAnalysisService.shared
        
        print("[DEBUG] 🧪 Testing URL parsing...")
        
        for testCase in testCases {
            do {
                let username = try service.parseUsernameFromInput(testCase)
                print("[DEBUG] ✅ '\(testCase)' → '@\(username)'")
            } catch {
                print("[DEBUG] ❌ '\(testCase)' → Error: \(error.localizedDescription)")
            }
        }
        
        print("[DEBUG] 🧪 URL parsing test completed")
    }
    
    // MARK: - Web Scraping Methods
    
    /// Scrape Threads profile using web scraping techniques
    private func scrapeThreadsProfile(username: String) async throws -> ThreadsProfile {
        let cleanUsername = username.replacingOccurrences(of: "@", with: "")
        let profileURL = "https://www.threads.com/@\(cleanUsername)"
        
        print("[DEBUG] 🌐 ThreadsAnalysis: Scraping profile: \(profileURL)")
        
        // Note: This is a simplified implementation
        // In production, you'd need to handle:
        // 1. User-Agent headers
        // 2. Rate limiting
        // 3. CAPTCHA handling
        // 4. JavaScript rendering (if needed)
        
        guard let url = URL(string: profileURL) else {
            throw ThreadsAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ThreadsAnalysisError.profileNotFound
        }
        
        print("[DEBUG] 🌐 HTTP Response Status: \(httpResponse.statusCode)")
        print("[DEBUG] 🌐 Response Headers: \(httpResponse.allHeaderFields)")
        
        guard httpResponse.statusCode == 200 else {
            print("[DEBUG] ❌ Non-200 status code: \(httpResponse.statusCode)")
            throw ThreadsAnalysisError.profileNotFound
        }
        
        let html = String(data: data, encoding: .utf8) ?? ""
        
        // Debug: Show HTML analysis
        analyzeHTMLContent(html: html, username: cleanUsername)
        
        // Parse HTML content (simplified implementation)
        let profile = parseThreadsHTML(html: html, username: cleanUsername)
        
        return profile
    }
    
    /// Parse HTML content to extract profile information
    private func parseThreadsHTML(html: String, username: String) -> ThreadsProfile {
        // This is a simplified parser
        // In production, you'd use a proper HTML parser like SwiftSoup
        
        var posts: [ThreadsPost] = []
        
        // Extract basic profile info using regex or string matching
        let displayName = extractDisplayName(from: html)
        let bio = extractBio(from: html)
        let isVerified = html.contains("verified") || html.contains("checkmark")
        
        // Try to extract real posts from HTML
        posts = extractPostsFromHTML(html: html)
        
        // If no real posts found, fallback to mock data for demo
        if posts.isEmpty {
            print("[DEBUG] ⚠️ No real posts extracted, using mock data for demo")
            posts = generateMockPosts(for: username)
        } else {
            print("[DEBUG] ✅ Successfully extracted \(posts.count) real posts from HTML")
        }
        
        return ThreadsProfile(
            username: username,
            displayName: displayName,
            bio: bio,
            followerCount: nil, // Would extract from HTML
            followingCount: nil, // Would extract from HTML
            posts: posts,
            isVerified: isVerified,
            profileImageURL: nil // Would extract from HTML
        )
    }
    
    // MARK: - Gemini Analysis Methods
    
    /// Analyze Threads content using Gemini API
    private func analyzeContentWithGemini(profile: ThreadsProfile) async throws -> (ThreadsAnalysisDetails, String, ThreadsProfile) {
        print("[DEBUG] 🤖 ThreadsAnalysis: Analyzing content with Gemini API")
        
        // Prepare content for analysis
        let contentToAnalyze = prepareContentForAnalysis(profile: profile)
        
        // Create comprehensive analysis prompt
        let analysisPrompt = createAnalysisPrompt(content: contentToAnalyze, username: profile.username)
        
        // Call Gemini API
        let geminiResult = try await callGeminiForAnalysis(prompt: analysisPrompt)
        
        // Parse Gemini response into structured data
        let (analysisDetails, personality, flaggedPostNumbers) = parseGeminiAnalysisResult(geminiResult)
        
        // Mark flagged posts in the profile
        let updatedProfile = markFlaggedPosts(profile: profile, flaggedPostNumbers: flaggedPostNumbers)
        
        return (analysisDetails, personality, updatedProfile)
    }
    
    /// Prepare content from Threads profile for analysis (optimized for token usage)
    private func prepareContentForAnalysis(profile: ThreadsProfile) -> String {
        var content = ""
        
        // Add bio if available (limit length)
        if let bio = profile.bio {
            let trimmedBio = String(bio.prefix(200)) // Max 200 chars
            content += "Bio: \(trimmedBio)\n\n"
        }
        
        // Add recent posts (limit count and length)
        content += "Recent Posts:\n"
        let maxPosts = 10 // Reduce from 20 to 10
        let maxPostLength = 280 // Twitter-like limit
        
        for (index, post) in profile.posts.prefix(maxPosts).enumerated() {
            let trimmedPost = String(post.content.prefix(maxPostLength))
            content += "\(index + 1). \(trimmedPost)\n"
        }
        
        print("[DEBUG] 💰 Token Optimization:")
        print("[DEBUG]   - Bio length: \(profile.bio?.count ?? 0) → \(profile.bio != nil ? min(200, profile.bio!.count) : 0)")
        print("[DEBUG]   - Posts included: \(profile.posts.count) → \(min(maxPosts, profile.posts.count))")
        print("[DEBUG]   - Total content length: \(content.count) characters")
        print("[DEBUG]   - Estimated tokens: ~\(content.count / 4)")
        
        return content
    }
    
    /// Create optimized analysis prompt for Gemini (reduced token usage)
    private func createAnalysisPrompt(content: String, username: String) -> String {
        return """
        Analyze @\(username) for misogynistic content detection. Check each numbered post for gender-based discrimination, objectification, or hostile attitudes toward women.
        
        \(content)
        
        Return JSON:
        {
            "contentTone": "positive/neutral/negative/mixed/enthusiastic/calm/sarcastic/humorous/serious/emotional/analytical/creative/philosophical/casual/professional/passionate",
            "personality": "Creative/Analytical/Outgoing/Reserved/Empathetic/Confident/Curious/Practical/etc",
            "interests": ["interest1", "interest2", "interest3"],
            "flaggedPostNumbers": [1, 3],
            "misogynyScore": 0.15,
            "misogynyRisk": "Safe/Moderate/High",
            "flagReasons": ["objectification", "gender stereotyping", "hostile language"]
        }
        
        Misogyny detection criteria:
        - Objectification of women
        - Gender-based insults or slurs
        - Stereotyping women negatively  
        - Dismissive attitudes toward women's capabilities
        - Sexual harassment or inappropriate comments
        - "Red pill" or incel ideology
        
        misogynyScore: 0.0-1.0 (percentage of posts with misogynistic content)
        flaggedPostNumbers: array of post numbers (1, 2, 3, etc.) that contain misogyny
        
        Focus: misogyny detection, personality, interests, content tone.
        """
    }
    
    /// Call Gemini API for analysis using the centralized GeminiService
    private func callGeminiForAnalysis(prompt: String) async throws -> String {
        print("[DEBUG] 🤖 ThreadsAnalysis: Using centralized GeminiService for API call")
        
        do {
            // Use the centralized GeminiService to make the API call
            return try await GeminiService.shared.callGeminiAPI(prompt: prompt)
        } catch let error as GeminiError {
            // Convert GeminiError to ThreadsAnalysisError
            print("[DEBUG] ❌ ThreadsAnalysis: Gemini API error: \(error.localizedDescription)")
            throw ThreadsAnalysisError.analysisAPIError
        } catch {
            // Handle other errors
            print("[DEBUG] ❌ ThreadsAnalysis: Unexpected error: \(error)")
            throw ThreadsAnalysisError.analysisAPIError
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parse Gemini analysis result into structured data
    private func parseGeminiAnalysisResult(_ jsonText: String) -> (ThreadsAnalysisDetails, String, [Int]) {
        // Extract JSON from response
        let jsonString = extractJSONFromText(jsonText)
        
        print("[DEBUG] 🤖 Gemini Analysis Result:")
        print("[DEBUG] Raw JSON: \(jsonString)")
        
        guard let jsonData = jsonString.data(using: .utf8),
              let analysisData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("[DEBUG] ❌ Failed to parse Gemini response, using default analysis")
            return (createDefaultAnalysisDetails(), "Friendly", [])
        }
        
        print("[DEBUG] 📊 Parsed Analysis Data:")
        print("[DEBUG] Content Tone: \(analysisData["contentTone"] as? String ?? "unknown")")
        print("[DEBUG] Misogyny Score: \(analysisData["misogynyScore"] as? Double ?? 0.0)")
        print("[DEBUG] Interests: \(analysisData["interests"] as? [String] ?? [])")
        print("[DEBUG] Misogyny Risk: \(analysisData["misogynyRisk"] as? String ?? "unknown")")
        print("[DEBUG] Personality: \(analysisData["personality"] as? String ?? "unknown")")
        print("[DEBUG] Flagged Post Numbers: \(analysisData["flaggedPostNumbers"] as? [Int] ?? [])")
        
        // Parse each component
        let contentTone = ContentTone(rawValue: analysisData["contentTone"] as? String ?? "neutral") ?? .neutral
        let misogynyScore = analysisData["misogynyScore"] as? Double ?? 0.0
        let interests = analysisData["interests"] as? [String] ?? []
        let personality = analysisData["personality"] as? String ?? "Friendly"
        let flaggedPostNumbers = analysisData["flaggedPostNumbers"] as? [Int] ?? []
        
        // Create risk factors based on misogyny detection
        var riskFactors: [RiskFactor] = []
        if misogynyScore > 0.1 {
            let severity: DetectionSeverity = misogynyScore > 0.3 ? .high : misogynyScore > 0.15 ? .medium : .low
            riskFactors.append(RiskFactor(
                type: .misogyny,
                severity: severity,
                description: "AI detected potential misogynistic content patterns",
                examples: flaggedPostNumbers.map { "Post #\($0)" }
            ))
        }
        
        // Create topic analysis from interests
        var topicAnalysis: [String: Double] = [:]
        for interest in interests {
            topicAnalysis[interest] = 0.8 // Default confidence
        }
        
        let analysisDetails = ThreadsAnalysisDetails(
            contentTone: contentTone,
            topicAnalysis: topicAnalysis,
            riskFactors: riskFactors,
            personalityTraits: [], // Empty array since we now use simple personality keyword
            recommendedInterests: interests,
            overallSafetyScore: 1.0 - misogynyScore // Safety score inversely related to misogyny score
        )
        
        return (analysisDetails, personality, flaggedPostNumbers)
    }
    
    /// Extract JSON from text response
    private func extractJSONFromText(_ text: String) -> String {
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
    
    // parsePersonalityTraits method removed - now using simple personality keyword
    
    /// Mark posts that were flagged for misogynistic content (using AI-provided post numbers)
    private func markFlaggedPosts(profile: ThreadsProfile, flaggedPostNumbers: [Int]) -> ThreadsProfile {
        print("[DEBUG] 🚩 Marking posts using AI-provided indices: \(flaggedPostNumbers)")
        print("[DEBUG] 🚩 Original posts count: \(profile.posts.count)")
        
        var updatedPosts = profile.posts
        var markedCount = 0
        
        // Debug: Show all posts
        for (index, post) in profile.posts.enumerated() {
            print("[DEBUG] 📝 Post \(index + 1): \(String(post.content.prefix(100)))...")
        }
        
        // Mark posts based on AI-provided indices (convert from 1-based to 0-based indexing)
        for postNumber in flaggedPostNumbers {
            let arrayIndex = postNumber - 1 // Convert from 1-based to 0-based
            
            if arrayIndex >= 0 && arrayIndex < updatedPosts.count {
                let post = updatedPosts[arrayIndex]
                
                // Mark this post as flagged by adding a marker
                updatedPosts[arrayIndex] = ThreadsPost(
                    id: post.id,
                    content: "[MISOGYNISTIC] \(post.content)",
                    timestamp: post.timestamp,
                    likes: post.likes,
                    replies: post.replies,
                    reposts: post.reposts,
                    mediaType: post.mediaType
                )
                
                markedCount += 1
                print("[DEBUG] ✅ Successfully flagged post #\(postNumber) (index \(arrayIndex))")
                print("[DEBUG] ✅ Content: \(String(post.content.prefix(50)))...")
            } else {
                print("[DEBUG] ❌ Invalid post number: \(postNumber) (index \(arrayIndex) out of bounds)")
            }
        }
        
        print("[DEBUG] 🚩 Successfully marked \(markedCount) out of \(flaggedPostNumbers.count) flagged posts")
        
        return ThreadsProfile(
            username: profile.username,
            displayName: profile.displayName,
            bio: profile.bio,
            followerCount: profile.followerCount,
            followingCount: profile.followingCount,
            posts: updatedPosts,
            isVerified: profile.isVerified,
            profileImageURL: profile.profileImageURL
        )
    }
    
    // Removed complex text matching methods - now using AI-provided post indices directly
    
    /// Parse risk factors from JSON data
    private func parseRiskFactors(from data: [[String: Any]]) -> [RiskFactor] {
        return data.compactMap { riskData in
            guard let typeString = riskData["type"] as? String,
                  let type = RiskType(rawValue: typeString),
                  let severityString = riskData["severity"] as? String,
                  let description = riskData["description"] as? String else {
                return nil
            }
            
            let severity = DetectionSeverity.fromString(severityString)
            let examples = riskData["examples"] as? [String] ?? []
            
            return RiskFactor(
                type: type,
                severity: severity,
                description: description,
                examples: examples
            )
        }
    }
    
    /// Generate UserProfile from analysis results
    private func generateUserProfile(userId: String, threadsHandle: String, analysisDetails: ThreadsAnalysisDetails, personality: String) -> UserProfile {
        let interests = Array(analysisDetails.recommendedInterests.prefix(5))
        
        // Use the personality directly from Gemini analysis
        let mainPersonality = personality
        
        // Determine misogyny risk based on AI analysis
        let misogynyRisk: String
        let misogynyScore = 1.0 - analysisDetails.overallSafetyScore // Extract misogyny score
        
        if misogynyScore > 0.3 {
            misogynyRisk = "High"
        } else if misogynyScore > 0.15 {
            misogynyRisk = "Moderate"
        } else {
            misogynyRisk = "Safe"
        }
        
        let userProfile = UserProfile(
            userId: userId,
            threadsHandle: threadsHandle,
            interests: interests,
            personality: mainPersonality,
            misogynyRisk: misogynyRisk,
            strikes: 0
        )
        
        print("[DEBUG] 📝 Generated User Profile:")
        print("[DEBUG] User ID: \(userProfile.userId)")
        print("[DEBUG] Threads Handle: @\(userProfile.threadsHandle)")
        print("[DEBUG] Interests: \(userProfile.interests)")
        print("[DEBUG] Personality: \(userProfile.personality)")
        print("[DEBUG] Misogyny Risk: \(userProfile.misogynyRisk)")
        print("[DEBUG] Strikes: \(userProfile.strikes)")
        
        print("[DEBUG] 🔍 Detailed Analysis:")
        print("[DEBUG] Content Tone: \(analysisDetails.contentTone.rawValue)")
        print("[DEBUG] Overall Safety Score: \(analysisDetails.overallSafetyScore)")
        print("[DEBUG] Misogyny Score: \(1.0 - analysisDetails.overallSafetyScore)")
        print("[DEBUG] Risk Factors Count: \(analysisDetails.riskFactors.count)")
        
        if !analysisDetails.riskFactors.isEmpty {
            print("[DEBUG] ⚠️ Risk Factors:")
            for risk in analysisDetails.riskFactors {
                print("[DEBUG]   - \(risk.type.rawValue): \(risk.severity) - \(risk.description)")
                if !risk.examples.isEmpty {
                    print("[DEBUG]     Flagged posts: \(risk.examples.joined(separator: ", "))")
                }
            }
        } else {
            print("[DEBUG] ✅ No misogynistic content detected")
        }
        
        return userProfile
    }
    
    /// Create default analysis details for fallback
    private func createDefaultAnalysisDetails() -> ThreadsAnalysisDetails {
        return ThreadsAnalysisDetails(
            contentTone: .neutral,
            topicAnalysis: [:],
            riskFactors: [],
            personalityTraits: [],
            recommendedInterests: [],
            overallSafetyScore: 0.5
        )
    }
    
    // MARK: - Mock Data Generation (for testing)
    
    /// Generate mock posts for testing (when real content cannot be extracted)
    private func generateMockPosts(for username: String) -> [ThreadsPost] {
        print("[DEBUG] 🎭 ThreadsAnalysis: Using mock data for @\(username) - could not extract real posts")
        
        return [
            ThreadsPost(
                id: "mock_1",
                content: "[DEMO DATA] Just finished a great design project! Love creating user-friendly interfaces.",
                timestamp: Date().addingTimeInterval(-86400),
                likes: 15,
                replies: 3,
                reposts: 1,
                mediaType: .text
            ),
            ThreadsPost(
                id: "mock_2", 
                content: "[DEMO DATA] Coffee and coding - perfect Sunday morning ☕️",
                timestamp: Date().addingTimeInterval(-172800),
                likes: 8,
                replies: 2,
                reposts: 0,
                mediaType: .text
            ),
            ThreadsPost(
                id: "mock_3",
                content: "[DEMO DATA] Working on some exciting new features. Can't wait to share!",
                timestamp: Date().addingTimeInterval(-259200),
                likes: 22,
                replies: 5,
                reposts: 2,
                mediaType: .text
            )
        ]
    }
    
    // MARK: - HTML Parsing Helpers
    
    /// Analyze HTML content for debugging
    private func analyzeHTMLContent(html: String, username: String) {
        print("[DEBUG] 📊 HTML Analysis for @\(username):")
        print("[DEBUG]   - Total size: \(html.count) characters")
        print("[DEBUG]   - Contains 'threads': \(html.contains("threads"))")
        print("[DEBUG]   - Contains '@\(username)': \(html.contains("@\(username)"))")
        print("[DEBUG]   - Contains 'posts': \(html.lowercased().contains("posts"))")
        print("[DEBUG]   - Contains JSON data: \(html.contains("{") && html.contains("}"))")
        print("[DEBUG]   - Contains script tags: \(html.contains("<script"))")
        
        // Show first 200 characters of HTML for inspection
        let preview = String(html.prefix(200))
        print("[DEBUG]   - HTML preview: \(preview)...")
    }
    
    /// Extract posts from Threads HTML content
    private func extractPostsFromHTML(html: String) -> [ThreadsPost] {
        var posts: [ThreadsPost] = []
        
        print("[DEBUG] 🔍 ThreadsAnalysis: Attempting to extract posts from HTML")
        print("[DEBUG] 📄 HTML length: \(html.count) characters")
        
        // Look for common patterns in Threads HTML
        // Note: This is a basic implementation - Threads uses dynamic loading
        // which makes scraping challenging
        
        // Try to find text content patterns
        let postPatterns = [
            // Look for content within script tags (React data)
            "\"text\":\"([^\"]+)\"",
            // Look for aria-label or text content
            "aria-label=\"([^\"]+)\"",
            // Look for content in data attributes
            "data-text=\"([^\"]+)\""
        ]
        
        for pattern in postPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                
                for match in matches.prefix(10) { // Limit to first 10 matches
                    if let range = Range(match.range(at: 1), in: html) {
                        let content = String(html[range])
                        
                        // Filter out obvious non-post content
                        if isValidPostContent(content) {
                            let post = ThreadsPost(
                                id: UUID().uuidString,
                                content: content,
                                timestamp: Date().addingTimeInterval(-Double.random(in: 0...7*24*3600)), // Random within week
                                likes: Int.random(in: 0...100),
                                replies: Int.random(in: 0...20),
                                reposts: Int.random(in: 0...10),
                                mediaType: .text
                            )
                            posts.append(post)
                        }
                    }
                }
                
                if !posts.isEmpty {
                    print("[DEBUG] ✅ Found \(posts.count) posts using pattern: \(pattern)")
                    break // Use first successful pattern
                }
            } catch {
                print("[DEBUG] ❌ Regex error for pattern \(pattern): \(error)")
            }
        }
        
        // If still no posts, try simpler text extraction
        if posts.isEmpty {
            posts = extractPostsByTextAnalysis(html: html)
        }
        
        return posts
    }
    
    /// Validate if extracted text looks like a real post
    private func isValidPostContent(_ content: String) -> Bool {
        // Filter out common UI elements and short content
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip if too short or looks like UI text
        guard cleaned.count > 10 && cleaned.count < 500 else { return false }
        
        // Skip common UI elements
        let skipPatterns = [
            "follow", "following", "followers", "posts", "replies",
            "share", "like", "comment", "menu", "profile",
            "settings", "privacy", "help", "about"
        ]
        
        let lowercased = cleaned.lowercased()
        for pattern in skipPatterns {
            if lowercased == pattern || lowercased.hasPrefix(pattern + " ") {
                return false
            }
        }
        
        return true
    }
    
    /// Alternative method to extract posts by analyzing text content
    private func extractPostsByTextAnalysis(html: String) -> [ThreadsPost] {
        var posts: [ThreadsPost] = []
        
        // Split HTML into potential text blocks
        let lines = html.components(separatedBy: .newlines)
        var potentialPosts: [String] = []
        
        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if isValidPostContent(cleaned) {
                potentialPosts.append(cleaned)
            }
        }
        
        // Take first few valid posts
        for (index, content) in potentialPosts.prefix(5).enumerated() {
            let post = ThreadsPost(
                id: "extracted_\(index)",
                content: content,
                timestamp: Date().addingTimeInterval(-Double(index * 3600)), // 1 hour apart
                likes: Int.random(in: 0...50),
                replies: Int.random(in: 0...10),
                reposts: Int.random(in: 0...5),
                mediaType: .text
            )
            posts.append(post)
        }
        
        print("[DEBUG] 📝 Extracted \(posts.count) posts by text analysis")
        return posts
    }
    
    private func extractDisplayName(from html: String) -> String? {
        // Try to extract display name using regex
        let patterns = [
            "\"display_name\":\"([^\"]+)\"",
            "\"name\":\"([^\"]+)\"",
            "<title>([^@]+)\\(@[^)]+\\)",
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let name = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty && name.count < 50 {
                        return name
                    }
                }
            } catch {
                continue
            }
        }
        return nil
    }
    
    private func extractBio(from html: String) -> String? {
        // Try to extract bio using regex
        let patterns = [
            "\"biography\":\"([^\"]+)\"",
            "\"bio\":\"([^\"]+)\"",
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let bio = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !bio.isEmpty && bio.count < 200 {
                        return bio
                    }
                }
            } catch {
                continue
            }
        }
        return nil
    }
}



// MARK: - ThreadsAnalysisError

enum ThreadsAnalysisError: Error, LocalizedError {
    case invalidURL
    case invalidUsername
    case profileNotFound
    case privateProfile
    case analysisAPIError
    case noAnalysisContent
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Threads profile URL. Please use format: https://www.threads.com/@username"
        case .invalidUsername:
            return "Invalid username format. Username should contain only letters, numbers, underscores, and dots."
        case .profileNotFound:
            return "Threads profile not found or may be private"
        case .privateProfile:
            return "This Threads profile is private"
        case .analysisAPIError:
            return "Failed to analyze profile content"
        case .noAnalysisContent:
            return "No content available for analysis"
        case .parsingError:
            return "Failed to parse profile data"
        }
    }
} 
