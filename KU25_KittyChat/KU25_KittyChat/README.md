# KU25_KittyChat

A secure and intelligent chat application featuring AI-powered content moderation, user education modules, and Threads profile analysis capabilities.

## 🚀 Core Features

### 🤖 AI Guardian Safety System
- **Google Gemini API Integration**: Real-time content analysis and flagging
- **Multi-layered Detection**: Local keyword detection + AI-powered intelligent analysis
- **Severity Classification**: Low/Medium/High risk content categorization
- **Bidirectional Interaction System**: Complete response flow for both senders and receivers

### 💬 Real-time Chat Functionality
- **Sendbird Chat SDK**: Professional-grade chat experience
- **Group Chat Support**: Multi-user conversation capabilities
- **Message Interception**: GlobalMessageMonitor for comprehensive monitoring
- **Custom Message Types**: Special handling for flagged messages

### 🧵 Threads Profile Analysis
- **Intelligent Scraping**: Automated extraction of Threads user posts
- **AI Content Analysis**: Post content analysis using Gemini API
- **Risk Assessment**: Misogyny risk score calculation
- **Interest Identification**: Automatic detection of user interests and personality traits
- **Caching Mechanism**: Token usage optimization and analysis result caching

### 📚 Education Module
- **Interactive Learning**: Targeted educational content
- **Progress Tracking**: EducationProgressManager for learning progress management
- **Modular Design**: Extensible educational content architecture
- **Personalized Recommendations**: Behavior-based educational suggestions

### ⚡ Bidirectional Interaction System
- **Sender Responses**: Retract/Edit/Just Joking options
- **Receiver Responses**: Acceptable/Uncomfortable/Exit options
- **Intelligent Scoring**: Punishment calculation based on mutual responses
- **Interaction Tracking**: Complete interaction flow logging

### 🎯 Strike System
- **Progressive Punishment**: StrikeManager for user penalty management
- **Education Integration**: Punishment triggers educational modules
- **Exit Mechanisms**: Automatic exit for severe violations
- **Data Persistence**: Local and remote penalty records

### 🔄 Webhook Integration
- **Cross-device Notifications**: Real-time user status synchronization
- **Data Synchronization**: Penalty and education progress sync
- **Configurable Endpoints**: Support for custom webhook URLs

## 🏗️ Technical Architecture

### Core Structure
```
KU25_KittyChat/
├── Core/                    # Core functionality modules
│   ├── DetectionEngine/     # Content detection engine
│   ├── Managers/           # Business logic managers
│   ├── Services/           # External API services
│   └── UI/                 # Shared UI components
├── Features/               # Feature modules
│   ├── Chat/              # Chat functionality
│   ├── Education/         # Education module
│   ├── Matching/          # Matching functionality
│   ├── Onboarding/        # Onboarding flow
│   └── Profile/           # Profile management
├── Data/                  # Data models
└── Resources/             # Resource files
```

### Key Components

#### DetectionEngine
- `DetectionEngine.swift`: Local keyword detection
- `BiDirectionalInteractionManager.swift`: Bidirectional interaction management

#### Services
- `GeminiService.swift`: Google Gemini API integration
- `SendbirdAPI.swift`: Sendbird chat services
- `ThreadsAnalysisService.swift`: Threads analysis service

#### Managers
- `GlobalMessageMonitor.swift`: Global message monitoring
- `StrikeManager.swift`: Strike system management
- `AIMessageRouter.swift`: AI message routing
- `WebhookEndpointURL.swift`: Webhook configuration

## 📱 User Flow

### 1. Registration Process
```
Enter Threads Account → AI Profile Analysis → Risk Assessment → Complete Registration
```

### 2. Chat Process
```
Send Message → AI Detection → Safe/Flagged → Bidirectional Interaction → Penalty Calculation
```

### 3. Education Process
```
Trigger Penalty → Education Module → Learning Content → Progress Tracking → Complete Learning
```

## ⚙️ Installation & Configuration

### System Requirements
- **Xcode**: 14.0 or later
- **iOS**: 16.0 or later
- **Swift**: 5.7 or later
- **macOS**: 13.0 or later (development environment)

### API Configuration

⚠️ **Important**: All API keys in the project are placeholders and must be replaced with actual keys for proper functionality.

#### 1. Google Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Open `Core/Services/GeminiService.swift`
4. Replace line 42 placeholder:

```swift
// Replace this line
self.apiKey = "YOUR_GEMINI_API_KEY_HERE"

// With
self.apiKey = "your-actual-gemini-api-key"
```

#### 2. Sendbird Credentials

1. Create a Sendbird account at [Sendbird](https://sendbird.com)
2. Create a new application
3. Obtain Application ID and API Token
4. Open `Core/Services/SendbirdAPI.swift`
5. Replace lines 9 and 17 placeholders:

```swift
// Replace these lines
static let appId = "YOUR_SENDBIRD_APP_ID_HERE"
static let apiToken = "YOUR_SENDBIRD_API_TOKEN_HERE"

// With
static let appId = "your-actual-sendbird-app-id"
static let apiToken = "your-actual-sendbird-api-token"
```

#### 3. Webhook Endpoint URL

1. Set up webhook endpoint (Firebase Functions, AWS Lambda, etc.)
2. Open `Core/Managers/WebhookEndpointURL.swift`
3. Replace line 8 URL:

```swift
// Replace this line
return "https://<URL>.ngrok-free.app/kittychat-149e5/us-central1/sendbirdWebhook"



### Environment Variables Configuration (Recommended)

For enhanced security, we recommend using environment variables:

1. Create a `.env` file in the project root (already in `.gitignore`)
2. Add your API keys:

```env
GEMINI_API_KEY=your-gemini-api-key
SENDBIRD_APP_ID=your-sendbird-app-id
SENDBIRD_API_TOKEN=your-sendbird-api-token
WEBHOOK_URL=your-webhook-url
```

3. Uncomment the environment variable loading code in respective service files

### Installation Steps

1. Clone the repository:
```bash
git clone https://github.com/your-username/KU25_KittyChat.git
cd KU25_KittyChat
```

2. Open `KU25_KittyChat.xcodeproj` in Xcode

3. Configure API keys as described above

4. Build and run the project

## 🔧 Development Guide

### Architecture Patterns
- **MVVM**: Using SwiftUI's @StateObject and @Published
- **Protocol-Oriented**: Extensive use of Swift protocols
- **Dependency Injection**: Service layer dependency injection
- **Reactive Programming**: Combine framework integration

### Key Technologies
- **SwiftUI**: Modern UI framework
- **SendbirdUIKit**: Professional chat UI components
- **Combine**: Reactive programming
- **Async/Await**: Modern asynchronous processing
- **Core Data**: Local data persistence

### Code Style
- **Naming Conventions**: camelCase for variables/functions, PascalCase for types
- **Documentation**: Comprehensive Chinese comments and DEBUG logging
- **Error Handling**: Result types and proper error handling
- **Memory Management**: Appropriate weak/strong references

## 🧪 Testing

### Unit Testing
- XCTest framework
- Core business logic testing
- External API call mocking

### UI Testing
- XCUITest implementation
- Main user flow testing
- UI interaction validation

### Manual Testing
- Threads analysis functionality testing
- AI detection accuracy verification
- Bidirectional interaction flow validation

## 📊 Performance Optimization

### Token Usage Optimization
- Threads analysis result caching
- Intelligent content truncation
- Batch API calls

### Memory Management
- Lazy image loading
- Appropriate memory cleanup
- Background task handling

### Network Optimization
- Request caching
- Error retry mechanisms
- Offline support

## 🔒 Security Considerations

### Data Protection
- Secure API key storage
- Sensitive data encryption
- Local data protection

### Privacy Protection
- Minimal data collection
- User consent mechanisms
- Data deletion capabilities

### Content Security
- Multi-layered content detection
- User reporting mechanisms
- Automatic content filtering

## 🚨 Known Issues

### Development Phase Issues
- API keys require manual configuration
- Webhook URL requires custom setup
- Threads analysis may be affected by website changes

### Limitations
- Valid API keys required for complete testing
- Threads analysis functionality depends on external websites
- Some features require network connectivity

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Environment Setup
- Ensure all API keys are properly configured
- Test all major functionality flows
- Check code style and documentation
- Update relevant documentation

---

**Note**: This is a demonstration application. For production use, ensure all security measures are properly implemented and tested.

## 📈 Version History

### v1.0.0 (Current Version)
- Initial release
- Complete AI Guardian system
- Threads profile analysis
- Bidirectional interaction system
- Education module
- Strike system

### Future Plans
- Additional educational content modules
- Advanced AI detection features
- Enhanced community functionality
- Multi-language support
- Additional platform integrations






