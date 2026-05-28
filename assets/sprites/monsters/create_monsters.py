from PIL import Image, ImageDraw

# SLIME - Green bouncing blob
def create_slime():
    img = Image.new('RGBA', (64, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    slime_base = (50, 180, 80)
    slime_light = (100, 220, 120)
    slime_dark = (30, 120, 50)
    eye = (255, 255, 255)
    pupil = (0, 0, 0)
    
    def draw_slime_frame(offset_x, frame):
        # Bounce animation
        heights = [14, 12, 14, 11]
        y = 15 - heights[frame]
        h = heights[frame]
        
        # Body - rounded rectangle
        draw.ellipse([offset_x + 2, y - 2, offset_x + 14, y + h], fill=slime_base)
        draw.ellipse([offset_x + 4, y, offset_x + 12, y + h - 2], fill=slime_light)
        
        # Eyes
        eye_y = y + h // 3
        draw.ellipse([offset_x + 5, eye_y, offset_x + 7, eye_y + 3], fill=eye)
        draw.ellipse([offset_x + 9, eye_y, offset_x + 11, eye_y + 3], fill=eye)
        draw.ellipse([offset_x + 6, eye_y + 1, offset_x + 6, eye_y + 2], fill=pupil)
        draw.ellipse([offset_x + 10, eye_y + 1, offset_x + 10, eye_y + 2], fill=pupil)
        
        # Shine
        draw.ellipse([offset_x + 4, y + 2, offset_x + 6, y + 4], fill=slime_light)
    
    for i in range(4):
        draw_slime_frame(i * 16, i)
    
    return img

# SKELETON - Undead warrior
def create_skeleton():
    img = Image.new('RGBA', (64, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    bone = (220, 220, 210)
    bone_dark = (180, 180, 170)
    eye = (200, 50, 50)
    
    def draw_skeleton_frame(offset_x, frame):
        bounce = [0, 1, 0, 1][frame]
        y = 1 + bounce
        
        # Head (skull)
        draw.rectangle([offset_x + 6, y, offset_x + 10, y + 5], fill=bone)
        draw.rectangle([offset_x + 7, y + 1, offset_x + 9, y + 2], fill=eye)  # Eyes
        
        # Body (ribs)
        draw.rectangle([offset_x + 5, y + 6, offset_x + 11, y + 7], fill=bone)
        draw.rectangle([offset_x + 6, y + 8, offset_x + 10, y + 9], fill=bone)
        draw.rectangle([offset_x + 6, y + 10, offset_x + 10, y + 11], fill=bone)
        
        # Arms
        arm_offset = [0, 1, 0, -1][frame]
        draw.rectangle([offset_x + 3, y + 6, offset_x + 5, y + 14], fill=bone)
        draw.rectangle([offset_x + 11, y + 6 + arm_offset, offset_x + 13, y + 14 + arm_offset], fill=bone)
        
        # Legs
        leg_offset = [0, 1, 0, 1][frame]
        draw.rectangle([offset_x + 5, y + 12, offset_x + 7, y + 22 - leg_offset], fill=bone)
        draw.rectangle([offset_x + 9, y + 12, offset_x + 11, y + 22 - leg_offset], fill=bone)
    
    for i in range(4):
        draw_skeleton_frame(i * 16, i)
    
    return img

# BAT - Flying creature
def create_bat():
    img = Image.new('RGBA', (64, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    body = (80, 60, 100)
    wing = (120, 100, 140)
    wing_dark = (90, 70, 110)
    eye = (255, 100, 100)
    
    def draw_bat_frame(offset_x, frame):
        y = 8
        wing_span = [6, 8, 6, 4][frame]
        
        # Body
        draw.ellipse([offset_x + 6, y - 3, offset_x + 10, y + 3], fill=body)
        
        # Wings
        # Left wing
        draw.polygon([
            (offset_x + 6, y),
            (offset_x + 6 - wing_span, y - 2),
            (offset_x + 6 - wing_span + 2, y + 4),
            (offset_x + 6, y + 2)
        ], fill=wing)
        # Right wing
        draw.polygon([
            (offset_x + 10, y),
            (offset_x + 10 + wing_span, y - 2),
            (offset_x + 10 + wing_span - 2, y + 4),
            (offset_x + 10, y + 2)
        ], fill=wing)
        
        # Eyes
        draw.ellipse([offset_x + 7, y - 1, offset_x + 8, y], fill=eye)
        draw.ellipse([offset_x + 8, y - 1, offset_x + 9, y], fill=eye)
        
        # Ears
        draw.polygon([(offset_x + 6, y - 2), (offset_x + 5, y - 5), (offset_x + 7, y - 2)], fill=body)
        draw.polygon([(offset_x + 10, y - 2), (offset_x + 11, y - 5), (offset_x + 9, y - 2)], fill=body)
    
    for i in range(4):
        draw_bat_frame(i * 16, i)
    
    return img

# SWAMP MONSTER - Toxic creature
def create_swamp_monster():
    img = Image.new('RGBA', (64, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    body = (60, 100, 50)
    body_light = (80, 140, 70)
    eye = (150, 255, 100)
    
    def draw_monster_frame(offset_x, frame):
        bounce = [0, 1, 0, 2][frame]
        y = 2 + bounce
        
        # Blob body
        draw.ellipse([offset_x + 4, y, offset_x + 12, y + 12], fill=body)
        draw.ellipse([offset_x + 6, y + 2, offset_x + 10, y + 8], fill=body_light)
        
        # Tentacles/arms
        tentacle_y = [0, 2, 0, -1][frame]
        draw.rectangle([offset_x + 2, y + 6 + tentacle_y, offset_x + 4, y + 14], fill=body)
        draw.rectangle([offset_x + 12, y + 6 - tentacle_y, offset_x + 14, y + 14], fill=body)
        
        # Eye
        draw.ellipse([offset_x + 7, y + 3, offset_x + 9, y + 5], fill=eye)
        
        # Bubbles
        draw.ellipse([offset_x + 5, y - 2, offset_x + 7, y], fill=body_light)
    
    for i in range(4):
        draw_monster_frame(i * 16, i)
    
    return img

# DARK KNIGHT - Armored enemy
def create_dark_knight():
    img = Image.new('RGBA', (64, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    armor = (60, 60, 70)
    armor_light = (90, 90, 100)
    armor_dark = (40, 40, 50)
    glow = (150, 50, 200)
    
    def draw_knight_frame(offset_x, frame):
        bounce = [0, 1, 0, 1][frame]
        y = 1 + bounce
        
        # Helmet
        draw.rectangle([offset_x + 6, y, offset_x + 10, y + 5], fill=armor)
        draw.rectangle([offset_x + 7, y + 2, offset_x + 9, y + 3], fill=glow)  # Eye glow
        
        # Body (armor)
        draw.rectangle([offset_x + 5, y + 5, offset_x + 11, y + 12], fill=armor)
        draw.rectangle([offset_x + 6, y + 6, offset_x + 10, y + 8], fill=armor_light)
        
        # Shoulders
        draw.rectangle([offset_x + 3, y + 5, offset_x + 5, y + 7], fill=armor_dark)
        draw.rectangle([offset_x + 11, y + 5, offset_x + 13, y + 7], fill=armor_dark)
        
        # Arms
        arm_swing = [0, 1, 0, -1][frame]
        draw.rectangle([offset_x + 3, y + 7, offset_x + 5, y + 14], fill=armor)
        draw.rectangle([offset_x + 11, y + 7 + arm_swing, offset_x + 13, y + 14 + arm_swing], fill=armor)
        
        # Legs
        leg_offset = [0, 1, 0, 1][frame]
        draw.rectangle([offset_x + 5, y + 12, offset_x + 7, y + 22 - leg_offset], fill=armor_dark)
        draw.rectangle([offset_x + 9, y + 12, offset_x + 11, y + 22 - leg_offset], fill=armor_dark)
        
        # Sword (on back)
        draw.rectangle([offset_x + 13, y + 3, offset_x + 14, y + 12], fill=armor_light)
    
    for i in range(4):
        draw_knight_frame(i * 16, i)
    
    return img

# Create all monster sprites
slime = create_slime()
slime.save('slime_spritesheet.png')
print("Created slime_spritesheet.png")

skeleton = create_skeleton()
skeleton.save('skeleton_spritesheet.png')
print("Created skeleton_spritesheet.png")

bat = create_bat()
bat.save('bat_spritesheet.png')
print("Created bat_spritesheet.png")

swamp = create_swamp_monster()
swamp.save('swamp_monster_spritesheet.png')
print("Created swamp_monster_spritesheet.png")

knight = create_dark_knight()
knight.save('dark_knight_spritesheet.png')
print("Created dark_knight_spritesheet.png")

print("\nAll monster sprites created!")
