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

## 📊 Usage & Quotas (Free Tier)
This app uses the Gemini API Free Tier with the following approximate limits:
- **Daily Scans**: ~1,500 plants/day (Gemini 1.5 Flash).
- **Simultaneous Users**: Up to 15 requests per minute.
- **Cost**: $0.00 (Completely free for personal and hobby use).

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Gemini API Key from [Google AI Studio](https://aistudio.google.com/).

### 2. Run the App Locally (Secure Method)
To keep your key safe, run the app using the `dart-define` flag:
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_new_key_here
```

### 3. Deployment (Advanced Security)
Since the public web build contains the API key in the code, automated scanners may flag it as leaked. To prevent this, we use **Base64 Encoding**:

1.  **Encode your Key**:
    Run this in your terminal: `echo -n "YOUR_RAW_API_KEY" | base64`
2.  **Add to GitHub Secrets**:
    *   Go to **Settings** -> **Secrets and variables** -> **Actions**.
    *   Update `GEMINI_API_KEY` with the **Encoded String** (it will end with `=` usually and won't start with `AIza`).
3.  **Push or Run Workflow**:
    The app is smart enough to detect the encoded key and decode it automatically!

## 🤝 Contributing
Feel free to fork this project and add your own plant-tastic features!

---
*Created with ❤️ by lakshmipcc*
