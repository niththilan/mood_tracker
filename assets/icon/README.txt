MOOD TRACKER APP ICON SETUP INSTRUCTIONS

You need to add a 1024x1024 PNG icon file at:
/Users/niththilan/Desktop/devolopment/mood_tracker/assets/icon/app_icon.png

ICON IDEAS FOR MOOD TRACKER:
1. 😊 Emoji-based: Combine multiple mood emojis in a circle
2. 📊 Chart-based: Simple bar chart or graph icon
3. 💝 Heart-based: Heart with different colors/emotions
4. 📱 Modern: Clean, minimalist design with mood indicators

WHERE TO GET ICONS:
1. Canva.com (free templates)
2. Figma (design your own)
3. Icons8.com (mood/emotion icons)
4. Freepik.com (free with attribution)

RECOMMENDED DESIGN:
- Background color: #6366F1 (indigo, matching your app theme)
- Main element: Stylized emoji or simple mood indicator
- Text: Avoid small text (won't be readable at small sizes)
- Style: Rounded corners, modern flat design

Once you have your icon file, run:
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter clean
flutter build apk --release
