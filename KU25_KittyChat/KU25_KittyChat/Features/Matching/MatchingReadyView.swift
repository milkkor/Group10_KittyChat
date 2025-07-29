import SwiftUI

struct MatchingReadyView: View {
    var isMatching: Bool
    var onStartMatching: () -> Void
    var error: String?
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "fef9ff")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo 區域
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                        
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(hex: "f472b6"))
                    }
                    
                    Text("Ready to Match?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text("Find someone special to chat with")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6b7280"))
                        .multilineTextAlignment(.center)
                }
                
                // 狀態區域
                VStack(spacing: 20) {
                    if isMatching {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "c084fc")))
                                .scaleEffect(1.2)
                            
                            Text("Finding your perfect match...")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        .padding(32)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                    } else {
                        Button(action: onStartMatching) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Start Matching")
                                    .font(.system(size: 17, weight: .bold))
                            }
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
                    }
                    
                    // 錯誤訊息
                    if let error = error {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "ef4444"))
                            
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "ef4444"))
                        }
                        .padding(16)
                        .background(Color(hex: "fef2f2"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "ef4444").opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}
