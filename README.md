# RealEst: Property Swiping \& Client Matching Software

RealEst is a Flutter application that helps users and realtors effectively communicate their preferences.

## Getting Started

https://firebase.google.com/docs/flutter/setup?platform=web

This is a good guide for setting up

### Prerequisites

Before setting up the project, ensure you have the following installed:

- Flutter SDK (latest stable version)
- Dart SDK
- Git
- Firebase CLI
- FlutterFire CLI


### Clone the Repository

```bash
git clone https://github.com/Realest-TAMU-Capstone-Spring-2025.git
cd Realest-TAMU-Capstone-Spring-2025
```


### Install Dependencies

Run the following command to install all required dependencies:

```bash
flutter pub get
```


## Firebase Setup

### Step 1: Install Required Command Line Tools

If you haven't already, install the Firebase CLI and log in:

```bash
npm install -g firebase-tools
firebase login
```

Install the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
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