# RealEst: Property Swiping & Client Matching Software

RealEst is a cross-platform Flutter application that enables realtors and investors to connect efficiently through intelligent property matching, personalized dashboards, and secure authentication.

---

## Complete API Documentation

For full documentation including all files, classes, methods, and detailed comments:

- Navigate to: doc/api/
- Open index.html in your browser

This comprehensive documentation includes:

- Detailed descriptions of all modules and files
- Complete API reference
- Code comments and usage examples
- Inheritance diagrams and type information
- For the best viewing experience, we recommend using Chrome or Firefox.

Note: Documentation is generated from source code comments - ensure you have the latest version of the codebase for accurate documentation.

---

## 📁 Project Structure

```bash
lib/
├── data/
│   └── db/
│       └── entity/
│           ├── listing.dart           # Listing model for property data
│           ├── settings.dart          # User preferences/settings model
│           ├── swipe.dart             # Model for tracking swipes
│           └── user.dart              # Core user model (investor/realtor)
│
├── services/
│   ├── auth_service.dart              # Handles sign up, login, logout, update
│   ├── calculator_service.dart        # Contains affordability, PITI, ROI calculators
│   └── realtor_settings_service.dart  # Manages realtor filter and settings
│
├── src/
│   ├── config/                        # Constants and environment-specific setup
│   ├── models/                        # Business logic models (e.g., PropertyFilter)
│   └── views/
│       ├── calculators/               # UI for affordability and rental tools
│       ├── home/
│       │   └── overview/              # Landing page, about section, hero panels
│       ├── investor/
│       │   ├── swipe_view.dart        # Main investor swiping interface
│       │   ├── saved.dart             # Saved listings view
│       │   └── disliked.dart          # Disliked properties view
│       └── realtor/
│           ├── dashboard/             # Realtor analytics and activity tracking
│           ├── clients/               # Panels for managing clients/leads
│           ├── helpers/               # Firebase query helpers, card builders, etc.
│           └── widgets/               # Reusable UI components like buttons, cards
│
├── util/
│   ├── firebase_options.dart          # Firebase config (auto-generated)
│   ├── theme_provider.dart            # Theme management (dark/light mode)
│   └── property_fetch_helpers.dart    # API integration with HomeHarvest
│
├── user_provider.dart                 # Global provider for current user info
├── main.dart                          # App entry point, routes, and initialization
```

### Class Models

- **User**: Represents app users (realtors, investors); includes `email`, `role`, `completedSetup`, `createdAt`
- **Listing**: Stores property metadata such as location, price, images, and tags
- **Swipe**: Tracks swipe direction, timestamp, and user-listing interactions
- **Settings**: Manages investor/realtor preferences (e.g., budget, location filters)

### Filter & Logic Models (`src/models/`)

- **PropertyFilter**: Stores dynamic filters applied by investors (e.g., price range, radius, type)

### Service Classes (`services/`)

- **AuthService**: Handles login, signup, sign out, and user updates
- **CalculatorService**: Affordability, mortgage (PITI), and ROI calculators
- **RealtorSettingsService**: Saves and loads realtor preferences from Firestore

### State Management

- **UserProvider**: Global state for the current user
- **ThemeProvider**: Manages app-wide light/dark theme

### Views & Widgets (`src/views/`)

- Investor and Realtor views are separated by role
- Each screen is a `StatefulWidget` or `StatelessWidget`
- Reusable UI components are found in `widgets/`
- Logic is abstracted into `helpers/` for separation of concerns

All models support `fromJson()` and `toJson()` for Firestore integration.

---

## ⚙️ API Specification

### 🔐 Firebase Authentication

Implemented via `auth_service.dart`:

- `createUserWithEmailAndPassword(email, password)`
- `signInWithEmailAndPassword(email, password)`
- `signOut()`
- `updateEmail(newEmail)`
- `updatePassword(newPassword)`
- `sendPasswordResetEmail(email)`

### ⚡ Firebase Cloud Function: `promoteQualifiedLead`

A secure callable function that allows realtors to promote a user to a qualified investor.

**Functionality**:
- Verifies that the caller is a realtor
- Creates a Firebase Auth user
- Sets up a Firestore profile under `/users`
- Updates `/investors` status to `qualified-lead`
- Sends a welcome email via SendGrid with a temporary password

**Returns**:
- `success: true`
- `uid`
- `password`

### 🌍 External APIs

#### Algolia

- Real-time property and user search
- Uses `ALGOLIA_APP_ID` and `ALGOLIA_API_KEY`

#### Google Maps

- Interactive property mapping and distance filtering
- API key is manually added in code

#### HomeHarvest

- Provides property listing data (price, location, attributes)
- Accessed via `property_fetch_helpers.dart`

---

## 🛠 Setup Guide

### Step 1: Install Required Command Line Tools

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK (included with Flutter)
- [Git](https://git-scm.com/downloads)
- [Node.js](https://nodejs.org/en)
- Firebase CLI:
```bash
  npm install -g firebase-tools
```
- FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```
- Clone the Repository
```bash
git clone https://github.com/Realest-TAMU-Capstone-Spring-2025.git
cd Realest-TAMU-Capstone-Spring-2025
```
- Install Dependencies
```bash
flutter pub get
```
### Step 2: Configure Firebase

From your project directory, run:

```bash
flutterfire configure
```
If you get an error about null strings, run the previous command just for android + ios
manually check the `firebase_options.dart` file. Create a `FirebaseOptions` object for web and return that .

This will:

- Guide you through creating or selecting a Firebase project
- Register your app with Firebase
- Generate the necessary configuration files (`firebase_options.dart`)


### Step 3: Initialize Firebase in Your App

Add Firebase core to your project:

```bash
flutter pub add firebase_core
```

Ensure your `lib/main.dart` file initializes Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```


### Step 4: Add Required Firebase Plugins

Add the Firebase plugins needed for the project:

```bash
flutter pub get
```


## Required API Keys

The application requires several API keys to function properly. Create a `.env` file in the root directory with the following keys:

```
# Algolia API Keys
ALGOLIA_APP_ID=your_algolia_app_id
ALGOLIA_API_KEY=your_algolia_api_key

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```
**Note:** Google maps key won't work with `.env` you need to do that manually.

**Note:** Make sure to add the `.env` file to your `.gitignore` to prevent exposing sensitive keys.

## Firebase Configuration File

Ensure you have the `firebase.json` file in your project root. This file is typically generated during the Firebase initialization process. If it's missing, create it with the following content:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```


## Running the App

Once everything is set up, you can run the app using:

```bash
flutter run
```


## Deployment

To deploy the web version to Firebase Hosting:

```bash
flutter build web --release
firebase deploy
```


## Troubleshooting

If you encounter issues with Firebase configuration:

1. Ensure all required files (`firebase_options.dart`, `firebase.json`, etc.) are present
2. Verify that you've added the correct Google Services files:
   - `google-services.json` in the `android/app` directory
   - `GoogleService-Info.plist` in the `ios/Runner` directory
3. Make sure all environment variables and API keys are properly configured

## Contributing

Please read our contributing guidelines before submitting pull requests to the project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
