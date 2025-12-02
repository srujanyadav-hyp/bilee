# Firebase Configuration

## Setup Instructions

### 1. Install FlutterFire CLI

If you haven't already installed the FlutterFire CLI, run:

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase for Your Project

Run the following command in your project root to generate the Firebase configuration:

```bash
flutterfire configure
```

This will:
- Prompt you to select or create a Firebase project
- Generate a `firebase_options.dart` file in the `lib/` directory
- Configure Firebase for all platforms (Android, iOS, Web, etc.)

### 3. Replace the Placeholder File

After running `flutterfire configure`:
- The generated `lib/firebase_options.dart` will contain your real Firebase project credentials
- You can remove or replace `lib/firebase_options_dev.dart` with the generated file
- Update your imports to use the real configuration

### 4. Update Your Main Application

In your `main.dart`, initialize Firebase with the generated options:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import the generated file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## Security Notes

⚠️ **IMPORTANT: Never commit sensitive Firebase credentials to version control!**

- The real `firebase_options.dart` file is added to `.gitignore`
- Service account keys and private keys must **never** be committed
- Use environment-specific configurations for development, staging, and production
- For CI/CD pipelines, use secure secret management (GitHub Secrets, environment variables, etc.)

## Production Configuration

For production deployments:
1. Create separate Firebase projects for dev, staging, and production
2. Generate separate `firebase_options.dart` files for each environment
3. Use build flavors or environment variables to switch configurations
4. Store production credentials securely (e.g., CI/CD secrets, secure vaults)

## Troubleshooting

If you encounter issues:
- Ensure you're logged into the correct Google account with Firebase access
- Verify that the Firebase project exists and you have the necessary permissions
- Check that all required Firebase services are enabled in the Firebase Console
- Run `firebase login` if authentication fails

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI Documentation](https://firebase.flutter.dev/docs/cli)
