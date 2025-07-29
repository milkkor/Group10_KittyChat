import SwiftUI

struct EducationModuleDetailView: View {
    let module: EducationModule
    @ObservedObject var viewModel: EducationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentLessonIndex = 0
    @State private var showingQuiz = false
    @State private var quizResults: [Int] = []
    @State private var showingQuizResults = false
    
    var body: some View {
        ZStack {
            // Modern gradient background matching other pages
            LinearGradient(
                colors: [
                    Color(hex: "fef9ff"),
                    Color(hex: "f3e8ff").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Lesson Content
                lessonContent
                
                // Navigation Buttons
                navigationButtons
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingQuiz) {
            if let quiz = module.lessons[currentLessonIndex].quiz {
                QuizView(
                    quiz: quiz,
                    onComplete: { results in
                        quizResults = results
                        showingQuizResults = true
                        viewModel.recordQuizScore(module.id, score: calculateScore(results, quiz: quiz))
                    }
                )
            }
        }
        .sheet(isPresented: $showingQuizResults) {
            QuizResultsView(
                quiz: module.lessons[currentLessonIndex].quiz!,
                results: quizResults
            )
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 0) {
            // Top navigation
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "374151"))
                }
                
                Spacer()
                
                Text(module.title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
                
                Button(action: {
                    showingQuiz = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(Color(hex: "374151"))
                }
                .disabled(module.lessons[currentLessonIndex].quiz == nil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress indicator
            VStack(spacing: 12) {
                HStack {
                    Text("Lesson \(currentLessonIndex + 1) of \(module.lessons.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "6b7280"))
                    
                    Spacer()
                    
                    if viewModel.isLessonCompleted(module.lessons[currentLessonIndex].id) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "10b981"))
                            Text("Completed")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "10b981"))
                        }
                    }
                }
                
                ProgressView(value: Double(currentLessonIndex + 1), total: Double(module.lessons.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "c084fc")))
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Lesson Content
    
    private var lessonContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let lesson = module.lessons[currentLessonIndex]
                
                // Lesson Title
                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text("\(lesson.duration) minutes")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Color(hex: "6b7280"))
                }
                .padding(.horizontal, 20)
                
                // Lesson Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(lesson.content)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "374151"))
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                // Interactive Elements
                if !lesson.interactiveElements.isEmpty {
                    interactiveElementsSection(lesson.interactiveElements)
                }
                
                // Quiz Preview
                if lesson.quiz != nil {
                    quizPreviewSection(lesson.quiz!)
                }
            }
            .padding(.bottom, 120) // Space for navigation buttons
        }
    }
    
    // MARK: - Interactive Elements Section
    
    private func interactiveElementsSection(_ elements: [InteractiveElement]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interactive Exercise")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(elements) { element in
                    InteractiveElementView(element: element)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Quiz Preview Section
    
    private func quizPreviewSection(_ quiz: Quiz) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Knowledge Check")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(Color(hex: "c084fc"))
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quiz.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "374151"))
                        
                        Text("\(quiz.questions.count) questions • Passing score: \(quiz.passingScore)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "6b7280"))
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button(action: previousLesson) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Previous")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "f3f4f6"))
                .foregroundColor(Color(hex: "374151"))
                .cornerRadius(12)
            }
            .disabled(currentLessonIndex == 0)
            
            Button(action: nextLesson) {
                HStack(spacing: 8) {
                    Text("Next")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color(hex: "c084fc").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    // MARK: - Actions
    
    private func previousLesson() {
        if currentLessonIndex > 0 {
            currentLessonIndex -= 1
        }
    }
    
    private func nextLesson() {
        // Mark current lesson as completed
        let currentLesson = module.lessons[currentLessonIndex]
        viewModel.completeLesson(currentLesson.id)
        
        if currentLessonIndex < module.lessons.count - 1 {
            currentLessonIndex += 1
        } else {
            // Module completed
            viewModel.completeModule(module.id)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func calculateScore(_ results: [Int], quiz: Quiz) -> Int {
        var correctAnswers = 0
        for (index, result) in results.enumerated() {
            if index < quiz.questions.count && result == quiz.questions[index].correctAnswer {
                correctAnswers += 1
            }
        }
        return correctAnswers
    }
}

// MARK: - Interactive Element View

struct InteractiveElementView: View {
    let element: InteractiveElement
    @State private var selectedAnswer: String?
    @State private var showingFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(element.content)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            if let options = element.options {
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedAnswer = option
                            showingFeedback = true
                        }) {
                            HStack {
                                Text(option)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "374151"))
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedAnswer == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "10b981"))
                                        .font(.system(size: 18))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedAnswer == option ? Color(hex: "10b981").opacity(0.1) : Color(hex: "f9fafb"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedAnswer == option ? Color(hex: "10b981") : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            
            if showingFeedback, let feedback = element.feedback {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "fbbf24"))
                        .font(.system(size: 16))
                    
                    Text(feedback)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "10b981"))
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .background(Color(hex: "10b981").opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "10b981").opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

// MARK: - Quiz View

struct QuizView: View {
    let quiz: Quiz
    let onComplete: ([Int]) -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Modern gradient background matching other pages
            LinearGradient(
                colors: [
                    Color(hex: "fef9ff"),
                    Color(hex: "f3e8ff").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "374151"))
                    }
                    
                    Spacer()
                    
                    Text(quiz.title)
                        .font(.headline)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(Color(hex: "374151"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "6b7280"))
                        
                        Spacer()
                    }
                    
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quiz.questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "c084fc")))
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Question content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        let question = quiz.questions[currentQuestionIndex]
                        
                        // Question
                        VStack(alignment: .leading, spacing: 16) {
                            Text(question.question)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "374151"))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Options
                        VStack(spacing: 12) {
                            ForEach(0..<question.options.count, id: \.self) { index in
                                Button(action: {
                                    selectAnswer(index)
                                }) {
                                    HStack {
                                        Text(question.options[index])
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "374151"))
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        if answers.count > currentQuestionIndex && answers[currentQuestionIndex] == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "10b981"))
                                                .font(.system(size: 18))
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(answers.count > currentQuestionIndex && answers[currentQuestionIndex] == index ? Color(hex: "10b981").opacity(0.1) : Color(hex: "f9fafb"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(answers.count > currentQuestionIndex && answers[currentQuestionIndex] == index ? Color(hex: "10b981") : Color.clear, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120) // Space for navigation buttons
                }
                
                // Navigation
                HStack(spacing: 16) {
                    Button("Previous") {
                        if currentQuestionIndex > 0 {
                            currentQuestionIndex -= 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "f3f4f6"))
                    .foregroundColor(Color(hex: "374151"))
                    .cornerRadius(12)
                    .disabled(currentQuestionIndex == 0)
                    
                    Button(currentQuestionIndex == quiz.questions.count - 1 ? "Finish" : "Next") {
                        if currentQuestionIndex == quiz.questions.count - 1 {
                            onComplete(answers)
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            currentQuestionIndex += 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color(hex: "c084fc").opacity(0.3), radius: 8, x: 0, y: 4)
                    .disabled(answers.count <= currentQuestionIndex)
                }
                .padding(20)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func selectAnswer(_ index: Int) {
        while answers.count <= currentQuestionIndex {
            answers.append(-1)
        }
        answers[currentQuestionIndex] = index
    }
}

// MARK: - Quiz Results View

struct QuizResultsView: View {
    let quiz: Quiz
    let results: [Int]
    @Environment(\.presentationMode) var presentationMode
    
    private var score: Int {
        var correct = 0
        for (index, result) in results.enumerated() {
            if index < quiz.questions.count && result == quiz.questions[index].correctAnswer {
                correct += 1
            }
        }
        return correct
    }
    
    private var passed: Bool {
        return score >= quiz.passingScore
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background matching other pages
            LinearGradient(
                colors: [
                    Color(hex: "fef9ff"),
                    Color(hex: "f3e8ff").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "374151"))
                    }
                    
                    Spacer()
                    
                    Text("Quiz Results")
                        .font(.headline)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(Color(hex: "374151"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Score Display
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                                
                                Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(passed ? Color(hex: "10b981") : Color(hex: "ef4444"))
                            }
                            
                            VStack(spacing: 8) {
                                Text(passed ? "Congratulations!" : "Keep Learning")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "374151"))
                                
                                Text("You scored \(score) out of \(quiz.questions.count)")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "6b7280"))
                                
                                if passed {
                                    Text("You passed the quiz!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "10b981"))
                                } else {
                                    Text("You need \(quiz.passingScore) correct answers to pass")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "ef4444"))
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Review Questions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Review")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "374151"))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                                    QuestionReviewCard(
                                        question: question,
                                        userAnswer: index < results.count ? results[index] : -1
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // Done button
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color(hex: "c084fc").opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(20)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Question Review Card

struct QuestionReviewCard: View {
    let question: QuizQuestion
    let userAnswer: Int
    
    private var isCorrect: Bool {
        return userAnswer == question.correctAnswer
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "374151"))
            
            VStack(spacing: 8) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    HStack {
                        Text(question.options[index])
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "374151"))
                        
                        Spacer()
                        
                        if index == question.correctAnswer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "10b981"))
                                .font(.system(size: 16))
                        } else if index == userAnswer && !isCorrect {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: "ef4444"))
                                .font(.system(size: 16))
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            if !isCorrect {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "fbbf24"))
                        .font(.system(size: 14))
                    
                    Text("Explanation: \(question.explanation)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6b7280"))
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
} 