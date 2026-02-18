# 🔧 Troubleshooting: Flutter Not Running

## Issue: Flutter processes stuck or conflicting

### Quick Fix - Option 1: Use the Batch Script

I've created a batch script that will clean everything up and run the app:

```bash
# Just run this:
.\run_app.bat
```

This script will:
1. Kill any stuck Flutter/Dart processes
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run -d chrome`

---

### Quick Fix - Option 2: Manual Steps

If the batch script doesn't work, follow these steps:

#### Step 1: Kill Stuck Processes
```powershell
# Open a NEW PowerShell window and run:
taskkill /F /IM dart.exe
taskkill /F /IM flutter.exe
```

#### Step 2: Clean the Project
```bash
flutter clean
```

#### Step 3: Get Dependencies
```bash
flutter pub get
```

#### Step 4: Run the App
```bash
flutter run -d chrome
```

---

### Quick Fix - Option 3: Restart VS Code

Sometimes the easiest fix is:
1. Close ALL terminal windows in VS Code
2. Close VS Code completely
3. Reopen VS Code
4. Open a new terminal
5. Run: `flutter run -d chrome`

---

## Common Issues

### Issue: "Terminate batch job (Y/N)?"

**Cause**: A Flutter process is still running in the background

**Solution**:
1. Type `y` and press Enter to terminate
2. Wait a few seconds
3. Run `flutter run -d chrome` again

---

### Issue: "Waiting for another flutter command to release the startup lock"

**Cause**: Another Flutter command is running

**Solution**:
```powershell
# Kill all Flutter processes
taskkill /F /IM dart.exe
taskkill /F /IM flutter.exe

# Wait 5 seconds, then try again
flutter run -d chrome
```

---

### Issue: Compilation errors about missing fields

**Cause**: The code was updated but not recompiled

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

---

## Verify the Fixes

After the fixes, you should see:

```
✅ authBaseUrl is defined in api_config.dart (line 31)
✅ chatBaseUrl is defined in api_config.dart (line 34)
✅ baseUrl is set to 'https://api-chatbot.fuzionest.com'
```

Check the file `lib/core/config/api_config.dart` - you should see:

```dart
static const String baseUrl = 'https://api-chatbot.fuzionest.com';

/// Auth base URL (for AuthService)
static const String authBaseUrl = '$baseUrl/auth';

/// Chat base URL (for ChatRepository)
static const String chatBaseUrl = '$baseUrl/chat';
```

---

## Expected Output When Running

When you run `flutter run -d chrome`, you should see:

```
Launching lib\main.dart on Chrome in debug mode...
Building application for the web...
✓ Built build\web
Launching lib\main.dart on Chrome in debug mode...
```

Then Chrome should open with your app showing:
1. **Splash screen** (briefly)
2. **Login screen** (if no token)

---

## Test the Login

Once the app is running:

1. **Enter email**: Your email
2. **Enter password**: Your password
3. **Click Login**

Expected result:
- API call to `https://api-chatbot.fuzionest.com/auth/login`
- Token saved to Secure Storage
- Redirect to chat screen

---

## If Still Not Working

### Check 1: Verify API Config
```bash
# Open the file and check line 28:
lib/core/config/api_config.dart
```

Should see:
```dart
static const String baseUrl = 'https://api-chatbot.fuzionest.com';
```

### Check 2: Verify No Compilation Errors
```bash
flutter analyze
```

Should show: "No issues found!"

### Check 3: Check Chrome is Available
```bash
flutter devices
```

Should show Chrome in the list.

---

## Alternative: Run on Windows Desktop

If Chrome is giving issues, try Windows desktop:

```bash
flutter run -d windows
```

---

## Need More Help?

If none of these work:

1. **Check Flutter version**:
   ```bash
   flutter --version
   ```

2. **Check Flutter doctor**:
   ```bash
   flutter doctor
   ```

3. **Try a different device**:
   ```bash
   flutter devices
   flutter run -d edge    # or
   flutter run -d windows
   ```

---

**Most Common Solution**: Close all terminals, restart VS Code, and run `flutter run -d chrome` in a fresh terminal.
