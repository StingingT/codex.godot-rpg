from PIL import Image, ImageDraw, ImageFilter
import math

# Canvas size for inventory icons
SIZE = 32

def create_canvas():
    return Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

def create_sword(material):
    """Create sword sprite based on material"""
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Material definitions
    materials = {
        'bronze': {
            'blade': (180, 120, 80),
            'highlight': (200, 140, 100),
            'shadow': (140, 90, 60),
            'guard': (160, 100, 70),
            'pommel': (150, 95, 65),
            'outline': (80, 50, 35)
        },
        'iron': {
            'blade': (140, 140, 145),
            'highlight': (170, 170, 175),
            'shadow': (100, 100, 105),
            'guard': (120, 120, 125),
            'pommel': (110, 110, 115),
            'outline': (60, 60, 65)
        },
        'steel': {
            'blade': (200, 210, 220),
            'highlight': (230, 240, 250),
            'shadow': (150, 160, 170),
            'guard': (180, 190, 200),
            'pommel': (170, 180, 190),
            'outline': (80, 90, 100)
        },
        'adamant': {
            'blade': (60, 80, 120),
            'highlight': (100, 140, 200),
            'shadow': (40, 50, 80),
            'guard': (50, 70, 100),
            'pommel': (45, 65, 95),
            'outline': (30, 40, 60),
            'glow': (80, 120, 180, 100)
        },
        'mythril': {
            'blade': (150, 200, 230),
            'highlight': (200, 240, 255),
            'shadow': (100, 150, 180),
            'guard': (130, 180, 210),
            'pommel': (120, 170, 200),
            'outline': (60, 100, 130),
            'glow': (150, 220, 255, 120)
        },
        'orichalcum': {
            'blade': (255, 180, 80),
            'highlight': (255, 220, 120),
            'shadow': (200, 130, 50),
            'guard': (240, 160, 70),
            'pommel': (230, 150, 60),
            'outline': (150, 90, 30),
            'glow': (255, 200, 100, 150)
        }
    }
    
    m = materials[material]
    
    # Blade (diagonal from bottom-left to top-right)
    blade_points = [(14, 28), (16, 28), (18, 8), (16, 4), (14, 4), (12, 8)]
    draw.polygon(blade_points, fill=m['blade'], outline=m['outline'])
    
    # Blade highlight
    draw.line([(13, 10), (15, 26)], fill=m['highlight'], width=1)
    
    # Crossguard
    guard_width = 14 if material in ['bronze', 'iron'] else 16
    if material == 'orichalcum':
        guard_width = 18
    draw.rectangle([16 - guard_width//2, 26, 16 + guard_width//2, 29], 
                   fill=m['guard'], outline=m['outline'])
    
    # Guard details for higher tiers
    if material in ['adamant', 'mythril', 'orichalcum']:
        draw.rectangle([14, 27, 18, 28], fill=m['highlight'])
    
    # Pommel
    pommel_size = 3 if material in ['bronze', 'iron'] else 4
    if material == 'orichalcum':
        pommel_size = 5
    draw.ellipse([16 - pommel_size, 29, 16 + pommel_size, 31 + pommel_size], 
                 fill=m['pommel'], outline=m['outline'])
    
    # Glow effect for magical weapons
    if 'glow' in m:
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.polygon(blade_points, fill=m['glow'])
        img = Image.alpha_composite(glow, img)
    
    return img

def create_bow(material):
    """Create bow sprite based on material"""
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    materials = {
        'bronze': {
            'wood': (139, 90, 43),
            'reinforce': (180, 120, 80),
            'string': (200, 200, 180),
            'outline': (80, 50, 30)
        },
        'iron': {
            'wood': (120, 80, 40),
            'reinforce': (140, 140, 145),
            'string': (220, 220, 210),
            'outline': (70, 45, 25)
        },
        'steel': {
            'wood': (100, 70, 35),
            'reinforce': (200, 210, 220),
            'string': (240, 240, 230),
            'outline': (60, 40, 20)
        },
        'adamant': {
            'wood': (60, 50, 40),
            'reinforce': (60, 80, 120),
            'string': (150, 180, 220),
            'outline': (40, 35, 30),
            'glow': (80, 120, 180, 80)
        },
        'mythril': {
            'wood': (80, 100, 110),
            'reinforce': (150, 200, 230),
            'string': (200, 240, 255),
            'outline': (50, 70, 80),
            'glow': (150, 220, 255, 100)
        },
        'orichalcum': {
            'wood': (120, 80, 40),
            'reinforce': (255, 180, 80),
            'string': (255, 240, 200),
            'outline': (150, 100, 40),
            'glow': (255, 200, 100, 120)
        }
    }
    
    m = materials[material]
    
    # Bow curve (left side)
    bow_points = [(8, 28), (6, 20), (8, 12), (14, 6), (16, 8), (12, 14), (10, 20), (12, 28)]
    draw.polygon(bow_points, fill=m['wood'], outline=m['outline'])
    
    # Reinforcement on bow
    reinforce_points = [(7, 24), (6, 20), (7, 16)]
    draw.polygon(reinforce_points, fill=m['reinforce'], outline=m['outline'])
    
    # String
    draw.line([(14, 6), (14, 28)], fill=m['string'], width=1)
    
    # Higher tier details
    if material in ['adamant', 'mythril', 'orichalcum']:
        draw.ellipse([10, 18, 12, 22], fill=m['reinforce'])
    
    if 'glow' in m:
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.polygon(bow_points, fill=m['glow'])
        img = Image.alpha_composite(glow, img)
    
    return img

def create_staff(gem_type):
    """Create staff sprite based on gem"""
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    gems = {
        'sapphire': {
            'wood': (100, 80, 60),
            'gem': (80, 120, 200),
            'gem_light': (120, 180, 255),
            'outline': (60, 50, 40),
            'glow': (100, 150, 255, 80)
        },
        'ruby': {
            'wood': (110, 70, 50),
            'gem': (200, 60, 60),
            'gem_light': (255, 100, 100),
            'outline': (70, 45, 35),
            'glow': (255, 80, 80, 80)
        },
        'emerald': {
            'wood': (90, 90, 60),
            'gem': (60, 180, 80),
            'gem_light': (100, 255, 120),
            'outline': (55, 55, 40),
            'glow': (80, 255, 100, 80)
        },
        'topaz': {
            'wood': (120, 100, 50),
            'gem': (255, 200, 60),
            'gem_light': (255, 240, 120),
            'outline': (80, 65, 35),
            'glow': (255, 220, 80, 100)
        }
    }
    
    g = gems[gem_type]
    
    # Staff shaft
    draw.rectangle([15, 8, 17, 28], fill=g['wood'], outline=g['outline'])
    
    # Staff head (forked)
    draw.polygon([(12, 8), (15, 4), (15, 8)], fill=g['wood'], outline=g['outline'])
    draw.polygon([(17, 8), (20, 4), (17, 8)], fill=g['wood'], outline=g['outline'])
    
    # Gem in center
    gem_size = 4 if gem_type == 'sapphire' else 5
    draw.ellipse([16 - gem_size, 2, 16 + gem_size, 10], fill=g['gem'], outline=g['outline'])
    draw.ellipse([15, 4, 17, 6], fill=g['gem_light'])
    
    # Glow
    if 'glow' in g:
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse([16 - gem_size - 2, 0, 16 + gem_size + 2, 12], fill=g['glow'])
        img = Image.alpha_composite(glow, img)
    
    return img

# Create all swords
sword_materials = ['bronze', 'iron', 'steel', 'adamant', 'mythril', 'orichalcum']
for mat in sword_materials:
    sword = create_sword(mat)
    sword.save(f'sword_{mat}.png')
    print(f"Created sword_{mat}.png")

# Create all bows
for mat in sword_materials:
    bow = create_bow(mat)
    bow.save(f'bow_{mat}.png')
    print(f"Created bow_{mat}.png")

# Create all staves
staff_gems = ['sapphire', 'ruby', 'emerald', 'topaz']
for gem in staff_gems:
    staff = create_staff(gem)
    staff.save(f'staff_{gem}.png')
    print(f"Created staff_{gem}.png")

print("\nAll weapon sprites created!")
