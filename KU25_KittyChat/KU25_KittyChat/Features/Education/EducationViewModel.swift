import Foundation
import SwiftUI
import Combine
import SendbirdChatSDK

class EducationViewModel: ObservableObject {
    @Published var modules: [EducationModule] = []
    @Published var userProgress: UserProgress?
    @Published var currentModule: EducationModule?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let progressManager = EducationProgressManager()
    
    init() {
        loadModules()
        loadUserProgress()
    }
    
    // MARK: - Computed Properties
    
    var completedModules: Int {
        return userProgress?.completedModules.count ?? 0
    }
    
    var totalModules: Int {
        return modules.count
    }
    
    var progressPercentage: Double {
        guard totalModules > 0 else { return 0 }
        return Double(completedModules) / Double(totalModules)
    }
    
    var quickTips: [String] {
        return [
            "Think before you send - consider how your message might be received",
            "Use 'I' statements to express your feelings without blaming others",
            "Ask questions to understand others' perspectives better",
            "Take breaks during heated conversations to cool down",
            "Remember that tone doesn't always translate well in text"
        ]
    }
    
    var resources: [EducationResource] {
        return [
            EducationResource(
                id: "1",
                title: "Digital Communication Guide",
                description: "Best practices for online communication",
                iconName: "book.fill",
                url: URL(string: "https://example.com/digital-communication")!,
                type: .article
            ),
            EducationResource(
                id: "2",
                title: "Conflict Resolution Skills",
                description: "Learn how to handle disagreements constructively",
                iconName: "hand.raised.fill",
                url: URL(string: "https://example.com/conflict-resolution")!,
                type: .video
            ),
            EducationResource(
                id: "3",
                title: "Emotional Intelligence",
                description: "Understanding and managing emotions in communication",
                iconName: "brain.head.profile",
                url: URL(string: "https://example.com/emotional-intelligence")!,
                type: .article
            )
        ]
    }
    
    // MARK: - Public Methods
    
    func isModuleCompleted(_ moduleId: String) -> Bool {
        return userProgress?.completedModules.contains(moduleId) ?? false
    }
    
    func isLessonCompleted(_ lessonId: String) -> Bool {
        return userProgress?.completedLessons.contains(lessonId) ?? false
    }
    
    func completeModule(_ moduleId: String) {
        guard var progress = userProgress else { return }
        progress.completedModules.insert(moduleId)
        progress.lastAccessed = Date()
        userProgress = progress
        saveUserProgress()
    }
    
    func completeLesson(_ lessonId: String) {
        guard var progress = userProgress else { return }
        progress.completedLessons.insert(lessonId)
        progress.lastAccessed = Date()
        userProgress = progress
        saveUserProgress()
    }
    
    func recordQuizScore(_ moduleId: String, score: Int) {
        guard var progress = userProgress else { return }
        progress.quizScores[moduleId] = score
        userProgress = progress
        saveUserProgress()
    }
    
    func openResource(_ resource: EducationResource) {
        UIApplication.shared.open(resource.url)
    }
    
    // MARK: - Private Methods
    
    private func loadModules() {
        modules = EducationContentManager.shared.getAllModules()
    }
    
    private func loadUserProgress() {
        guard let currentUser = getCurrentUserId() else { return }
        
        progressManager.loadProgress(for: currentUser) { [weak self] progress in
            DispatchQueue.main.async {
                self?.userProgress = progress
            }
        }
    }
    
    private func saveUserProgress() {
        guard let progress = userProgress else { return }
        
        progressManager.saveProgress(progress) { [weak self] success in
            if !success {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to save progress"
                }
            }
        }
    }
    
    private func getCurrentUserId() -> String? {
        // Get current user ID from Sendbird or your user management system
        return SendbirdChat.getCurrentUser()?.userId
    }
}

// MARK: - Education Content Manager

class EducationContentManager {
    static let shared = EducationContentManager()
    
    private init() {}
    
    func getAllModules() -> [EducationModule] {
        return [
            createAIGuardianModule(),
            createCommunicationModule(),
            createSafetyModule(),
            createPsychologyModule()
        ]
    }
    
    private func createAIGuardianModule() -> EducationModule {
        return EducationModule(
            id: "ai_guardian_101",
            title: "Understanding AI Guardian",
            description: "Learn how AI Guardian works to protect users and maintain a safe environment.",
            iconName: "shield.fill",
            duration: 15,
            difficulty: .beginner,
            lessons: [
                EducationLesson(
                    id: "ai_lesson_1",
                    title: "What is AI Guardian?",
                    content: "AI Guardian is an advanced safety system that uses artificial intelligence to detect potentially harmful or inappropriate content in real-time. It works by analyzing messages for patterns that might indicate misogyny, harassment, or other forms of harmful communication.",
                    type: .text,
                    duration: 5,
                    interactiveElements: [],
                    quiz: nil
                ),
                EducationLesson(
                    id: "ai_lesson_2",
                    title: "How Detection Works",
                    content: "The system uses multiple detection methods: 1) Local keyword-based detection for immediate response, 2) Advanced AI analysis using Google Gemini for context-aware understanding, 3) Bidirectional interaction system that involves both sender and receiver in the safety process.",
                    type: .text,
                    duration: 8,
                    interactiveElements: [
                        InteractiveElement(
                            id: "interactive_1",
                            type: .scenario,
                            content: "Imagine you're about to send a message. What would you do if AI Guardian flags it?",
                            options: ["Retract the message", "Edit it", "Send it anyway"],
                            correctAnswer: "Edit it",
                            feedback: "Great choice! Editing allows you to express yourself while being mindful of others."
                        )
                    ],
                    quiz: nil
                )
            ],
            category: .aiGuardian
        )
    }
    
    private func createCommunicationModule() -> EducationModule {
        return EducationModule(
            id: "communication_skills",
            title: "Effective Communication",
            description: "Master the art of clear, respectful, and empathetic communication.",
            iconName: "message.fill",
            duration: 20,
            difficulty: .intermediate,
            lessons: [
                EducationLesson(
                    id: "comm_lesson_1",
                    title: "Active Listening",
                    content: "Active listening involves fully concentrating on what the other person is saying, understanding their message, and responding thoughtfully. It's about being present and showing genuine interest in their perspective.",
                    type: .text,
                    duration: 7,
                    interactiveElements: [],
                    quiz: nil
                ),
                EducationLesson(
                    id: "comm_lesson_2",
                    title: "Nonviolent Communication",
                    content: "Nonviolent Communication (NVC) is a method that helps people communicate more effectively by focusing on observations, feelings, needs, and requests. It promotes empathy and understanding.",
                    type: .text,
                    duration: 10,
                    interactiveElements: [
                        InteractiveElement(
                            id: "interactive_2",
                            type: .multipleChoice,
                            content: "Which of the following is an example of nonviolent communication?",
                            options: [
                                "You're always late!",
                                "I feel frustrated when meetings start late because I value punctuality. Could we start on time?",
                                "Stop being so inconsiderate"
                            ],
                            correctAnswer: "I feel frustrated when meetings start late because I value punctuality. Could we start on time?",
                            feedback: "Correct! This statement expresses feelings, identifies needs, and makes a clear request."
                        )
                    ],
                    quiz: createCommunicationQuiz()
                )
            ],
            category: .communication
        )
    }
    
    private func createSafetyModule() -> EducationModule {
        return EducationModule(
            id: "online_safety",
            title: "Online Safety & Boundaries",
            description: "Learn how to maintain healthy boundaries and stay safe in digital spaces.",
            iconName: "lock.shield.fill",
            duration: 18,
            difficulty: .beginner,
            lessons: [
                EducationLesson(
                    id: "safety_lesson_1",
                    title: "Setting Digital Boundaries",
                    content: "Setting boundaries in digital spaces is crucial for maintaining healthy relationships and protecting your mental health. This includes knowing when to disconnect, what information to share, and how to respond to uncomfortable situations.",
                    type: .text,
                    duration: 8,
                    interactiveElements: [],
                    quiz: nil
                ),
                EducationLesson(
                    id: "safety_lesson_2",
                    title: "Recognizing Red Flags",
                    content: "Learn to identify warning signs in online interactions, such as excessive control, manipulation, or inappropriate requests. Trust your instincts and don't hesitate to block or report concerning behavior.",
                    type: .text,
                    duration: 10,
                    interactiveElements: [
                        InteractiveElement(
                            id: "interactive_3",
                            type: .trueFalse,
                            content: "It's okay to share personal information with someone you just met online if they seem nice.",
                            options: ["True", "False"],
                            correctAnswer: "False",
                            feedback: "Correct! Always be cautious about sharing personal information with people you don't know well."
                        )
                    ],
                    quiz: createSafetyQuiz()
                )
            ],
            category: .safety
        )
    }
    
    private func createPsychologyModule() -> EducationModule {
        return EducationModule(
            id: "psychology_communication",
            title: "Psychology of Communication",
            description: "Understand the psychological aspects of human communication and relationships.",
            iconName: "brain.head.profile",
            duration: 25,
            difficulty: .advanced,
            lessons: [
                EducationLesson(
                    id: "psych_lesson_1",
                    title: "Emotional Intelligence",
                    content: "Emotional intelligence involves understanding and managing your own emotions while also being able to recognize and respond to the emotions of others. It's a key skill for effective communication.",
                    type: .text,
                    duration: 12,
                    interactiveElements: [],
                    quiz: nil
                ),
                EducationLesson(
                    id: "psych_lesson_2",
                    title: "Cognitive Biases in Communication",
                    content: "We all have cognitive biases that can affect how we communicate and interpret messages. Understanding these biases helps us communicate more effectively and avoid misunderstandings.",
                    type: .text,
                    duration: 13,
                    interactiveElements: [],
                    quiz: createPsychologyQuiz()
                )
            ],
            category: .psychology
        )
    }
    
    // MARK: - Quiz Creators
    
    private func createCommunicationQuiz() -> Quiz {
        return Quiz(
            id: "comm_quiz",
            title: "Communication Skills Quiz",
            questions: [
                QuizQuestion(
                    id: "q1",
                    question: "What is the first step in active listening?",
                    options: ["Prepare your response", "Focus on the speaker", "Take notes", "Ask questions"],
                    correctAnswer: 1,
                    explanation: "The first step is to focus on the speaker and give them your full attention."
                ),
                QuizQuestion(
                    id: "q2",
                    question: "Which communication style is most effective for resolving conflicts?",
                    options: ["Aggressive", "Passive", "Assertive", "Passive-aggressive"],
                    correctAnswer: 2,
                    explanation: "Assertive communication respects both your own needs and the needs of others."
                )
            ],
            passingScore: 1
        )
    }
    
    private func createSafetyQuiz() -> Quiz {
        return Quiz(
            id: "safety_quiz",
            title: "Online Safety Quiz",
            questions: [
                QuizQuestion(
                    id: "q1",
                    question: "What should you do if someone makes you uncomfortable online?",
                    options: ["Ignore it", "Block and report them", "Confront them aggressively", "Share it publicly"],
                    correctAnswer: 1,
                    explanation: "Blocking and reporting is the safest way to handle uncomfortable situations."
                )
            ],
            passingScore: 1
        )
    }
    
    private func createPsychologyQuiz() -> Quiz {
        return Quiz(
            id: "psych_quiz",
            title: "Psychology Quiz",
            questions: [
                QuizQuestion(
                    id: "q1",
                    question: "What is emotional intelligence?",
                    options: ["Being emotional", "Understanding emotions", "Controlling others' emotions", "Avoiding emotions"],
                    correctAnswer: 1,
                    explanation: "Emotional intelligence involves understanding and managing emotions effectively."
                )
            ],
            passingScore: 1
        )
    }
} 