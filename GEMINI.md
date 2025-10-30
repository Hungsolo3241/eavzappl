
# Project Overview

This is a Flutter-based mobile application for a dating app called "eavzappl". The app is designed for both Android and iOS platforms. It uses Firebase for its backend services, including authentication, database, storage, and push notifications.

## Main Technologies

- **Frontend:** Flutter
- **Backend:** Firebase (Authentication, Firestore, Realtime Database, Storage, Cloud Messaging, App Check)
- **State Management:** GetX
- **Image Handling:** image_picker, image_cropper
- **Location:** intl_phone_field

## Architecture

The application follows a feature-based directory structure. The `lib` directory contains the following modules:

- `authenticationScreen`: Handles user login and registration.
- `controllers`: Contains the business logic for various features like authentication, profile management, and likes.
- `homeScreen`: The main screen of the app, which contains the tab navigation.
- `models`: Defines the data models for the application, such as `Person`.
- `pushNotifications`: Manages push notifications using Firebase Cloud Messaging.
- `splashScreen`: The initial screen shown to the user.
- `tabScreens`: Contains the different screens accessible from the bottom navigation bar.
- `widgets`: Contains reusable UI components.

## Building and Running

To build and run the project, you need to have the Flutter SDK installed.

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

**Note:** You will need to set up a Firebase project and add the `google-services.json` file to the `android/app` directory and the `GoogleService-Info.plist` file to the `ios/Runner` directory.

## Development Conventions

- **State Management:** The project uses GetX for state management.
- **Coding Style:** The code follows the standard Dart and Flutter coding conventions.
- **File Naming:** File names are in `snake_case`.
- **Testing:** The project has a `test` directory, but it only contains a default widget test.

