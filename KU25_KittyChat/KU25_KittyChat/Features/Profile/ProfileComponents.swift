import SwiftUI
import UIKit

// MARK: - Modern Card Container

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
    }
}



// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(hex: "6b7280"))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "d1d5db"))
            }
            .padding(20)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}





// MARK: - Simplified Components for Basic Info

// Simple Info Row
struct SimpleInfoRow: View {
    let title: String
    let value: String
    let isPrivate: Bool
    
    init(title: String, value: String, isPrivate: Bool = false) {
        self.title = title
        self.value = value
        self.isPrivate = isPrivate
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6b7280"))
                
                Text(displayValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "374151"))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var displayValue: String {
        if isPrivate && value.count > 12 {
            return String(value.prefix(8)) + "..."
        }
        return value
    }
}



// MARK: - Topic Map Analysis (Treemap + Tag Cloud Style)

struct TopicPreferenceCard: View {
    // Mock data - In production, this would be generated from chat analysis
    private let topicMapData = [
        TopicMapData(name: "AI Tools", frequency: 32, style: .technical, description: "Technical Discussion"),
        TopicMapData(name: "School", frequency: 28, style: .academic, description: "Academic Research"),
        TopicMapData(name: "Gaming", frequency: 25, style: .entertainment, description: "Entertainment"),
        TopicMapData(name: "Lifestyle", frequency: 22, style: .casual, description: "Daily Chat"),
        TopicMapData(name: "Work", frequency: 18, style: .professional, description: "Career Topics"),
        TopicMapData(name: "Food", frequency: 15, style: .lifestyle, description: "Food & Taste"),
        TopicMapData(name: "Tech", frequency: 14, style: .technical, description: "Tech News"),
        TopicMapData(name: "Music", frequency: 12, style: .creative, description: "Creative Inspiration"),
        TopicMapData(name: "Reading", frequency: 11, style: .academic, description: "Knowledge Sharing"),
        TopicMapData(name: "Sports", frequency: 9, style: .lifestyle, description: "Health & Fitness"),
        TopicMapData(name: "Movies", frequency: 8, style: .entertainment, description: "Film & TV"),
        TopicMapData(name: "Finance", frequency: 7, style: .professional, description: "Investment"),
        TopicMapData(name: "Travel", frequency: 6, style: .adventure, description: "Exploration"),
        TopicMapData(name: "Design", frequency: 5, style: .creative, description: "Visual Arts"),
        TopicMapData(name: "Cars", frequency: 4, style: .lifestyle, description: "Automotive")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "f472b6"))
                
                Text("Chat Topic Map")
                    .font(.headline)
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
            }
            
            // Treemap visualization
            TopicTreemapView(topics: topicMapData)
                .frame(height: 220)
        }
    }
}

struct TopicMapData {
    let name: String
    let frequency: Int // Frequency of occurrence (determines block size)
    let style: ChatStyle // Chat style (determines color)
    let description: String
}

enum ChatStyle: CaseIterable {
    case technical, academic, entertainment, casual, professional, lifestyle, creative, adventure
    
    var color: Color {
        switch self {
        case .technical: return Color(hex: "8b5cf6") // Purple - Rational & Technical
        case .academic: return Color(hex: "c084fc") // Light Purple - Academic Depth
        case .entertainment: return Color(hex: "f472b6") // Pink - Fun & Lively
        case .casual: return Color(hex: "6366f1") // Indigo - Casual & Natural
        case .professional: return Color(hex: "6b7280") // Gray - Professional & Stable
        case .lifestyle: return Color(hex: "ec4899") // Rose - Lifestyle & Taste
        case .creative: return Color(hex: "d946ef") // Magenta - Creative Inspiration
        case .adventure: return Color(hex: "8b5cf6") // Purple - Adventure & Exploration
        }
    }
    
    var name: String {
        switch self {
        case .technical: return "Technical"
        case .academic: return "Academic"
        case .entertainment: return "Fun"
        case .casual: return "Casual"
        case .professional: return "Professional"
        case .lifestyle: return "Lifestyle"
        case .creative: return "Creative"
        case .adventure: return "Adventure"
        }
    }
}

struct TopicTreemapView: View {
    let topics: [TopicMapData]
    
    var body: some View {
        GeometryReader { geometry in
            let layout = calculateTreemapLayout(
                topics: topics,
                in: CGRect(origin: .zero, size: geometry.size)
            )
            
            ZStack {
                ForEach(Array(layout.enumerated()), id: \.offset) { index, rect in
                    TopicBlock(
                        topic: topics[index],
                        frame: rect
                    )
                }
            }
        }
        .background(Color(hex: "f8fafc"))
        .cornerRadius(16)
    }
    
    private func calculateTreemapLayout(topics: [TopicMapData], in rect: CGRect) -> [CGRect] {
        // Optimized Treemap Algorithm - Dense & Compact Layout
        var layouts: [CGRect] = []
        let sortedTopics = topics.sorted(by: { $0.frequency > $1.frequency })
        let totalFrequency = sortedTopics.reduce(0) { $0 + $1.frequency }
        let totalArea = rect.width * rect.height * 0.95 // Use 95% of space
        
        var remainingRect = rect
        var index = 0
        
        while index < sortedTopics.count && remainingRect.width > 20 && remainingRect.height > 20 {
            let remainingTopics = Array(sortedTopics[index...])
            let remainingFrequency = remainingTopics.reduce(0) { $0 + $1.frequency }
            
            if remainingTopics.count == 1 {
                // Last block uses remaining space
                layouts.append(remainingRect)
                break
            }
            
            // Decide vertical or horizontal split
            let isWiderThanTall = remainingRect.width > remainingRect.height
            
            if isWiderThanTall {
                // Horizontal split - Calculate left block group
                var leftGroupFreq = 0
                var leftGroupCount = 0
                let targetRatio = 0.4 + Double.random(in: 0...0.2) // Random ratio for natural layout
                
                for i in 0..<min(3, remainingTopics.count) {
                    leftGroupFreq += remainingTopics[i].frequency
                    leftGroupCount += 1
                    if Double(leftGroupFreq) / Double(remainingFrequency) >= targetRatio {
                        break
                    }
                }
                
                let leftWidth = remainingRect.width * CGFloat(leftGroupFreq) / CGFloat(remainingFrequency)
                let leftRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: leftWidth,
                    height: remainingRect.height
                )
                
                // 遞歸處理左側區域
                let leftLayouts = layoutGroup(Array(remainingTopics.prefix(leftGroupCount)), in: leftRect)
                layouts.append(contentsOf: leftLayouts)
                
                // 更新剩餘區域
                remainingRect = CGRect(
                    x: remainingRect.minX + leftWidth + 2,
                    y: remainingRect.minY,
                    width: remainingRect.width - leftWidth - 2,
                    height: remainingRect.height
                )
                index += leftGroupCount
                
            } else {
                // 垂直分割 - 計算上方方塊組
                var topGroupFreq = 0
                var topGroupCount = 0
                let targetRatio = 0.4 + Double.random(in: 0...0.2)
                
                for i in 0..<min(3, remainingTopics.count) {
                    topGroupFreq += remainingTopics[i].frequency
                    topGroupCount += 1
                    if Double(topGroupFreq) / Double(remainingFrequency) >= targetRatio {
                        break
                    }
                }
                
                let topHeight = remainingRect.height * CGFloat(topGroupFreq) / CGFloat(remainingFrequency)
                let topRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: remainingRect.width,
                    height: topHeight
                )
                
                // 遞歸處理上方區域
                let topLayouts = layoutGroup(Array(remainingTopics.prefix(topGroupCount)), in: topRect)
                layouts.append(contentsOf: topLayouts)
                
                // 更新剩餘區域
                remainingRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY + topHeight + 2,
                    width: remainingRect.width,
                    height: remainingRect.height - topHeight - 2
                )
                index += topGroupCount
            }
        }
        
        return layouts
    }
    
    private func layoutGroup(_ topics: [TopicMapData], in rect: CGRect) -> [CGRect] {
        if topics.count == 1 {
            return [rect]
        }
        
        if topics.count == 2 {
            let freq1 = topics[0].frequency
            let freq2 = topics[1].frequency
            let total = freq1 + freq2
            
            if rect.width > rect.height {
                // 水平排列
                let width1 = rect.width * CGFloat(freq1) / CGFloat(total)
                return [
                    CGRect(x: rect.minX, y: rect.minY, width: width1, height: rect.height),
                    CGRect(x: rect.minX + width1 + 1, y: rect.minY, width: rect.width - width1 - 1, height: rect.height)
                ]
            } else {
                // 垂直排列
                let height1 = rect.height * CGFloat(freq1) / CGFloat(total)
                return [
                    CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height1),
                    CGRect(x: rect.minX, y: rect.minY + height1 + 1, width: rect.width, height: rect.height - height1 - 1)
                ]
            }
        }
        
        // 3個或更多方塊 - 網格布局
        let totalFreq = topics.reduce(0) { $0 + $1.frequency }
        var layouts: [CGRect] = []
        
        if topics.count <= 4 {
            // 2x2 網格
            let cols = 2
            let rows = 2
            let cellWidth = (rect.width - 1) / 2
            let cellHeight = (rect.height - 1) / 2
            
            for (index, _) in topics.enumerated() {
                let col = index % cols
                let row = index / cols
                let x = rect.minX + CGFloat(col) * (cellWidth + 1)
                let y = rect.minY + CGFloat(row) * (cellHeight + 1)
                layouts.append(CGRect(x: x, y: y, width: cellWidth, height: cellHeight))
            }
        } else {
            // 更多方塊使用流式布局
            var currentX = rect.minX
            var currentY = rect.minY
            var rowHeight: CGFloat = rect.height / 3
            
            for (index, topic) in topics.enumerated() {
                let blockWidth = max(40, rect.width / 4) // 最小40點寬度
                
                if currentX + blockWidth > rect.maxX {
                    currentX = rect.minX
                    currentY += rowHeight + 1
                    if index < topics.count - 1 {
                        rowHeight = (rect.maxY - currentY) / CGFloat(topics.count - index) * 1.5
                    }
                }
                
                layouts.append(CGRect(
                    x: currentX,
                    y: currentY,
                    width: blockWidth,
                    height: min(rowHeight, rect.maxY - currentY)
                ))
                
                currentX += blockWidth + 1
            }
        }
        
        return layouts
    }
}

struct TopicBlock: View {
    let topic: TopicMapData
    let frame: CGRect
    
    var body: some View {
        let cornerRadius: CGFloat = min(8, frame.width * 0.12)
        
        VStack(spacing: max(2, frame.height * 0.08)) {
            // Topic name with better typography
            if frame.width > 30 && frame.height > 20 {
                Text(topic.name)
                    .font(.system(size: min(max(frame.width * 0.14, 9), 13), weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
            }
            
            // Percentage - show on larger blocks
            if frame.width > 50 && frame.height > 35 {
                Text("\(topic.frequency)%")
                    .font(.system(size: min(max(frame.width * 0.12, 8), 10), weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(width: frame.width, height: frame.height)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            topic.style.color.opacity(0.95),
                            topic.style.color.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(topic.style.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: topic.style.color.opacity(0.3), radius: 2, x: 0, y: 1)
        .position(x: frame.midX, y: frame.midY)
    }
}



// MARK: - Simplified AI Safety Summary

struct SafetySummaryCard: View {
    let currentStrikes: Double
    let maxStrikes: Double
    
    private var safetyStatus: (text: String, color: Color, icon: String) {
        switch currentStrikes {
        case 0:
            return ("No warnings in last 7 days", Color(hex: "10b981"), "checkmark.shield.fill")
        case 1..<maxStrikes * 0.7:
            return ("Good interaction quality", Color(hex: "10b981"), "shield.fill")
        case maxStrikes * 0.7..<maxStrikes:
            return ("\(Int(currentStrikes)) times flagged", Color(hex: "f59e0b"), "exclamationmark.shield.fill")
        default:
            return ("Need to watch language content", Color(hex: "ef4444"), "xmark.shield.fill")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundColor(Color(hex: "8b5cf6"))
                
                Text("AI Safety Interaction")
                    .font(.headline)
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
            }
            
            // Status indicator
            HStack(spacing: 16) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(safetyStatus.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: safetyStatus.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(safetyStatus.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(safetyStatus.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text(encouragingMessage)
                        .font(.caption)
                        .foregroundColor(Color(hex: "6b7280"))
                }
                
                Spacer()
            }
            
            // Simple progress bar
            if currentStrikes > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Safety Score")
                            .font(.caption)
                            .foregroundColor(Color(hex: "6b7280"))
                        
                        Spacer()
                        
                        Text("\(Int(currentStrikes))/\(Int(maxStrikes))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(safetyStatus.color)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "f3f4f6"))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(safetyStatus.color)
                                .frame(
                                    width: geometry.size.width * (currentStrikes / maxStrikes),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 1.0), value: currentStrikes)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }
    
    private var encouragingMessage: String {
        switch currentStrikes {
        case 0:
            return "Your conversation style is stable 👍"
        case 1..<maxStrikes * 0.7:
            return "Keep up the friendly communication"
        case maxStrikes * 0.7..<maxStrikes:
            return "Mindful language makes conversations smoother"
        default:
            return "Please review community guidelines"
        }
    }
}

// MARK: - AI Personality Analysis

struct AIPersonalityAnalysis {
    let languageStyle: String
    let communicationStyle: String
    let personaSummary: PersonaSummary
}

struct PersonaSummary {
    let label: String
    let description: String
}

// AI Personality Analysis Display
struct AIPersonalityDisplay: View {
    let analysis: AIPersonalityAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            // Persona Summary Header
            VStack(spacing: 8) {
                HStack {
                    Text("AI Personality Analysis")
                        .font(.caption)
                        .foregroundColor(Color(hex: "6b7280"))
                    
                    Spacer()
                }
                
                // Persona Label
                HStack {
                    Text(analysis.personaSummary.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "374151"))
                    
                    Spacer()
                }
            }
            
            // Persona Description
            VStack(spacing: 12) {
                Text(analysis.personaSummary.description)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6b7280"))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Language Style
                VStack(spacing: 4) {
                    HStack {
                        Text("Language Style")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "8b5cf6"))
                        
                        Spacer()
                    }
                    
                    Text(analysis.languageStyle)
                        .font(.caption)
                        .foregroundColor(Color(hex: "6b7280"))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Communication Style
                VStack(spacing: 4) {
                    HStack {
                        Text("Communication Pattern")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "8b5cf6"))
                        
                        Spacer()
                    }
                    
                    Text(analysis.communicationStyle)
                        .font(.caption)
                        .foregroundColor(Color(hex: "6b7280"))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "fef9ff"),
                Color(hex: "f3e8ff").opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                Text("Profile Components Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "374151"))
                
                Group {
                    SimpleInfoRow(
                        title: "User ID",
                        value: "user123456789",
                        isPrivate: true
                    )
                    
                    SimpleInfoRow(
                        title: "Threads Account",
                        value: "analytical_user"
                    )
                    
                    AIPersonalityDisplay(
                        analysis: AIPersonalityAnalysis(
                            languageStyle: "You often use questions and emojis, with a gentle and polite tone.",
                            communicationStyle: "You like to start with questions, prefer rational organization, and express views after emotional packaging.",
                            personaSummary: PersonaSummary(
                                label: "Rational & Gentle Observer",
                                description: "You always understand before responding, speak logically but not coldly, and consider others' perspectives."
                            )
                        )
                    )
                }
                
                Group {
                    TopicPreferenceCard()
                    
                    SafetySummaryCard(
                        currentStrikes: 0,
                        maxStrikes: 3
                    )
                }
                
                ActionCard(
                    icon: "shield.checkerboard",
                    title: "Safety Settings",
                    subtitle: "Customize AI Guardian preferences",
                    color: Color(hex: "8b5cf6"),
                    action: {}
                )
            }
            .padding()
        }
    }
} 