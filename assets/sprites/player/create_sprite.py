from PIL import Image, ImageDraw

# Create a 64x96 sprite sheet (4x4 grid of 16x24 frames)
width, height = 64, 96
img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Colors
skin = (255, 220, 177)
hair = (139, 90, 43)
armor_light = (192, 192, 192)
armor_dark = (128, 128, 128)
armor_highlight = (220, 220, 220)
pants = (64, 64, 80)
boots = (80, 50, 30)

def rect(x, y, w, h, color):
    draw.rectangle([x, y, x+w-1, y+h-1], fill=color)

def draw_down_frame(offset_x, offset_y, frame_num):
    bounce = 0 if frame_num == 0 else (1 if frame_num == 1 else (0 if frame_num == 2 else 1))
    y = offset_y + bounce
    
    # Head (4x4)
    rect(offset_x + 6, y, 4, 4, skin)
    rect(offset_x + 6, y, 4, 1, hair)
    rect(offset_x + 6, y + 1, 1, 1, hair)
    rect(offset_x + 9, y + 1, 1, 1, hair)
    
    # Body - armor chest (6x5)
    rect(offset_x + 5, y + 4, 6, 5, armor_light)
    rect(offset_x + 6, y + 4, 4, 1, armor_highlight)
    rect(offset_x + 7, y + 6, 2, 2, armor_dark)
    
    # Arms
    rect(offset_x + 3, y + 5, 2, 4, skin)
    rect(offset_x + 11, y + 5, 2, 4, skin)
    rect(offset_x + 3, y + 5, 2, 2, armor_light)
    rect(offset_x + 11, y + 5, 2, 2, armor_light)
    
    # Legs
    rect(offset_x + 5, y + 9, 2, 4, pants)
    rect(offset_x + 9, y + 9, 2, 4, pants)
    
    # Boots
    rect(offset_x + 5, y + 13, 2, 2, boots)
    rect(offset_x + 9, y + 13, 2, 2, boots)

def draw_up_frame(offset_x, offset_y, frame_num):
    bounce = 0 if frame_num == 0 else (1 if frame_num == 1 else (0 if frame_num == 2 else 1))
    y = offset_y + bounce
    
    rect(offset_x + 6, y, 4, 4, hair)
    rect(offset_x + 7, y + 2, 2, 2, skin)
    
    rect(offset_x + 5, y + 4, 6, 5, armor_light)
    rect(offset_x + 6, y + 4, 4, 1, armor_highlight)
    
    rect(offset_x + 3, y + 5, 2, 4, armor_light)
    rect(offset_x + 11, y + 5, 2, 4, armor_light)
    
    rect(offset_x + 5, y + 9, 2, 4, pants)
    rect(offset_x + 9, y + 9, 2, 4, pants)
    
    rect(offset_x + 5, y + 13, 2, 2, boots)
    rect(offset_x + 9, y + 13, 2, 2, boots)

def draw_left_frame(offset_x, offset_y, frame_num):
    bounce = 0 if frame_num == 0 else (1 if frame_num == 1 else (0 if frame_num == 2 else 1))
    y = offset_y + bounce
    
    rect(offset_x + 6, y, 3, 4, skin)
    rect(offset_x + 6, y, 3, 2, hair)
    
    rect(offset_x + 5, y + 4, 5, 5, armor_light)
    rect(offset_x + 6, y + 4, 3, 1, armor_highlight)
    
    rect(offset_x + 3, y + 5, 2, 4, armor_light)
    rect(offset_x + 10, y + 5, 2, 4, skin)
    
    leg_offset = 0 if frame_num in [0, 2] else (-1 if frame_num == 1 else 1)
    rect(offset_x + 5 + leg_offset, y + 9, 2, 4, pants)
    rect(offset_x + 8 - leg_offset, y + 9, 2, 4, pants)
    
    rect(offset_x + 5 + leg_offset, y + 13, 2, 2, boots)
    rect(offset_x + 8 - leg_offset, y + 13, 2, 2, boots)

def draw_right_frame(offset_x, offset_y, frame_num):
    bounce = 0 if frame_num == 0 else (1 if frame_num == 1 else (0 if frame_num == 2 else 1))
    y = offset_y + bounce
    
    rect(offset_x + 7, y, 3, 4, skin)
    rect(offset_x + 7, y, 3, 2, hair)
    
    rect(offset_x + 6, y + 4, 5, 5, armor_light)
    rect(offset_x + 7, y + 4, 3, 1, armor_highlight)
    
    rect(offset_x + 9, y + 5, 2, 4, armor_light)
    rect(offset_x + 4, y + 5, 2, 4, skin)
    
    leg_offset = 0 if frame_num in [0, 2] else (1 if frame_num == 1 else -1)
    rect(offset_x + 9 - leg_offset, y + 9, 2, 4, pants)
    rect(offset_x + 6 + leg_offset, y + 9, 2, 4, pants)
    
    rect(offset_x + 9 - leg_offset, y + 13, 2, 2, boots)
    rect(offset_x + 6 + leg_offset, y + 13, 2, 2, boots)

# Draw all frames
for i in range(4):
    draw_down_frame(i * 16, 0, i)

for i in range(4):
    draw_up_frame(i * 16, 24, i)

for i in range(4):
    draw_left_frame(i * 16, 48, i)

for i in range(4):
    draw_right_frame(i * 16, 72, i)

img.save('player_spritesheet.png')
print("Created player_spritesheet.png (64x96)")
