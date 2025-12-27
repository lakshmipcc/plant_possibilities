# 🌱 Plant Possibilities

Discover your plant's potential! **Plant Possibilities** is a beautiful, responsive Flutter web application that uses Google's Gemini AI to identify plants from photos and provide interesting botanical facts.

![Plant Possibilities Header](https://images.unsplash.com/photo-1545239351-ef35f43d514b?auto=format&fit=crop&q=80&w=1000)

## ✨ Features

- **AI-Powered Identification**: Leverages **Gemini 1.5 Flash** to identify plants and provide their common and scientific names.
- **Glanceable Results**: Quick facts and identification details presented in a clean, modern card.
- **Offline / Manual Fallback**: A robust manual mode that allows you to provide your own plant data if the API is unavailable.
- **Earth-Toned Design**: A calming, premium UI built with a custom Sage Green, Terracotta, and Cream palette.
- **Responsive Web**: Optimized for large screens and mobile browsers alike.

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Gemini API Key from [Google AI Studio](https://aistudio.google.com/).

### 2. Environment Setup
Create an environment file at `assets/.env`:
```env
GEMINI_API_KEY=your_api_key_here
```

### 3. Manual Data (Optional)
To use the manual fallback, create `assets/plants/plants_data.json`:
```json
{
  "my_plant.jpg": {
    "commonName": "Swiss Cheese Plant",
    "scientificName": "Monstera deliciosa",
    "funFact": "It can grow up to 30 feet tall in the wild!"
  }
}
```

### 4. Run the App
```bash
flutter pub get
flutter run -d chrome
```

## 🛠️ Tech Stack
- **Framework**: [Flutter](https://flutter.dev)
- **AI Service**: [Google Generative AI SDK](https://pub.dev/packages/google_generative_ai)
- **Environment Management**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)
- **Asset Picking**: [file_picker](https://pub.dev/packages/file_picker)

## 🤝 Contributing
Feel free to fork this project and add your own plant-tastic features!

---
*Created with ❤️ by lakshmipcc*
