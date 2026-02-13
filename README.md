# مترجم الحرم - Real-Time Multilingual Speech Translator

A Flutter application for holy shrine visitors enabling real-time speech translation between Arabic and multiple languages (English, Kurdish, Persian, Urdu) using Soniox API v4.

## Project Status

✅ **FULLY IMPLEMENTED & READY TO TEST!**

**Phase 1 ✓ - Foundation & Architecture**
- Project structure with clean architecture
- GetX state management configured
- Arabic RTL UI theme with Cairo font
- Data models with JSON serialization
- Constants and configuration

**Phase 2 ✓ - Core Services**
- SonioxService (WebSocket communication with real-time translation)
- AudioService (microphone recording with PCM16 streaming)
- TtsService (text-to-speech for 5 languages)
- StorageService (Hive local persistence)
- PermissionService (microphone permissions)
- TranslationRepository (orchestrates all services)

**Phase 3 ✓ - Controllers & UI**
- TranslatorController with full business logic
- Beautiful main translator screen with Arabic RTL
- Custom widgets (RecordButton, AudioVisualizer, TranslationDisplay, etc.)
- Language selector with swap functionality
- Connection status indicator
- Floating action buttons (speak, history, settings)

**Phase 4 ✓ - Platform Configuration**
- Android microphone permissions added
- iOS microphone permissions with Arabic descriptions
- App compiles successfully with zero errors!

## Project Structure

```
lib/
├── main.dart                          # Entry point with GetX and RTL
├── app/
│   ├── routes/                        # Navigation routes
│   ├── services/                      # Core services (TODO)
│   └── themes/                        # Arabic theme configuration
├── bindings/                          # GetX dependency injection
├── core/
│   ├── constants/                     # API, language, storage constants
│   ├── utils/                         # Utilities (TODO)
│   └── widgets/                       # Reusable widgets (TODO)
├── data/
│   ├── models/                        # Data models (✓ Complete)
│   ├── providers/                     # API providers (TODO)
│   └── repositories/                  # Business logic (TODO)
└── features/
    ├── translator/                    # Main translation screen (TODO)
    ├── languages/                     # Language selection (TODO)
    ├── history/                       # Conversation history (TODO)
    └── settings/                      # App settings (TODO)
```

## Key Features (Planned)

1. **Real-time Speech-to-Text + Translation**
   - Live audio capture from microphone
   - Streaming transcription via Soniox WebSocket
   - Bidirectional translation (Arabic ↔ English/Persian/Urdu/Kurdish)

2. **Text-to-Speech Output**
   - Speak translated text aloud in target language
   - Support for Arabic, English, Persian, Urdu

3. **Conversation History**
   - Local storage with Hive
   - Browse past conversations
   - Export/share functionality

4. **Automatic Language Detection**
   - Two-way translation mode
   - Seamless language switching

## Technical Stack

- **Framework**: Flutter (Android + iOS)
- **State Management**: GetX 4.6.6
- **Speech-to-Text**: Soniox API v4 (WebSocket)
- **TTS**: flutter_tts 4.0.2
- **Audio Recording**: record 5.0.4 (PCM16 16kHz)
- **Storage**: Hive 2.2.3
- **UI**: Material 3 with Cairo font (Arabic support)

## Setup Instructions

### Prerequisites

- Flutter SDK 3.10.4+
- Dart SDK
- Soniox API key (get from soniox.com)

### Installation

1. **Navigate to project**:
   ```bash
   cd /home/muq2002/Documents/holy-shrine/speech_translator_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**:
   Edit `.env` file and add your Soniox API key:
   ```env
   SONIOX_API_KEY=your_actual_api_key_here
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Configuration

### Supported Languages

| Language | Code | Soniox Support | TTS Support |
|----------|------|----------------|-------------|
| Arabic   | ar   | ✓              | ✓           |
| English  | en   | ✓              | ✓           |
| Persian  | fa   | ✓              | ✓           |
| Urdu     | ur   | ✓              | ✓           |
| Kurdish  | ku   | ✓              | ? (verify)  |

### Soniox API Configuration

- **WebSocket Endpoint**: `wss://stt-rt.soniox.com/transcribe-websocket`
- **Model**: v4_rt (real-time)
- **Audio Format**: PCM 16-bit little-endian (s16le)
- **Sample Rate**: 16000 Hz
- **Channels**: Mono (1 channel)
- **Translation Mode**: Two-way

## Testing Guide

### Prerequisites
1. **Get Soniox API Key**:
   - Sign up at https://soniox.com
   - Get your API key from the dashboard

2. **Add API Key to .env**:
   ```bash
   cd /home/muq2002/Documents/holy-shrine/speech_translator_app
   # Edit .env file and add:
   SONIOX_API_KEY=your_actual_api_key_here
   ```

### Running the App

```bash
# Make sure you're in the project directory
cd /home/muq2002/Documents/holy-shrine/speech_translator_app

# Check for connected devices
flutter devices

# Run on Android
flutter run

# Run on iOS (macOS only)
flutter run -d ios

# Run on Chrome (for web testing)
flutter run -d chrome
```

### Testing Checklist
- [ ] App launches successfully with Arabic interface
- [ ] Language selector shows Arabic ↔ English by default
- [ ] Swap button switches languages
- [ ] Record button animation works (pulse effect)
- [ ] Microphone permission dialog appears (in Arabic)
- [ ] After granting permission, connection status shows "متصل" (connected)
- [ ] Speaking Arabic shows transcription in "النص الأصلي"
- [ ] Translation appears in "الترجمة" section
- [ ] Audio visualizer shows bars moving with voice
- [ ] Speaker button plays translated text aloud
- [ ] Stop button ends session and saves conversation
- [ ] History button shows saved conversations
- [ ] Settings button opens settings (placeholder)

### Troubleshooting

**Connection Error**:
- Check if .env file has correct Soniox API key
- Verify internet connection
- Check if API key is valid

**No Audio**:
- Grant microphone permission
- Check device microphone is working
- Restart app after granting permission

**No Translation**:
- Speak clearly and slowly
- Check connection status indicator
- Verify selected languages are supported

## Resources

- [Soniox Real-time Translation](https://soniox.com/docs/stt/rt/real-time-translation)
- [Soniox WebSocket API](https://soniox.com/docs/stt/api-reference/websocket-api)
- [Flutter GetX](https://pub.dev/packages/get)

---

**Built for holy shrine visitors** 🕌
