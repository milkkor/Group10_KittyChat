import Foundation

class EducationProgressManager {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Public Methods
    
    func loadProgress(for userId: String, completion: @escaping (UserProgress) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("education_progress_\(userId).json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            // Create new progress if file doesn't exist
            let newProgress = UserProgress(userId: userId)
            completion(newProgress)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let progress = try decoder.decode(UserProgress.self, from: data)
            completion(progress)
        } catch {
            print("Error loading education progress: \(error)")
            // Return new progress if decoding fails
            let newProgress = UserProgress(userId: userId)
            completion(newProgress)
        }
    }
    
    func saveProgress(_ progress: UserProgress, completion: @escaping (Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("education_progress_\(progress.userId).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(progress)
            try data.write(to: fileURL)
            completion(true)
        } catch {
            print("Error saving education progress: \(error)")
            completion(false)
        }
    }
    
    func getStats(for userId: String, completion: @escaping (EducationStats?) -> Void) {
        loadProgress(for: userId) { progress in
            let contentManager = EducationContentManager.shared
            let allModules = contentManager.getAllModules()
            
            let totalModules = allModules.count
            let completedModules = progress.completedModules.count
            
            let totalLessons = allModules.reduce(0) { $0 + $1.lessons.count }
            let completedLessons = progress.completedLessons.count
            
            let averageQuizScore = self.calculateAverageQuizScore(progress.quizScores)
            
            let stats = EducationStats(
                totalModules: totalModules,
                completedModules: completedModules,
                totalLessons: totalLessons,
                completedLessons: completedLessons,
                averageQuizScore: averageQuizScore,
                timeSpent: progress.totalTimeSpent
            )
            
            completion(stats)
        }
    }
    
    func resetProgress(for userId: String, completion: @escaping (Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("education_progress_\(userId).json")
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            completion(true)
        } catch {
            print("Error resetting education progress: \(error)")
            completion(false)
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateAverageQuizScore(_ scores: [String: Int]) -> Double {
        guard !scores.isEmpty else { return 0 }
        
        let totalScore = scores.values.reduce(0, +)
        return Double(totalScore) / Double(scores.count)
    }
} 