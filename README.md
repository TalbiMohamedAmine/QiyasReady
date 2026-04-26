# QiyasReady

An advanced, adaptive exam preparation platform designed to help students excel in the Qiyas exams. Built with Flutter, this project serves as a comprehensive MVP foundation for delivering personalized learning experiences, performance tracking, and exam simulations.

## 🚀 Features

The application is structured into modular, feature-based directories to maintain clean architecture and scalability. Below is a comprehensive list of all features included in QiyasReady:

### 1. Authentication (`/lib/features/auth`)
- **Secure Sign In & Sign Up:** Robust user authentication screens supporting standard email/password.
- **Social Auth Providers:** Integration for Google, Apple, and Facebook sign-ins.
- **Auth Gate:** Intelligent routing based on the user's active session state.

### 2. Onboarding (`/lib/features/onboarding`)
- **Welcome Flow:** A polished, engaging onboarding experience to guide new users through the app's value proposition and initial setup.

### 3. Adaptive Practice (`/lib/features/adaptive_practice`)
- **Dynamic Practice Engine:** An AI-driven practice mode that adapts question difficulty based on real-time user performance.
- **Subject & Topic Selection:** Targeted practice across different subjects and sub-topics.
- **Customizable Filters:** Granular control over practice sessions (e.g., specific concepts, difficulty levels).
- **Session Summaries:** Detailed breakdown and review of completed practice sessions.

### 4. Full Mock Exams (`/lib/features/mock_exam`)
- **Exam Simulation:** A realistic, timed mock exam environment designed to mirror the actual Qiyas testing interface.
- **Instant Grading & Results:** Immediate scoring upon exam submission.
- **Detailed Review:** Comprehensive post-exam review screen to analyze correct and incorrect answers with explanations.

### 5. Performance Analytics (`/lib/features/analytics`)
- **Global Report:** A centralized analytics dashboard featuring rich, interactive charts (`fl_chart`).
- **Progress Tracking:** Insights into strength and weakness areas to help optimize study time.

### 6. User Profile & Dashboard (`/lib/features/profile`)
- **Profile Dashboard:** The main user hub for navigating through stats, settings, and quick actions.
- **Bookmarked Questions:** A dedicated repository for saving, organizing, and revisiting challenging questions.
- **Wellbeing & Stress Management:** Unique features and tools incorporated directly into the app to help students manage exam anxiety and maintain mental wellness.

### 7. Goal Setting (`/lib/features/goals`)
- **Target Scores:** Dedicated screens for users to set, visualize, and track their desired Qiyas exam scores.

### 8. Study Plan (`/lib/features/study_plan`)
- **Personalized Setup:** Tools to generate and maintain a structured, achievable study schedule leading up to the exam day.

### 9. Gamification & Leaderboard (`/lib/features/leaderboard`)
- **Competitive Ranking:** A leaderboard system to track performance relative to peers, encouraging engagement and continuous improvement.

### 10. Subscriptions & Premium Features (`/lib/features/subscriptions`)
- **Paywall Integration:** Monetization setup using `purchases_flutter` (RevenueCat) to gate premium content.
- **Plan Selection:** Interfaces for users to browse and select subscription tiers.

## 🛠 Tech Stack

QiyasReady leverages a modern Flutter stack to ensure high performance, maintainability, and a premium user experience.

- **Framework:** [Flutter](https://flutter.dev/) (SDK >=3.3.0)
- **State Management:** `flutter_riverpod`
- **Backend & Database:** Firebase (Authentication, Cloud Firestore, Cloud Messaging)
- **UI & Styling:**
  - `google_fonts` for modern typography
  - `fl_chart` for rich data visualization
  - Custom `_C` color palette design system
- **Monetization:** `purchases_flutter` (RevenueCat)
- **Utilities:** 
  - `flutter_local_notifications` for reminders
  - `connectivity_plus` for network state management
  - `screen_protector` for content security

## 📁 Project Structure

The project follows a feature-first architecture (`/lib`):
- `/app` - Top-level app configurations and routing.
- `/core` - Foundational services, themes, security, and global Firebase instances.
- `/features` - Isolated business logic, UI, and state for each application domain.
- `/shared` - Common widgets and reusable UI components.

## 🏃 Getting Started

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
2. **Environment Variables:**
   Ensure your `.env` file is present in the root directory for API keys and configurations.
3. **Run the App:**
   ```bash
   flutter run
   ```
