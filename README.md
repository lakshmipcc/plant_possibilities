# 🌱 Plant Possibilities (v2.6)

Discover your plant's potential! **Plant Possibilities** is a beautiful, responsive PWA (Progressive Web App) that uses Google's Gemini AI to identify plants from photos and provide interesting botanical facts.

![Plant Possibilities Header](assets/header.png)

## 🚀 Live Demo
**Try it here**: [https://lakshmipcc.github.io/plant_possibilities/](https://lakshmipcc.github.io/plant_possibilities/)

## ✨ Features

- **📱 Full PWA Support**: Installable on iPhone and Android. Works as a standalone app without the browser bar.
- **📸 Live Camera Integration**: Snap a photo directly in the garden for instant identification.
- **🤖 Multi-Model Fallback**: Sequentially tries `gemini-flash-latest`, `gemini-2.0-flash`, and `gemini-pro-latest` to ensure maximum compatibility.
- **🔒 Secure Architecture**: API keys are injected via `--dart-define`, keeping your credentials out of the public source code.
- **🌿 Earth-Toned Design**: A calming UI built with a custom Sage Green, Terracotta, and Cream palette.

## 🛠️ Tech Stack
- **Framework**: [Flutter](https://flutter.dev) (Web/PWA)
- **AI Service**: [Google Generative AI](https://pub.dev/packages/google_generative_ai)
- **Camera**: [image_picker](https://pub.dev/packages/image_picker)
- **Deployment**: [GitHub Actions](https://github.com/features/actions)

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Gemini API Key from [Google AI Studio](https://aistudio.google.com/).

### 2. Run the App Locally (Secure Method)
To keep your key safe, run the app using the `dart-define` flag:
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_new_key_here
```

### 3. Deployment
The app is configured to deploy automatically via GitHub Actions. To make the live link work:
1. Go to **Settings** -> **Secrets and variables** -> **Actions**.
2. Add a new secret named `GEMINI_API_KEY`.
3. Push to the `main` branch.

## 🤝 Contributing
Feel free to fork this project and add your own plant-tastic features!

---
*Created with ❤️ by lakshmipcc*
