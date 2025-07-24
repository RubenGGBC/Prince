# 🏋️ Prince Fitness App - Developer Guide

## 📋 Project Overview
Prince is a sophisticated Flutter fitness app that combines traditional workout tracking with AI-powered coaching. The app features real-time pose detection using ML Kit, conversational AI coaching via Google Gemini, and a comprehensive SQLite database for fitness data management.

## 🎯 Key Features
- **AI-Powered Coaching**: Integration with Google Gemini API for personalized fitness advice
- **Real-Time Pose Detection**: ML Kit integration for exercise form analysis
- **Comprehensive Tracking**: Exercise logging, routine management, and progress tracking
- **Cross-Platform**: Mobile and desktop support with adaptive UI
- **Advanced Navigation**: Multi-page swipe interface with smooth animations

## 🏗️ Architecture

### Project Structure
```
lib/
├── database/          # SQLite database layer (DatabaseHelper singleton)
├── domain/           # Business entities (User, Exercise, Rutina, Nutricion)
├── models/           # Data transfer objects (ChatMessage, FormFeedback)
├── screens/          # UI layer - all app screens
├── services/         # Business logic and external APIs
├── utils/            # Utilities (AppColors, constants)
└── widgets/          # Reusable UI components
```

### Core Architectural Patterns
1. **Repository Pattern**: `DatabaseHelper` singleton for data persistence
2. **Rich Domain Models**: Models with business logic and validation
3. **StatefulWidget Architecture**: Local state management with manual updates
4. **Factory Pattern**: Model constructors (`fromMap()`, `toMap()`)
5. **Observer Pattern**: Stream-based real-time updates

## 🗄️ Database Schema

### Core Tables
- **users**: User authentication and profile data
- **exercises**: Exercise tracking with timestamps, sets, reps, weight
- **rutinas**: Workout routines with exercise groupings

### Key Models
```dart
User {
  email, password (hashed), name, weight, height, age, genre
}

Exercise {
  grupo_muscular, nombre, repeticiones, series, peso, notas
  hora_inicio, hora_fin, fecha_creacion
}

Rutina {
  nombre, descripcion, ejercicio_ids, duracion_estimada, categoria
}
```

## 🔧 Development Commands

### Flutter Commands
```bash
# Run app in development mode
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos           # macOS

# Build for production
flutter build apk             # Android
flutter build ios             # iOS
flutter build windows         # Windows
flutter build macos           # macOS

# Code analysis and formatting
flutter analyze               # Static analysis
flutter format .             # Code formatting
```

### Database Operations
```bash
# Reset database (uncomment in main.dart)
# Useful for development when schema changes
```

### Testing
```bash
flutter test                  # Run unit tests
flutter test --coverage      # Run with coverage
flutter integration_test     # Run integration tests
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android SDK / Xcode (for mobile)
- Desktop development setup (for desktop targets)

### Setup Steps
1. Clone repository
2. Run `flutter pub get`
3. Ensure database initialization in `main.dart`
4. Configure API keys if needed (Gemini API)
5. Run `flutter run`

## 🔌 Key Integrations

### AI Services
- **Google Gemini API**: Conversational fitness coaching
- **ML Kit Pose Detection**: Real-time exercise analysis
- **Camera Integration**: Live video analysis

### Dependencies
```yaml
# Core Flutter
sqflite: ^2.3.0              # Database
google_fonts: ^6.1.0         # Typography
camera: ^0.10.5+9            # Camera access

# AI & ML
google_mlkit_pose_detection: ^0.6.0
http: ^1.1.2                 # API requests

# UI Enhancement
shimmer: ^3.0.0              # Loading animations
lottie: ^2.7.0               # Animations
```

## 📱 Screen Architecture

### Navigation Flow
```
SplashScreen → LoginScreen → HomeTab (PageView)
                    ↓              ↓
              RegisterScreen    [Home, AI Chat, Progress, Profile]
                                       ↓
                           Various sub-screens
```

### Key Screens
- **home_tab.dart**: Main navigation hub with PageView
- **prince_ai_chat_screen.dart**: AI coaching interface
- **progress_tab.dart**: Exercise tracking and statistics
- **workout_session_screen.dart**: Active workout tracking
- **exercises_tab.dart**: Exercise library and management

## 🎨 Design System

### Color Palette
```dart
AppColors {
  primaryBlack: #1a1a1a
  surfaceBlack: #2d2d2d
  pastelBlue: #6366f1
  white: #ffffff
  // Additional theme colors
}
```

### UI Patterns
- **Dark Theme**: Optimized for fitness environments
- **Gradient Backgrounds**: Blue-themed professional appearance
- **Responsive Design**: Tablet and desktop optimizations
- **Smooth Animations**: Custom transitions and micro-interactions

## 💡 Development Best Practices

### Code Organization
1. **Consistent Naming**: snake_case for files, PascalCase for classes
2. **Error Handling**: Try-catch blocks with user feedback
3. **State Management**: Use `setState()` for simple state, consider Provider for complex state
4. **Database Operations**: Always use async/await with proper error handling

### Model Patterns
```dart
class YourModel {
  // Constructor
  YourModel({required this.field});
  
  // Factory constructor
  factory YourModel.fromMap(Map<String, dynamic> map) { ... }
  
  // Serialization
  Map<String, dynamic> toMap() { ... }
  
  // Copy with modifications
  YourModel copyWith({...}) { ... }
}
```

### Database Patterns
```dart
// Always use DatabaseHelper singleton
final DatabaseHelper _dbHelper = DatabaseHelper();

// Async operations with error handling
Future<void> _loadData() async {
  try {
    final data = await _dbHelper.getData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      // Handle error appropriately
    }
  }
}
```

## 🔍 Debugging and Troubleshooting

### Common Issues
1. **Database Connection**: Check DatabaseHelper initialization
2. **State Updates**: Verify `mounted` before calling `setState()`
3. **API Issues**: Check network connectivity and API keys
4. **Build Issues**: Run `flutter clean` and `flutter pub get`

### Debugging Tools
```bash
flutter logs                  # View device logs
flutter inspector            # UI debugging
flutter analyze              # Static analysis
```

## 📊 Performance Considerations

### Database Optimization
- Use indexed queries for large datasets
- Implement pagination for exercise lists
- Cache frequently accessed data

### UI Performance
- Avoid excessive `setState()` calls
- Use `const` constructors where possible
- Implement proper ListView builders for large lists

## 🧪 Testing Strategy

### Current State
- Basic smoke test in `widget_test.dart`
- Limited test coverage

### Recommended Testing
```dart
// Unit tests for models
test('User.fromMap creates valid user', () { ... });

// Widget tests for UI components
testWidgets('HomeTab displays correctly', (tester) async { ... });

// Integration tests for user flows
testWidgets('User can log exercise', (tester) async { ... });
```

## 🔐 Security Considerations

### Current Security Measures
- Password hashing with SHA-256
- Input validation in models
- Secure API key handling

### Security Best Practices
- Never commit API keys to version control
- Validate all user inputs
- Use secure storage for sensitive data
- Implement proper authentication flows

## 🚧 Future Enhancements

### Planned Features
1. **Nutrition Tracking**: Full nutrition database integration
3. **Advanced Analytics**: ML-powered insights and predictions

### Technical Improvements
1. **State Management**: Migrate to Provider or Riverpod
2. **Testing Coverage**: Comprehensive test suite
3. **CI/CD Pipeline**: Automated testing and deployment
4. **Performance Monitoring**: Analytics and crash reporting

## 📚 Additional Resources

### Documentation
- Flutter documentation: https://flutter.dev/docs
- SQLite documentation: https://www.sqlite.org/docs.html
- ML Kit documentation: https://developers.google.com/ml-kit

### Development Tools
- Flutter Inspector for UI debugging
- Android Studio Profiler for performance analysis
- VS Code Flutter extensions for enhanced development

---

*This guide provides comprehensive architectural guidance for the Prince fitness app. For feature requests and specific implementations, refer to the project's claude.md file.*