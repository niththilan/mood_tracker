#!/usr/bin/env python3
"""
Script to generate app icons for the MoodFlow app.
This script creates PNG icons in various sizes needed for Android and iOS.
"""

import os
from PIL import Image, ImageDraw, ImageFont
import math

def create_mood_ring_icon(size, primary_color=(103, 80, 164), bg_color=(237, 231, 246)):
    """Create a mood ring icon similar to the Flutter widget."""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Add background circle
    padding = size * 0.05
    draw.ellipse([padding, padding, size - padding, size - padding], 
                 fill=bg_color + (255,))
    
    # Draw mood dots around the edge
    center = size // 2
    radius = (size // 2) - (size * 0.2)
    
    mood_colors = [
        (76, 175, 80),   # Happy - Green
        (255, 152, 0),   # Neutral - Orange  
        (33, 150, 243),  # Sad - Blue
        (156, 39, 176),  # Tired - Purple
        (244, 67, 54),   # Angry - Red
        (233, 30, 99),   # Love - Pink
    ]
    
    dot_size = size * 0.08
    for i, color in enumerate(mood_colors):
        angle = (i * 2 * math.pi) / len(mood_colors)
        x = center + radius * math.cos(angle) - dot_size // 2
        y = center + radius * math.sin(angle) - dot_size // 2
        
        # Draw dot with slight glow
        glow_size = dot_size * 1.5
        glow_x = center + radius * math.cos(angle) - glow_size // 2
        glow_y = center + radius * math.sin(angle) - glow_size // 2
        
        draw.ellipse([glow_x, glow_y, glow_x + glow_size, glow_y + glow_size],
                     fill=color + (80,))
        draw.ellipse([x, y, x + dot_size, y + dot_size],
                     fill=color + (255,))
    
    # Draw center circle
    center_size = size * 0.5
    center_padding = (size - center_size) // 2
    
    # Gradient effect for center (simplified)
    for i in range(int(center_size // 2)):
        alpha = int(255 * (1 - i / (center_size // 2)))
        color_with_alpha = primary_color + (alpha,)
        draw.ellipse([
            center_padding + i, 
            center_padding + i,
            center_padding + center_size - i,
            center_padding + center_size - i
        ], fill=color_with_alpha)
    
    # Add emoji-like face
    face_size = size * 0.15
    eye_size = size * 0.025
    
    # Eyes
    left_eye_x = center - face_size * 0.3
    right_eye_x = center + face_size * 0.3
    eye_y = center - face_size * 0.2
    
    draw.ellipse([left_eye_x - eye_size, eye_y - eye_size,
                  left_eye_x + eye_size, eye_y + eye_size], fill=(255, 255, 255, 255))
    draw.ellipse([right_eye_x - eye_size, eye_y - eye_size,
                  right_eye_x + eye_size, eye_y + eye_size], fill=(255, 255, 255, 255))
    
    # Smile
    smile_y = center + face_size * 0.1
    smile_width = face_size * 0.6
    draw.arc([center - smile_width//2, smile_y - smile_width//4,
              center + smile_width//2, smile_y + smile_width//4],
             start=0, end=180, fill=(255, 255, 255, 255), width=int(size * 0.02))
    
    # Add "MF" text
    try:
        # Try to use a nice font, fall back to default if not available
        font_size = int(size * 0.08)
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
    except:
        font = ImageFont.load_default()
    
    text = "MF"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    text_x = center - text_width // 2
    text_y = center + face_size * 0.4 - text_height // 2
    
    draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    
    return img

def generate_icons():
    """Generate all required icon sizes."""
    # Create output directory
    icon_dir = "assets/icon/generated"
    os.makedirs(icon_dir, exist_ok=True)
    
    # Icon sizes for different platforms
    sizes = {
        # Android sizes (mipmap folders)
        'android_mdpi': 48,
        'android_hdpi': 72,
        'android_xhdpi': 96,
        'android_xxhdpi': 144,
        'android_xxxhdpi': 192,
        
        # iOS sizes
        'ios_20': 20,
        'ios_29': 29,
        'ios_40': 40,
        'ios_58': 58,
        'ios_60': 60,
        'ios_80': 80,
        'ios_87': 87,
        'ios_120': 120,
        'ios_180': 180,
        'ios_1024': 1024,
        
        # General sizes
        'small': 64,
        'medium': 128,
        'large': 256,
        'xlarge': 512,
    }
    
    print("Generating MoodFlow app icons...")
    
    for name, size in sizes.items():
        print(f"Creating {name} icon ({size}x{size})")
        icon = create_mood_ring_icon(size)
        icon.save(f"{icon_dir}/icon_{name}_{size}x{size}.png", "PNG")
    
    # Create the main app icon
    main_icon = create_mood_ring_icon(512)
    main_icon.save("assets/icon/app_icon_new.png", "PNG")
    
    print(f"\nIcons generated in {icon_dir}/")
    print("Main app icon saved as assets/icon/app_icon_new.png")
    print("\nTo use these icons:")
    print("1. For Android: Copy appropriate sizes to android/app/src/main/res/mipmap-* folders")
    print("2. For iOS: Use Xcode to add icons to the app")
    print("3. Or use flutter_launcher_icons package for automatic setup")

if __name__ == "__main__":
    try:
        generate_icons()
    except ImportError:
        print("Error: PIL (Pillow) is required to generate icons.")
        print("Install it with: pip install Pillow")
    except Exception as e:
        print(f"Error generating icons: {e}")
