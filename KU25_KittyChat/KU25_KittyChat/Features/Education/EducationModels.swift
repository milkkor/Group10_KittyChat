import Foundation
import SwiftUI

// MARK: - Education Module

struct EducationModule: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let duration: Int // in minutes
    let difficulty: ModuleDifficulty
    let lessons: [EducationLesson]
    let category: ModuleCategory
    
    static func == (lhs: EducationModule, rhs: EducationModule) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ModuleDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum ModuleCategory: String, CaseIterable {
    case aiGuardian = "AI Guardian"
    case communication = "Communication"
    case safety = "Safety"
    case psychology = "Psychology"
}

// MARK: - Education Lesson

struct EducationLesson: Identifiable {
    let id: String
    let title: String
    let content: String
    let type: LessonType
    let duration: Int // in minutes
    let interactiveElements: [InteractiveElement]
    let quiz: Quiz?
}

enum LessonType {
    case text
    case video
    case interactive
    case quiz
}

// MARK: - Interactive Elements

struct InteractiveElement: Identifiable {
    let id: String
    let type: InteractiveType
    let content: String
    let options: [String]?
    let correctAnswer: String?
    let feedback: String?
}

enum InteractiveType {
    case multipleChoice
    case trueFalse
    case scenario
    case reflection
}

// MARK: - Quiz

struct Quiz: Identifiable {
    let id: String
    let title: String
    let questions: [QuizQuestion]
    let passingScore: Int
}

struct QuizQuestion: Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

// MARK: - Resource

struct EducationResource: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let url: URL
    let type: ResourceType
}

enum ResourceType {
    case article
    case video
    case website
    case document
}

// MARK: - User Progress

struct UserProgress: Codable {
    let userId: String
    var completedModules: Set<String>
    var completedLessons: Set<String>
    var quizScores: [String: Int] // moduleId: score
    var lastAccessed: Date
    var totalTimeSpent: TimeInterval
    
    init(userId: String) {
        self.userId = userId
        self.completedModules = []
        self.completedLessons = []
        self.quizScores = [:]
        self.lastAccessed = Date()
        self.totalTimeSpent = 0
    }
}

// MARK: - Education Statistics

struct EducationStats {
    let totalModules: Int
    let completedModules: Int
    let totalLessons: Int
    let completedLessons: Int
    let averageQuizScore: Double
    let timeSpent: TimeInterval
    
    var progressPercentage: Double {
        guard totalModules > 0 else { return 0 }
        return Double(completedModules) / Double(totalModules)
    }
    
    var lessonProgressPercentage: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
} 