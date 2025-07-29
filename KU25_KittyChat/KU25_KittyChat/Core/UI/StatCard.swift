import SwiftUI

// MARK: - ProfileAnalysisView 使用的 StatCard
struct ProfileStatCard: View {
    let title: String
    let value: String
    let bgColor: Color
    let valueColor: Color
    let icon: String
    var isTextValue: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(valueColor)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "6b7280"))
            
            Text(value)
                .font(.system(size: isTextValue ? 14 : 20, weight: .bold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(bgColor)
        .cornerRadius(12)
    }
}

 