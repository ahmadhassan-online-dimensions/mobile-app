/// Where the app talks to. Defaults are the live VUE & OR site; override at
/// build time, e.g. for a local backend on the Android emulator:
///   flutter run --dart-define=API_URL=http://10.0.2.2:8080/api
class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://jewels.online-dimensions.com/api');

  /// Product and lifestyle photos are served by the website.
  static const imageBaseUrl = String.fromEnvironment(
    'IMAGE_URL',
    defaultValue: 'https://jewels.online-dimensions.com/images',
  );

  /// Google "Web application" OAuth client used by the website; the backend
  /// checks Google ID tokens against it. Android sign-in also needs an Android
  /// OAuth client (package name + SHA-1) in the same Google Cloud project.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '37189538495-nh81tedlmdr6i3m92adb2kudpno5dd0f.apps.googleusercontent.com',
  );

  static String image(String file) => '$imageBaseUrl/$file';
}
