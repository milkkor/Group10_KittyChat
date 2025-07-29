import SwiftUI

struct OnboardingView: View {
    @State private var userId: String = ""
    @State private var threadsHandle: String = ""
    @State private var isSignUp: Bool = false
    @State private var signUpError: String? = nil
    @State private var isUserIdFocused: Bool = false
    @State private var isThreadsFocused: Bool = false
    @FocusState private var focusedField: Field?
    
    var onLoginTapped: (String) -> Void
    var onSignUpTapped: (String, String) -> Void
    
    enum Field {
        case userId
        case threads
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: "fef9ff")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo area
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                        
                        Image("cat_paw") // Please ensure this image exists
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                    
                    Text("Welcome to KittyChat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text("A Safer Space for Dialogue")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6b7280"))
                }
                .padding(.bottom, 40)
                
                // Input area
                VStack(spacing: 16) {
                    TextField("User ID (e.g., user123)", text: $userId)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isUserIdFocused))
                        .focused($focusedField, equals: .userId)
                        .onChange(of: focusedField) { newValue in
                            isUserIdFocused = (newValue == .userId)
                        }
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                    
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Threads Profile URL", text: $threadsHandle)
                            .textFieldStyle(CustomTextFieldStyle(isFocused: isThreadsFocused))
                            .focused($focusedField, equals: .threads)
                            .onChange(of: focusedField) { newValue in
                                isThreadsFocused = (newValue == .threads)
                            }
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                                .keyboardType(.URL)
                            .frame(maxWidth: .infinity)
                            
                            // Helper text
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Supported formats:")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "6b7280"))
                                
                                Text("• https://www.threads.com/@username")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "9ca3af"))
                                
                                Text("• @username")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "9ca3af"))
                                
                                Text("• username")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "9ca3af"))
                            }
                        }
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            SendbirdAPI.checkUserExists(userId: userId) { exists in
                                DispatchQueue.main.async {
                                    if exists {
                                        signUpError = "This user ID is already registered, please login directly."
                                        isSignUp = false
                                    } else {
                                        onSignUpTapped(userId, threadsHandle)
                                    }
                                }
                            }
                        }) {
                            Text("Start Analysis")
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
                        .disabled(userId.isEmpty)
                        
                        Button(action: {
                            isSignUp = false
                        }) {
                            Text("Already have an account? Login here")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        .buttonStyle(SignUpButtonStyle())
                    } else {
                        Button(action: {
                            onLoginTapped(userId)
                        }) {
                            Text("Login")
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
                        .disabled(userId.isEmpty)
                        
                        Button(action: {
                            isSignUp = true
                        }) {
                            Text("First time? Sign up here")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        .buttonStyle(SignUpButtonStyle())
                    }
                }
                
                Spacer()
                Spacer()
            }
            .padding()
        }
        .alert(item: $signUpError) { msg in
            Alert(title: Text("Sign Up Error"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
    }
}

// Custom text field style
struct CustomTextFieldStyle: TextFieldStyle {
    var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color(hex: "c084fc") : Color(hex: "e5e7eb"), lineWidth: 1)
            )
            .shadow(color: isFocused ? Color(hex: "c084fc").opacity(0.1) : Color.clear, radius: 8)
    }
}

// Sign Up button style
struct SignUpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .foregroundColor(configuration.isPressed ? Color(hex: "c084fc") : Color(hex: "6b7280"))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            onLoginTapped: { userId in print("Login: \(userId)") },
            onSignUpTapped: { userId, threadsHandle in print("Sign up: \(userId), threads: \(threadsHandle)") }
        )
    }
} 