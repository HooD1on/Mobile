# Testing Methods

## Method 1
This method is more complex. Install Android Studio, set up the Flutter environment, and install all dependencies required by the code. After that, you can run the `main.dart` file to test the application.

## Method 2
We have compressed the complete code files into a ZIP format and submitted it on Canvas. In the `\build\app\outputs\flutter-apk` folder, you will find the generated APK file, which can be directly tested on a real device or an emulator.

## Method 3
In the root directory, open the command line and enter the following command:
```bash
flutter build apk --debug
```
This will automatically generate an APK file, which can also be tested on an emulator or a real device.

Note: Currently, only the Android version is supported. Due to the lack of a developer account and the complex configuration requirements, iOS adaptation has not been implemented.

