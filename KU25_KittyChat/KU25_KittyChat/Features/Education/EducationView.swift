import SwiftUI

struct EducationView: View {
    @StateObject private var viewModel = EducationViewModel()
    @State private var selectedModule: EducationModule? = nil
    
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
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    headerSection
                    progressSection
                    modulesSection
                    quickTipsSection
                    resourcesSection
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedModule) { module in
            EducationModuleDetailView(module: module, viewModel: viewModel)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top navigation
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "374151"))
                }
                
                Spacer()
                
                Text("Education")
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
            
            // Header content
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color(hex: "c084fc"))
                }
                
                VStack(spacing: 8) {
                    Text("AI Guardian Education")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text("Learn about safe communication and understand how AI Guardian works to protect everyone.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6b7280"))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
                
                Text("\(viewModel.completedModules)/\(viewModel.totalModules)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "6b7280"))
            }
            
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "c084fc")))
                
                Text("\(Int(viewModel.progressPercentage * 100))% Complete")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6b7280"))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Modules Section
    
    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Modules")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.modules) { module in
                    EducationModuleCard(
                        module: module,
                        isCompleted: viewModel.isModuleCompleted(module.id)
                    ) {
                        selectedModule = module
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Quick Tips Section
    
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tips")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(viewModel.quickTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(Color(hex: "fbbf24"))
                            .font(.system(size: 16))
                        
                        Text(tip)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "6b7280"))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Resources Section
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Resources")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "374151"))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(viewModel.resources, id: \.title) { resource in
                    Button(action: {
                        viewModel.openResource(resource)
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: resource.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "c084fc"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(resource.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "374151"))
                                
                                Text(resource.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "6b7280"))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Education Module Card

struct EducationModuleCard: View {
    let module: EducationModule
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isCompleted ? 
                                        [Color(hex: "10b981"), Color(hex: "059669")] :
                                        [Color(hex: "f472b6"), Color(hex: "c084fc")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: module.iconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10b981"))
                            .font(.system(size: 20))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(module.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "374151"))
                        .lineLimit(2)
                    
                    Text(module.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6b7280"))
                        .lineLimit(3)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(module.duration) min")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "6b7280"))
                    
                    Spacer()
                    
                    Text(module.difficulty.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.1))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(6)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var difficultyColor: Color {
        switch module.difficulty {
        case .beginner: return Color(hex: "10b981")
        case .intermediate: return Color(hex: "f59e0b")
        case .advanced: return Color(hex: "ef4444")
        }
    }
}

struct EducationView_Previews: PreviewProvider {
    static var previews: some View {
        EducationView()
    }
} 