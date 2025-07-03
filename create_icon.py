#!/usr/bin/env python3
"""
Create a custom mood tracker app icon
This script generates a 1024x1024 PNG icon for the mood tracker app
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_mood_icon():
    # Create a 1024x1024 canvas
    size = 1024
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Background circle with gradient-like effect
    center = size // 2
    radius = size // 2 - 40
    
    # Create a modern gradient background
    for i in range(radius, 0, -2):
        # Calculate color for gradient (light blue to purple)
        progress = 1 - (i / radius)
        r = int(100 + progress * 100)  # 100 to 200
        g = int(150 + progress * 50)   # 150 to 200  
        b = int(255 - progress * 50)   # 255 to 205
        
        draw.ellipse(
            [center - i, center - i, center + i, center + i],
            fill=(r, g, b, 255)
        )
    
    # Draw mood indicators as colorful dots around the circle
    mood_colors = [
        (255, 100, 100),  # Red - angry/sad
        (255, 165, 0),    # Orange - frustrated
        (255, 255, 100),  # Yellow - neutral
        (150, 255, 150),  # Light green - good
        (100, 255, 100),  # Green - great
    ]
    
    import math
    for i, color in enumerate(mood_colors):
        angle = (i / len(mood_colors)) * 2 * math.pi - math.pi/2
        dot_x = center + int((radius - 80) * math.cos(angle))
        dot_y = center + int((radius - 80) * math.sin(angle))
        dot_radius = 35
        
        draw.ellipse(
            [dot_x - dot_radius, dot_y - dot_radius, 
             dot_x + dot_radius, dot_y + dot_radius],
            fill=color + (255,)
        )
    
    # Draw a central symbol - a simple heart for mood/emotion
    heart_size = 120
    heart_x = center - heart_size // 2
    heart_y = center - heart_size // 2
    
    # Simple heart shape using two circles and a triangle
    circle_r = heart_size // 4
    # Left circle
    draw.ellipse([
        heart_x, heart_y,
        heart_x + circle_r * 2, heart_y + circle_r * 2
    ], fill=(255, 255, 255, 255))
    
    # Right circle
    draw.ellipse([
        heart_x + circle_r, heart_y,
        heart_x + circle_r * 3, heart_y + circle_r * 2
    ], fill=(255, 255, 255, 255))
    
    # Bottom triangle (heart point)
    triangle_points = [
        (heart_x + circle_r // 2, heart_y + circle_r),
        (heart_x + heart_size - circle_r // 2, heart_y + circle_r),
        (heart_x + heart_size // 2, heart_y + heart_size)
    ]
    draw.polygon(triangle_points, fill=(255, 255, 255, 255))
    
    return image

def main():
    print("Creating mood tracker app icon...")
    
    # Create the icon
    icon = create_mood_icon()
    
    # Save the icon
    icon_path = "/Users/niththilan/Desktop/devolopment/mood_tracker/assets/icon/app_icon.png"
    icon.save(icon_path, "PNG")
    
    print(f"✅ Icon created successfully at: {icon_path}")
    print(f"📏 Size: 1024x1024 pixels")
    print(f"📁 File size: {os.path.getsize(icon_path) / 1024:.1f} KB")

if __name__ == "__main__":
    main()
