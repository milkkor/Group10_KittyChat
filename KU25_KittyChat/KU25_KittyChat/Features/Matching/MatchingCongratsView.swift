import SwiftUI
import SendbirdChatSDK

struct MatchCongratsView: View {
    let matchedUser: User
    var onSendMessage: () -> Void
    var onContinue: () -> Void
    
    private var interests: [String] {
        (matchedUser.metaData["interests"] ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var body: some View {
        ZStack {
            // 背景色統一
            Color(hex: "fef9ff")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo 區域
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                        
                        Image(systemName: "heart.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color(hex: "f472b6"))
                    }
                    
                    Text("Congrats!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text("You have a match!")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6b7280"))
                }
                .padding(.bottom, 20)
                
                // 貓咪頭像區域
                HStack(spacing: -30) {
                    // 左邊的貓咪
                    Image("cat_left")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "fbcfe8"), lineWidth: 3))
                        .shadow(color: Color(hex: "fbcfe8").opacity(0.3), radius: 6, x: 0, y: 2)
                    // 右邊的貓咪
                    Image("cat_right")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "bbf7d0"), lineWidth: 3))
                        .shadow(color: Color(hex: "bbf7d0").opacity(0.3), radius: 6, x: 0, y: 2)
                }
                
                // 配對資訊卡片
                VStack(spacing: 16) {
                    Text(matchedUser.nickname ?? "Unknown")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    // 興趣標籤
                    VStack(alignment: .leading, spacing: 12) {
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
                    
                    // 風險等級卡片
                    HStack(spacing: 12) {
                        Image(systemName: (matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor((matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? Color(hex: "22c55e") : Color(hex: "ef4444"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text((matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? "Safe User Verified" : "Potential Risk Detected")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor((matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? Color(hex: "22c55e") : Color(hex: "ef4444"))
                            
                            Text("Misogyny Level: \(matchedUser.metaData["misogyny_risk"] ?? "-")")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background((matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? Color(hex: "f0fdf4") : Color(hex: "fef2f2"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke((matchedUser.metaData["misogyny_risk"] ?? "") == "Safe" ? Color(hex: "22c55e").opacity(0.2) : Color(hex: "ef4444").opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 按鈕區域
                VStack(spacing: 16) {
                    Button(action: onSendMessage) {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Send Message")
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
                    
                    Button(action: onContinue) {
                        Text("Continue matching")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "6b7280"))
                    }
                    .buttonStyle(ContinueButtonStyle())
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// Continue 按鈕樣式
struct ContinueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .foregroundColor(configuration.isPressed ? Color(hex: "c084fc") : Color(hex: "6b7280"))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}