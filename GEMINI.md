# Project Overview

This is a Flutter-based mobile application for a dating app called "eavzappl". The app is designed for both Android and iOS platforms. It uses Firebase for its backend services, including authentication, database, storage, and push notifications.

## Main Technologies

- **Frontend:** Flutter
- **Backend:** Firebase (Authentication, Firestore, Realtime Database, Storage, Cloud Messaging, App Check, Crashlytics, Analytics)
- **State Management:** GetX
- **Image Handling:** image_picker, image_cropper, cached_network_image
- **UI:** cupertino_icons, intl_phone_field, flutter_image_slider, carousel_slider
- **Utilities:** intl, path, url_launcher, http, googleapis, googleapis_auth, equatable, json_annotation, logger, path_provider, shared_preferences, permission_handler, flutter_dotenv

## Architecture

The application follows a feature-based directory structure. The `lib` directory contains the following modules:

-   `authenticationScreen`: Handles user login and registration UI.
-   `controllers`: Contains the business logic for various features.
-   `homeScreen`: The main screen of the app, which contains the bottom tab navigation.
-   `models`: Defines the data models for the application, such as `Person`.
-   `pushNotifications`: Manages push notifications using Firebase Cloud Messaging.
-   `splashScreen`: The initial screen shown to the user during app launch.
-   `tabScreens`: Contains the different screens accessible from the bottom navigation bar (`SwipingScreen`, `ViewReceivedScreen`, `FavouriteSentScreen`, `LikeSentLikeReceivedScreen`, `UserDetailsScreen`).
-   `widgets`: Contains reusable UI components, such as `ProfileGridItem`.

## State Management

The project uses GetX for state management and dependency injection. The main controllers are:

-   `AuthenticationController`: Manages user authentication (login, registration, logout), and handles the initial navigation logic.
-   `ProfileController`: Manages the current user's profile, as well as fetching and displaying other users' profiles.
-   `LikeController`: Manages the liking and unliking of profiles.
-   `LocationController`: Manages location-related functionalities.
-   `PushNotifications`: Manages push notifications.

## Firebase Integration

The project is deeply integrated with Firebase services:

-   **Firebase Authentication:** Handles user authentication using email/password and phone number.
-   **Cloud Firestore:** The primary database for storing user data, including profiles, likes, and favorites.
-   **Firebase Storage:** Used to store user-uploaded images (profile pictures and gallery images).
-   **Firebase Cloud Messaging:** Used for push notifications.
-   **Firebase App Check:** Helps protect the backend from abuse.
-   **Firebase Crashlytics:** For crash reporting.
-   **Firebase Analytics:** For analytics and tracking user engagement.

## Image Handling

The app has a complete pipeline for handling images:

1.  **Image Picking:** `image_picker` is used to select images from the gallery or capture them with the camera.
2.  **Image Cropping:** `image_cropper` is used to crop the selected images.
3.  **Image Compression:** Images are compressed before being uploaded to save storage space and bandwidth.
4.  **Image Uploading:** Images are uploaded to Firebase Storage.
5.  **Image Display:** `cached_network_image` is used to efficiently display and cache network images. The app also has a fallback mechanism to display placeholder images if a user's profile picture is not available.

## Building and Running

To build and run the project, you need to have the Flutter SDK installed.

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    ```
2.  **Set up Firebase:**
    -   Create a new Firebase project.
    -   Add an Android app to your Firebase project with the package name `com.blerdguild.eavzappl`.
    -   Download the `google-services.json` file and place it in the `android/app` directory.
    -   Add an iOS app to your Firebase project.
    -   Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory.
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

## Development Conventions

-   **State Management:** The project uses GetX for state management.
-   **Coding Style:** The code follows the standard Dart and Flutter coding conventions.
-   **File Naming:** File names are in `snake_case`.
-   **Testing:** The project has a `test` directory, but it only contains a default widget test.
