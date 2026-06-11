from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
TILE = 32
RNG = Random(47)


def rgba(color):
    return color


def save(img, rel_path):
    path = ROOT / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def sheet(width_tiles, height_tiles=1):
    return Image.new("RGBA", (width_tiles * TILE, height_tiles * TILE), (0, 0, 0, 0))


def tile(draw, idx):
    x = idx * TILE
    return x, 0, x + TILE - 1, TILE - 1


def tile_at(column, row):
    x = column * TILE
    y = row * TILE
    return x, y, x + TILE - 1, y + TILE - 1


def scatter(draw, x0, y0, x1, y1, colors, count, size=1):
    for _ in range(count):
        x = RNG.randint(x0, x1)
        y = RNG.randint(y0, y1)
        color = RNG.choice(colors)
        draw.rectangle((x, y, x + size - 1, y + size - 1), fill=color)


def outline_rect(draw, box, fill, outline=(30, 24, 21, 255), width=1):
    draw.rectangle(box, fill=fill, outline=outline, width=width)


def draw_transition_family(img, draw, row, background, background_dark, surface, surface_dark, surface_light, pattern="dirt"):
    polygons = [
        [(0, 11), (7, 9), (15, 12), (23, 10), (31, 12), (31, 31), (0, 31)],
        [(0, 0), (31, 0), (31, 20), (24, 22), (16, 19), (8, 22), (0, 20)],
        [(11, 0), (31, 0), (31, 31), (10, 31), (12, 23), (9, 15), (12, 7)],
        [(0, 0), (20, 0), (18, 7), (21, 15), (18, 23), (20, 31), (0, 31)],
        [(20, 0), (31, 0), (31, 31), (0, 31), (0, 20), (5, 18), (10, 14), (14, 9), (18, 5)],
        [(0, 0), (11, 0), (13, 5), (18, 9), (22, 14), (27, 18), (31, 20), (31, 31), (0, 31)],
        [(0, 0), (31, 0), (31, 31), (20, 31), (18, 27), (14, 22), (10, 18), (5, 14), (0, 12)],
        [(0, 0), (31, 0), (31, 12), (27, 14), (22, 18), (18, 22), (13, 27), (11, 31), (0, 31)],
    ]
    edges = [
        [(0, 11), (7, 9), (15, 12), (23, 10), (31, 12)],
        [(0, 20), (8, 22), (16, 19), (24, 22), (31, 20)],
        [(11, 0), (12, 7), (9, 15), (12, 23), (10, 31)],
        [(20, 0), (18, 7), (21, 15), (18, 23), (20, 31)],
        [(20, 0), (18, 5), (14, 9), (10, 14), (5, 18), (0, 20)],
        [(11, 0), (13, 5), (18, 9), (22, 14), (27, 18), (31, 20)],
        [(0, 12), (5, 14), (10, 18), (14, 22), (18, 27), (20, 31)],
        [(31, 12), (27, 14), (22, 18), (18, 22), (13, 27), (11, 31)],
    ]

    for column in range(8):
        x0 = column * TILE
        y0 = row * TILE
        outline_rect(draw, tile_at(column, row), background, background_dark)
        polygon = [(x0 + x, y0 + y) for x, y in polygons[column]]
        edge = [(x0 + x, y0 + y) for x, y in edges[column]]
        draw.polygon(polygon, fill=surface)
        draw.line(edge, fill=surface_light, width=2)

        if pattern == "cobble":
            for local_y in range(4, 31, 8):
                for local_x in range(3, 31, 8):
                    px = x0 + local_x
                    py = y0 + local_y
                    if img.getpixel((px, py)) == surface:
                        draw.rectangle((px, py, px + 4, py + 2), fill=surface_light)
                        draw.point((px + 4, py + 2), fill=surface_dark)
        else:
            for _ in range(42):
                px = RNG.randint(x0 + 1, x0 + 30)
                py = RNG.randint(y0 + 1, y0 + 30)
                if img.getpixel((px, py)) == surface:
                    draw.point((px, py), fill=RNG.choice([surface_dark, surface_light]))


def draw_ground_tiles():
    img = sheet(8)
    draw = ImageDraw.Draw(img)

    # 0 grass
    outline_rect(draw, tile(draw, 0), (63, 118, 77, 255), (50, 92, 64, 255))
    scatter(draw, 1, 1, 30, 30, [(79, 140, 88, 255), (47, 98, 68, 255), (95, 151, 91, 255)], 90)
    for x in range(3, 31, 7):
        draw.line((x, 25, x + 2, 22), fill=(40, 83, 56, 255))

    # 1 heavy grass
    outline_rect(draw, tile(draw, 1), (46, 100, 63, 255), (35, 76, 52, 255))
    scatter(draw, 33, 1, 62, 30, [(74, 145, 72, 255), (32, 76, 52, 255), (102, 158, 85, 255)], 130)
    for x in range(36, 62, 5):
        draw.line((x, 29, x + 3, 20), fill=(31, 73, 48, 255), width=2)

    # 2 worn ash path
    outline_rect(draw, tile(draw, 2), (120, 98, 72, 255), (83, 70, 56, 255))
    scatter(draw, 65, 1, 94, 30, [(101, 82, 64, 255), (151, 124, 85, 255), (70, 61, 53, 255)], 100)
    draw.line((67, 10, 93, 18), fill=(88, 70, 56, 255), width=2)

    # 3 packed dirt with leaf flecks
    outline_rect(draw, tile(draw, 3), (88, 73, 54, 255), (61, 51, 42, 255))
    scatter(draw, 97, 1, 126, 30, [(109, 91, 64, 255), (66, 54, 42, 255), (93, 112, 60, 255)], 95)

    # 4 plaza cobble
    outline_rect(draw, tile(draw, 4), (104, 105, 96, 255), (55, 55, 55, 255))
    for x in range(128, 160, 8):
        draw.line((x, 0, x, 31), fill=(61, 61, 59, 255))
    for y in range(0, 32, 8):
        draw.line((128, y, 159, y + 2), fill=(60, 60, 57, 255))
    scatter(draw, 129, 1, 158, 30, [(127, 128, 116, 255), (79, 80, 76, 255)], 55)

    # 5 pale stone trim
    outline_rect(draw, tile(draw, 5), (139, 134, 116, 255), (73, 71, 67, 255))
    for x in range(161, 190, 10):
        draw.line((x, 0, x + 6, 31), fill=(96, 91, 80, 255))
    scatter(draw, 161, 1, 190, 30, [(164, 155, 129, 255), (98, 94, 82, 255)], 65)

    # 6 dungeon stone
    outline_rect(draw, tile(draw, 6), (58, 56, 60, 255), (30, 29, 33, 255))
    for y in range(0, 32, 8):
        draw.line((192, y, 223, y), fill=(35, 34, 39, 255))
    for x in range(192, 224, 11):
        draw.line((x, 0, x, 31), fill=(36, 35, 39, 255))
    scatter(draw, 193, 1, 222, 30, [(76, 73, 77, 255), (42, 41, 47, 255)], 65)

    # 7 marsh mud
    outline_rect(draw, tile(draw, 7), (71, 70, 48, 255), (45, 43, 34, 255))
    scatter(draw, 225, 1, 254, 30, [(92, 89, 56, 255), (48, 59, 43, 255), (39, 38, 31, 255)], 100)
    for x in range(226, 255, 9):
        draw.arc((x - 2, 14, x + 8, 26), 10, 165, fill=(43, 50, 38, 255), width=1)

    save(img, "assets/tilesets/custom/poe_ground_tiles.png")


def draw_environment_tiles():
    img = sheet(8, 3)
    draw = ImageDraw.Draw(img)

    # 0 deep water
    outline_rect(draw, tile(draw, 0), (28, 91, 101, 255), (21, 60, 72, 255))
    for y in (7, 18, 27):
        draw.arc((4, y - 3, 16, y + 5), 0, 180, fill=(79, 157, 165, 255), width=1)
        draw.arc((20, y - 1, 31, y + 6), 0, 180, fill=(58, 129, 139, 255), width=1)

    # 1 wet edge
    outline_rect(draw, tile(draw, 1), (43, 103, 95, 255), (34, 74, 63, 255))
    draw.rectangle((32, 0, 42, 31), fill=(67, 116, 73, 255))
    draw.rectangle((51, 0, 63, 31), fill=(30, 82, 93, 255))
    scatter(draw, 33, 0, 48, 31, [(86, 138, 86, 255), (44, 88, 59, 255)], 50)

    # 2 cliff stone
    outline_rect(draw, tile(draw, 2), (87, 86, 82, 255), (42, 42, 43, 255))
    draw.polygon([(65, 4), (92, 0), (94, 31), (64, 31)], fill=(77, 75, 72, 255), outline=(38, 38, 40, 255))
    for y in (8, 18, 27):
        draw.line((66, y, 94, y + 2), fill=(48, 47, 48, 255))
    scatter(draw, 65, 1, 94, 30, [(111, 109, 101, 255), (55, 54, 55, 255)], 45)

    # 3 marsh water
    outline_rect(draw, tile(draw, 3), (38, 90, 73, 255), (26, 57, 49, 255))
    scatter(draw, 97, 1, 126, 30, [(52, 107, 76, 255), (27, 68, 58, 255), (89, 118, 74, 255)], 90)
    for y in (6, 18, 28):
        draw.arc((99, y - 2, 113, y + 5), 0, 180, fill=(78, 139, 119, 255), width=1)

    # 4 bridge planks
    outline_rect(draw, tile(draw, 4), (111, 78, 49, 255), (50, 35, 26, 255), 2)
    for x in range(128, 160, 7):
        draw.line((x, 1, x, 30), fill=(62, 43, 31, 255))
    draw.line((128, 10, 159, 8), fill=(156, 112, 64, 255), width=2)
    draw.line((128, 24, 159, 23), fill=(61, 43, 31, 255), width=2)

    # 5 fence
    outline_rect(draw, tile(draw, 5), (0, 0, 0, 0), (0, 0, 0, 0))
    for x in (163, 172, 181, 190):
        draw.rectangle((x, 8, x + 3, 30), fill=(86, 64, 42, 255), outline=(39, 29, 22, 255))
    draw.rectangle((160, 14, 191, 18), fill=(118, 84, 52, 255), outline=(43, 31, 24, 255))

    # 6 thick brush
    outline_rect(draw, tile(draw, 6), (43, 94, 58, 255), (28, 67, 44, 255))
    for x in range(194, 223, 4):
        draw.line((x, 30, x + RNG.randint(-2, 3), RNG.randint(4, 18)), fill=(32, 83, 47, 255), width=2)
        draw.line((x + 1, 30, x + RNG.randint(-3, 3), RNG.randint(8, 24)), fill=(77, 141, 68, 255), width=1)
    scatter(draw, 193, 1, 222, 30, [(91, 154, 76, 255), (23, 63, 43, 255)], 80)

    # 7 cracked stone
    outline_rect(draw, tile(draw, 7), (82, 80, 78, 255), (40, 40, 42, 255))
    draw.line((229, 5, 237, 15, 233, 28), fill=(24, 24, 25, 255), width=2)
    draw.line((237, 15, 249, 11), fill=(31, 30, 31, 255), width=1)
    draw.line((233, 28, 252, 25), fill=(34, 33, 34, 255), width=1)
    scatter(draw, 225, 1, 254, 30, [(105, 102, 98, 255), (52, 50, 51, 255)], 55)

    grass = (63, 118, 77, 255)
    grass_dark = (42, 87, 58, 255)
    river = (28, 91, 101, 255)
    river_light = (70, 145, 154, 255)
    mud = (71, 70, 48, 255)
    mud_dark = (45, 43, 34, 255)
    marsh = (38, 90, 73, 255)
    marsh_light = (74, 132, 105, 255)

    # Row 1: directional banks and bridge approaches.
    outline_rect(draw, tile_at(0, 1), grass, grass_dark)
    draw.polygon((20, 32, 31, 32, 31, 63, 18, 63, 22, 55, 19, 47, 22, 39), fill=river)
    draw.line((20, 32, 22, 39, 19, 47, 22, 55, 18, 63), fill=river_light, width=2)
    scatter(draw, 1, 34, 17, 61, [(78, 139, 86, 255), (47, 99, 67, 255)], 34)

    outline_rect(draw, tile_at(1, 1), grass, grass_dark)
    draw.polygon((32, 32, 44, 32, 42, 39, 45, 47, 41, 55, 45, 63, 32, 63), fill=river)
    draw.line((44, 32, 42, 39, 45, 47, 41, 55, 45, 63), fill=river_light, width=2)
    scatter(draw, 47, 34, 62, 61, [(78, 139, 86, 255), (47, 99, 67, 255)], 34)

    outline_rect(draw, tile_at(2, 1), grass, grass_dark)
    draw.polygon((64, 51, 72, 48, 80, 51, 88, 48, 95, 52, 95, 63, 64, 63), fill=river)
    draw.line((64, 51, 72, 48, 80, 51, 88, 48, 95, 52), fill=river_light, width=2)
    scatter(draw, 66, 34, 93, 46, [(78, 139, 86, 255), (47, 99, 67, 255)], 30)

    outline_rect(draw, tile_at(3, 1), grass, grass_dark)
    draw.polygon((96, 32, 127, 32, 127, 43, 119, 47, 111, 44, 104, 47, 96, 43), fill=river)
    draw.line((96, 43, 104, 47, 111, 44, 119, 47, 127, 43), fill=river_light, width=2)
    scatter(draw, 98, 49, 125, 61, [(78, 139, 86, 255), (47, 99, 67, 255)], 30)

    outline_rect(draw, tile_at(4, 1), mud, mud_dark)
    draw.polygon((149, 32, 159, 32, 159, 63, 147, 63, 151, 55, 148, 47, 151, 39), fill=marsh)
    draw.line((149, 32, 151, 39, 148, 47, 151, 55, 147, 63), fill=marsh_light, width=2)
    scatter(draw, 129, 34, 146, 61, [(94, 91, 57, 255), (48, 58, 42, 255)], 38)

    outline_rect(draw, tile_at(5, 1), mud, mud_dark)
    draw.polygon((160, 32, 172, 32, 170, 39, 173, 47, 169, 55, 173, 63, 160, 63), fill=marsh)
    draw.line((172, 32, 170, 39, 173, 47, 169, 55, 173, 63), fill=marsh_light, width=2)
    scatter(draw, 175, 34, 190, 61, [(94, 91, 57, 255), (48, 58, 42, 255)], 38)

    outline_rect(draw, tile_at(6, 1), grass, grass_dark)
    draw.polygon((208, 32, 223, 32, 223, 63, 208, 63, 204, 55, 207, 47, 204, 39), fill=(111, 78, 49, 255))
    draw.line((208, 32, 208, 63), fill=(184, 132, 71, 255), width=2)
    for x in (211, 217, 223):
        draw.line((x, 33, x, 62), fill=(58, 41, 30, 255))
    scatter(draw, 193, 34, 202, 61, [(78, 139, 86, 255), (47, 99, 67, 255)], 20)

    outline_rect(draw, tile_at(7, 1), grass, grass_dark)
    draw.polygon((224, 32, 239, 32, 243, 39, 240, 47, 243, 55, 239, 63, 224, 63), fill=(111, 78, 49, 255))
    draw.line((239, 32, 239, 63), fill=(184, 132, 71, 255), width=2)
    for x in (224, 230, 236):
        draw.line((x, 33, x, 62), fill=(58, 41, 30, 255))
    scatter(draw, 245, 34, 254, 61, [(78, 139, 86, 255), (47, 99, 67, 255)], 20)

    # Row 2: deep-water pond banks and corners for enclosed water shapes.
    outline_rect(draw, tile_at(0, 2), mud, mud_dark)
    draw.polygon((20, 64, 31, 64, 31, 95, 18, 95, 22, 87, 19, 79, 22, 71), fill=river)
    draw.line((20, 64, 22, 71, 19, 79, 22, 87, 18, 95), fill=river_light, width=2)
    scatter(draw, 1, 66, 17, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 34)

    outline_rect(draw, tile_at(1, 2), mud, mud_dark)
    draw.polygon((32, 64, 44, 64, 42, 71, 45, 79, 41, 87, 45, 95, 32, 95), fill=river)
    draw.line((44, 64, 42, 71, 45, 79, 41, 87, 45, 95), fill=river_light, width=2)
    scatter(draw, 47, 66, 62, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 34)

    outline_rect(draw, tile_at(2, 2), mud, mud_dark)
    draw.polygon((64, 83, 72, 80, 80, 83, 88, 80, 95, 84, 95, 95, 64, 95), fill=river)
    draw.line((64, 83, 72, 80, 80, 83, 88, 80, 95, 84), fill=river_light, width=2)
    scatter(draw, 66, 66, 93, 78, [(94, 91, 57, 255), (48, 58, 42, 255)], 30)

    outline_rect(draw, tile_at(3, 2), mud, mud_dark)
    draw.polygon((96, 64, 127, 64, 127, 75, 119, 79, 111, 76, 104, 79, 96, 75), fill=river)
    draw.line((96, 75, 104, 79, 111, 76, 119, 79, 127, 75), fill=river_light, width=2)
    scatter(draw, 98, 81, 125, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 30)

    outline_rect(draw, tile_at(4, 2), mud, mud_dark)
    draw.polygon((149, 80, 159, 76, 159, 95, 140, 95, 144, 88, 141, 82), fill=river)
    draw.line((141, 82, 144, 88, 140, 95), fill=river_light, width=2)
    draw.line((149, 80, 159, 76), fill=river_light, width=2)
    scatter(draw, 129, 66, 147, 78, [(94, 91, 57, 255), (48, 58, 42, 255)], 25)
    scatter(draw, 129, 80, 138, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 18)

    outline_rect(draw, tile_at(5, 2), mud, mud_dark)
    draw.polygon((160, 76, 171, 80, 179, 82, 176, 88, 180, 95, 160, 95), fill=river)
    draw.line((160, 76, 171, 80), fill=river_light, width=2)
    draw.line((179, 82, 176, 88, 180, 95), fill=river_light, width=2)
    scatter(draw, 173, 66, 190, 78, [(94, 91, 57, 255), (48, 58, 42, 255)], 25)
    scatter(draw, 182, 80, 190, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 18)

    outline_rect(draw, tile_at(6, 2), mud, mud_dark)
    draw.polygon((205, 64, 223, 64, 223, 83, 215, 80, 207, 83, 204, 89, 208, 95), fill=river)
    draw.line((204, 89, 208, 95), fill=river_light, width=2)
    draw.line((207, 83, 215, 80, 223, 83), fill=river_light, width=2)
    scatter(draw, 193, 66, 202, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 24)
    scatter(draw, 210, 85, 222, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 18)

    outline_rect(draw, tile_at(7, 2), mud, mud_dark)
    draw.polygon((224, 64, 243, 64, 241, 83, 249, 80, 255, 83, 255, 95, 239, 95, 243, 89), fill=river)
    draw.line((224, 83, 232, 80, 241, 83), fill=river_light, width=2)
    draw.line((243, 89, 239, 95), fill=river_light, width=2)
    scatter(draw, 245, 66, 254, 78, [(94, 91, 57, 255), (48, 58, 42, 255)], 24)
    scatter(draw, 225, 85, 237, 93, [(94, 91, 57, 255), (48, 58, 42, 255)], 18)

    save(img, "assets/tilesets/custom/poe_environment_tiles.png")


def draw_building_tiles():
    img = sheet(8, 4)
    draw = ImageDraw.Draw(img)

    # 0 red shingle roof
    outline_rect(draw, tile(draw, 0), (112, 52, 39, 255), (54, 31, 30, 255), 2)
    for y in range(3, 30, 6):
        draw.line((0, y, 31, y + 1), fill=(61, 34, 32, 255), width=1)
        for x in range(0, 32, 8):
            draw.line((x, y, x + 4, y - 3), fill=(151, 75, 48, 255))

    # 1 slate roof
    outline_rect(draw, tile(draw, 1), (59, 57, 68, 255), (31, 31, 38, 255), 2)
    for y in range(2, 31, 6):
        draw.line((32, y, 63, y), fill=(34, 34, 42, 255))
        for x in range(33, 64, 8):
            draw.line((x, y, x + 5, y + 4), fill=(89, 88, 101, 255))

    # 2 plaster wall
    outline_rect(draw, tile(draw, 2), (177, 151, 104, 255), (78, 55, 38, 255), 2)
    draw.rectangle((65, 0, 68, 31), fill=(105, 69, 43, 255))
    draw.rectangle((91, 0, 94, 31), fill=(105, 69, 43, 255))
    draw.line((64, 18, 95, 18), fill=(107, 72, 44, 255), width=2)
    scatter(draw, 65, 1, 94, 30, [(202, 176, 126, 255), (146, 118, 82, 255)], 45)

    # 3 stone/timber wall
    outline_rect(draw, tile(draw, 3), (118, 114, 101, 255), (54, 49, 45, 255), 2)
    for y in range(4, 32, 7):
        draw.line((96, y, 127, y + 1), fill=(70, 65, 59, 255))
    for x in range(97, 128, 10):
        draw.line((x, 0, x, 31), fill=(72, 52, 37, 255), width=2)

    # 4 lit window
    outline_rect(draw, tile(draw, 4), (175, 151, 104, 255), (78, 55, 38, 255), 2)
    outline_rect(draw, (137, 7, 153, 23), (251, 206, 117, 255), (48, 36, 30, 255), 2)
    draw.line((145, 7, 145, 23), fill=(80, 51, 34, 255))
    draw.line((137, 15, 153, 15), fill=(80, 51, 34, 255))
    draw.rectangle((135, 24, 155, 27), fill=(91, 61, 41, 255))

    # 5 door
    outline_rect(draw, tile(draw, 5), (175, 151, 104, 255), (78, 55, 38, 255), 2)
    outline_rect(draw, (171, 7, 184, 30), (88, 52, 34, 255), (42, 29, 24, 255), 2)
    draw.line((178, 8, 178, 30), fill=(50, 32, 25, 255))
    draw.ellipse((181, 18, 184, 21), fill=(227, 177, 74, 255))

    # 6 chimney
    outline_rect(draw, tile(draw, 6), (59, 57, 68, 255), (31, 31, 38, 255), 2)
    outline_rect(draw, (205, 4, 216, 23), (96, 79, 68, 255), (45, 36, 31, 255), 1)
    draw.rectangle((203, 1, 218, 5), fill=(61, 51, 45, 255))
    draw.rectangle((208, 0, 216, 1), fill=(64, 62, 61, 165))

    # 7 market awning/sign
    outline_rect(draw, tile(draw, 7), (151, 47, 42, 255), (57, 33, 27, 255), 2)
    for x in range(224, 256, 8):
        draw.rectangle((x, 0, x + 3, 31), fill=(218, 180, 91, 255))
    draw.rectangle((230, 12, 249, 18), fill=(75, 46, 31, 255), outline=(35, 24, 20, 255))

    # Row 1: modular roof pieces.
    roof_specs = [
        ("red_left", (119, 53, 41, 255)),
        ("red_center", (119, 53, 41, 255)),
        ("red_right", (119, 53, 41, 255)),
        ("slate_left", (62, 61, 73, 255)),
        ("slate_center", (62, 61, 73, 255)),
        ("slate_right", (62, 61, 73, 255)),
    ]
    for column, (kind, color) in enumerate(roof_specs):
        x0 = column * TILE
        y0 = TILE
        outline = (48, 31, 31, 255) if kind.startswith("red") else (29, 29, 37, 255)
        highlight = (170, 78, 50, 255) if kind.startswith("red") else (96, 96, 113, 255)
        if kind.endswith("left"):
            polygon = [(x0 + 3, y0 + 29), (x0 + 8, y0 + 4), (x0 + 31, y0 + 4), (x0 + 31, y0 + 31), (x0, y0 + 31)]
        elif kind.endswith("right"):
            polygon = [(x0, y0 + 4), (x0 + 23, y0 + 4), (x0 + 29, y0 + 29), (x0 + 31, y0 + 31), (x0, y0 + 31)]
        else:
            polygon = [(x0, y0 + 4), (x0 + 31, y0 + 4), (x0 + 31, y0 + 31), (x0, y0 + 31)]
        draw.polygon(polygon, fill=color, outline=outline)
        draw.line((x0 + 1, y0 + 28, x0 + 30, y0 + 28), fill=outline, width=3)
        for y in range(y0 + 8, y0 + 27, 6):
            draw.line((x0 + 4, y, x0 + 28, y), fill=outline)
            for x in range(x0 + 6, x0 + 28, 9):
                draw.line((x, y, x + 4, y - 3), fill=highlight)

    # Chimney roof and guild dormer.
    outline_rect(draw, tile_at(6, 1), (62, 61, 73, 255), (29, 29, 37, 255), 2)
    for y in range(38, 62, 6):
        draw.line((194, y, 222, y), fill=(36, 35, 43, 255))
    outline_rect(draw, (204, 35, 216, 55), (100, 81, 68, 255), (42, 34, 30, 255), 2)
    draw.rectangle((202, 33, 218, 38), fill=(65, 53, 47, 255))
    outline_rect(draw, tile_at(7, 1), (62, 61, 73, 255), (29, 29, 37, 255), 2)
    draw.polygon((229, 58, 241, 38, 253, 58), fill=(85, 85, 103, 255), outline=(29, 29, 37, 255))
    outline_rect(draw, (236, 45, 246, 56), (216, 177, 93, 255), (38, 31, 28, 255), 1)
    draw.rectangle((237, 34, 245, 47), fill=(111, 38, 47, 255), outline=(38, 25, 28, 255))

    # Row 2: plaster and stone facade modules.
    facade_y = 64
    plaster = (179, 151, 104, 255)
    timber = (95, 61, 39, 255)
    plaster_outline = (65, 45, 34, 255)
    stone = (119, 115, 103, 255)
    stone_dark = (67, 63, 58, 255)

    for column in range(5):
        x0 = column * TILE
        outline_rect(draw, tile_at(column, 2), plaster, plaster_outline, 2)
        draw.rectangle((x0 + 2, facade_y + 3, x0 + 5, facade_y + 31), fill=timber)
        draw.rectangle((x0 + 26, facade_y + 3, x0 + 29, facade_y + 31), fill=timber)
        draw.line((x0 + 1, facade_y + 22, x0 + 30, facade_y + 22), fill=timber, width=2)
        scatter(draw, x0 + 6, facade_y + 3, x0 + 25, facade_y + 21, [(202, 177, 129, 255), (145, 117, 83, 255)], 20)
    draw.rectangle((64, facade_y, 68, facade_y + 31), fill=timber)
    draw.rectangle((155, facade_y, 159, facade_y + 31), fill=timber)
    outline_rect(draw, (72, facade_y + 6, 87, facade_y + 21), (246, 202, 112, 255), (45, 34, 29, 255), 2)
    draw.line((79, facade_y + 6, 79, facade_y + 21), fill=timber)
    draw.line((72, facade_y + 13, 87, facade_y + 13), fill=timber)
    outline_rect(draw, (105, facade_y + 5, 118, facade_y + 31), (89, 51, 33, 255), (40, 28, 24, 255), 2)
    draw.ellipse((114, facade_y + 17, 117, facade_y + 20), fill=(226, 174, 72, 255))

    for column in range(5, 8):
        x0 = column * TILE
        outline_rect(draw, tile_at(column, 2), stone, (48, 46, 43, 255), 2)
        for y in range(facade_y + 5, facade_y + 30, 8):
            draw.line((x0 + 1, y, x0 + 30, y + 1), fill=stone_dark)
        for x in range(x0 + 6, x0 + 30, 11):
            draw.line((x, facade_y + 1, x + 3, facade_y + 30), fill=(82, 77, 68, 255))
    draw.rectangle((160, facade_y, 164, facade_y + 31), fill=(55, 51, 47, 255))
    draw.rectangle((251, facade_y, 255, facade_y + 31), fill=(55, 51, 47, 255))

    # Row 3: stone services, barred windows, ruins, stairs, and tower cap.
    service_y = 96
    for column in range(8):
        x0 = column * TILE
        outline_rect(draw, tile_at(column, 3), stone, (48, 46, 43, 255), 2)
        for y in range(service_y + 5, service_y + 30, 8):
            draw.line((x0 + 1, y, x0 + 30, y + 1), fill=stone_dark)

    outline_rect(draw, (7, service_y + 6, 24, service_y + 22), (228, 188, 105, 255), (38, 32, 29, 255), 2)
    draw.line((15, service_y + 6, 15, service_y + 22), fill=(73, 55, 38, 255))
    draw.line((7, service_y + 14, 24, service_y + 14), fill=(73, 55, 38, 255))
    outline_rect(draw, (41, service_y + 4, 54, service_y + 31), (73, 43, 32, 255), (34, 25, 22, 255), 2)
    draw.arc((40, service_y - 3, 55, service_y + 13), 180, 360, fill=(34, 25, 22, 255), width=2)
    draw.ellipse((50, service_y + 17, 53, service_y + 20), fill=(217, 164, 66, 255))

    # Blacksmith service facade.
    draw.rectangle((69, service_y + 17, 91, service_y + 29), fill=(51, 45, 42, 255), outline=(30, 27, 26, 255))
    draw.polygon((72, service_y + 25, 80, service_y + 13, 89, service_y + 25), fill=(236, 104, 44, 255))
    draw.line((76, service_y + 8, 86, service_y + 18), fill=(41, 35, 31, 255), width=3)
    draw.ellipse((73, service_y + 5, 80, service_y + 12), fill=(164, 164, 157, 255), outline=(42, 40, 38, 255))

    # Guild banner facade.
    draw.rectangle((105, service_y + 3, 118, service_y + 25), fill=(110, 38, 47, 255), outline=(42, 28, 31, 255))
    draw.polygon((105, service_y + 25, 111, service_y + 19, 118, service_y + 25), fill=(206, 160, 61, 255))
    draw.line((111, service_y + 5, 111, service_y + 18), fill=(220, 180, 76, 255), width=2)

    # Barred window and ruined wall.
    outline_rect(draw, (135, service_y + 7, 153, service_y + 23), (49, 55, 60, 255), (35, 33, 32, 255), 2)
    for x in (139, 144, 149):
        draw.line((x, service_y + 8, x, service_y + 22), fill=(125, 112, 82, 255), width=2)
    draw.polygon((160, service_y + 31, 160, service_y + 10, 168, service_y + 4, 176, service_y + 12, 185, service_y + 7, 191, service_y + 18, 191, service_y + 31), fill=(96, 92, 84, 255), outline=(43, 41, 39, 255))
    draw.line((169, service_y + 12, 175, service_y + 22, 181, service_y + 16), fill=(51, 49, 47, 255), width=2)

    # Walkable stone threshold/stairs.
    outline_rect(draw, tile_at(6, 3), (96, 92, 84, 255), (45, 43, 41, 255), 2)
    for y in range(service_y + 6, service_y + 30, 6):
        draw.line((194, y, 222, y), fill=(141, 134, 119, 255), width=2)

    # Tower parapet cap.
    outline_rect(draw, tile_at(7, 3), (82, 80, 76, 255), (40, 39, 38, 255), 2)
    for x in (226, 236, 246):
        draw.rectangle((x, service_y + 2, x + 6, service_y + 12), fill=(111, 107, 98, 255), outline=(43, 41, 39, 255))
    draw.rectangle((225, service_y + 11, 254, service_y + 30), fill=(91, 87, 81, 255), outline=(43, 41, 39, 255))

    save(img, "assets/tilesets/custom/poe_building_tiles.png")


def draw_route_tiles():
    img = sheet(8, 4)
    draw = ImageDraw.Draw(img)

    # 0 encounter brush
    outline_rect(draw, tile(draw, 0), (35, 86, 55, 255), (24, 58, 40, 255))
    for x in range(2, 31, 4):
        draw.line((x, 31, x + RNG.randint(-3, 3), RNG.randint(4, 22)), fill=(25, 70, 43, 255), width=2)
        draw.line((x + 1, 31, x + RNG.randint(-2, 3), RNG.randint(12, 27)), fill=(82, 145, 64, 255), width=1)

    # 1 route dirt
    outline_rect(draw, tile(draw, 1), (123, 88, 56, 255), (70, 48, 38, 255))
    scatter(draw, 33, 1, 62, 30, [(154, 112, 70, 255), (86, 63, 48, 255), (61, 47, 40, 255)], 105)

    # 2 rune stone
    outline_rect(draw, tile(draw, 2), (74, 72, 76, 255), (34, 34, 38, 255))
    draw.polygon((72, 6, 88, 2, 95, 18, 83, 30, 67, 22), fill=(108, 103, 100, 255), outline=(32, 32, 35, 255))
    draw.line((78, 9, 83, 18, 90, 12), fill=(89, 160, 150, 255), width=2)

    # 3 bonfire
    outline_rect(draw, tile(draw, 3), (45, 38, 34, 255), (24, 20, 18, 255))
    draw.ellipse((104, 21, 119, 29), fill=(45, 31, 24, 255))
    draw.line((104, 26, 119, 21), fill=(88, 50, 27, 255), width=3)
    draw.line((106, 20, 118, 28), fill=(79, 45, 26, 255), width=3)
    draw.polygon((111, 5, 117, 18, 110, 25, 105, 18), fill=(230, 69, 35, 255))
    draw.polygon((111, 9, 115, 18, 111, 23, 108, 18), fill=(255, 180, 62, 255))

    # 4 skull marker
    outline_rect(draw, tile(draw, 4), (49, 48, 51, 255), (26, 25, 27, 255))
    draw.ellipse((137, 7, 151, 21), fill=(200, 190, 168, 255), outline=(55, 50, 44, 255))
    draw.rectangle((141, 19, 148, 27), fill=(181, 169, 148, 255), outline=(55, 50, 44, 255))
    draw.point((141, 14), fill=(35, 30, 30, 255))
    draw.point((148, 14), fill=(35, 30, 30, 255))

    # 5 path curb
    outline_rect(draw, tile(draw, 5), (96, 86, 68, 255), (48, 43, 37, 255))
    draw.line((160, 6, 191, 26), fill=(142, 128, 92, 255), width=4)
    draw.line((160, 12, 191, 31), fill=(49, 43, 36, 255), width=2)

    # 6 thorn roots
    outline_rect(draw, tile(draw, 6), (45, 76, 48, 255), (23, 48, 34, 255))
    for x in range(194, 222, 8):
        draw.arc((x - 4, 8, x + 11, 29), 210, 40, fill=(49, 36, 31, 255), width=2)
    scatter(draw, 193, 1, 222, 30, [(75, 117, 65, 255), (30, 59, 39, 255)], 70)

    # 7 dark seal
    outline_rect(draw, tile(draw, 7), (45, 39, 50, 255), (23, 21, 27, 255))
    draw.ellipse((229, 5, 252, 28), outline=(108, 67, 160, 255), width=2)
    draw.line((241, 6, 241, 27), fill=(153, 83, 211, 255), width=1)
    draw.line((231, 17, 252, 17), fill=(153, 83, 211, 255), width=1)

    draw_transition_family(
        img,
        draw,
        1,
        (63, 118, 77, 255),
        (42, 87, 58, 255),
        (120, 98, 72, 255),
        (83, 70, 56, 255),
        (151, 124, 85, 255),
    )
    draw_transition_family(
        img,
        draw,
        2,
        (71, 70, 48, 255),
        (45, 43, 34, 255),
        (120, 98, 72, 255),
        (83, 70, 56, 255),
        (151, 124, 85, 255),
    )
    draw_transition_family(
        img,
        draw,
        3,
        (63, 118, 77, 255),
        (42, 87, 58, 255),
        (104, 105, 96, 255),
        (60, 60, 57, 255),
        (132, 132, 119, 255),
        "cobble",
    )

    save(img, "assets/tilesets/custom/poe_route_tiles.png")


def draw_object_tiles():
    img = sheet(8, 3)
    draw = ImageDraw.Draw(img)

    # barrels
    for base_x, top_y in ((5, 5), (38, 7)):
        draw.ellipse((base_x, top_y, base_x + 21, top_y + 7), fill=(137, 85, 45, 255), outline=(42, 28, 21, 255))
        draw.rectangle((base_x, top_y + 4, base_x + 21, 26), fill=(101, 62, 37, 255), outline=(42, 28, 21, 255))
        draw.ellipse((base_x, 22, base_x + 21, 29), fill=(69, 43, 30, 255), outline=(42, 28, 21, 255))
        draw.line((base_x + 4, top_y + 5, base_x + 4, 25), fill=(151, 92, 49, 255))
        draw.line((base_x + 17, top_y + 5, base_x + 17, 25), fill=(53, 34, 27, 255))
        draw.line((base_x, 13, base_x + 21, 13), fill=(55, 42, 36, 255))
        draw.line((base_x, 23, base_x + 21, 23), fill=(55, 42, 36, 255))

    # crate
    outline_rect(draw, (69, 7, 91, 29), (126, 84, 49, 255), (43, 30, 24, 255), 2)
    draw.line((71, 9, 89, 27), fill=(66, 44, 31, 255), width=2)
    draw.line((89, 9, 71, 27), fill=(66, 44, 31, 255), width=2)
    draw.rectangle((74, 5, 87, 8), fill=(151, 101, 57, 255), outline=(43, 30, 24, 255))

    # well
    draw.rectangle((101, 13, 104, 27), fill=(83, 72, 58, 255))
    draw.rectangle((123, 13, 126, 27), fill=(83, 72, 58, 255))
    draw.line((103, 13, 124, 13), fill=(93, 72, 49, 255), width=2)
    draw.ellipse((102, 17, 125, 28), fill=(42, 59, 63, 255), outline=(41, 38, 35, 255), width=2)
    draw.arc((100, 2, 127, 25), 190, 350, fill=(92, 87, 79, 255), width=3)
    draw.line((114, 13, 114, 20), fill=(58, 47, 38, 255))

    # pillar
    outline_rect(draw, (137, 7, 151, 27), (111, 106, 98, 255), (48, 47, 45, 255), 2)
    draw.polygon((134, 5, 142, 2, 155, 7, 152, 11, 137, 10), fill=(84, 80, 76, 255), outline=(42, 40, 38, 255))
    draw.rectangle((134, 27, 154, 30), fill=(74, 71, 68, 255), outline=(42, 40, 38, 255))
    draw.line((144, 10, 148, 22), fill=(59, 57, 56, 255))
    draw.line((138, 17, 143, 14), fill=(72, 69, 66, 255))

    # ritual circle
    draw.ellipse((164, 4, 188, 28), outline=(128, 74, 179, 255), width=2)
    draw.ellipse((170, 10, 182, 22), outline=(191, 112, 218, 255), width=1)
    draw.line((176, 4, 176, 28), fill=(150, 88, 198, 255))
    draw.line((164, 16, 188, 16), fill=(150, 88, 198, 255))
    draw.polygon((176, 7, 179, 13, 186, 14, 181, 19, 182, 25, 176, 22, 170, 25, 171, 19, 166, 14, 173, 13), outline=(210, 133, 229, 255))

    # broken wall
    for x, y, w in [(194, 19, 11), (205, 14, 10), (215, 20, 8), (198, 7, 9)]:
        outline_rect(draw, (x, y, x + w, y + 8), (92, 88, 82, 255), (42, 40, 39, 255))
        draw.line((x + 2, y + 2, x + w - 2, y + 2), fill=(125, 120, 111, 255))

    # chest
    outline_rect(draw, (231, 11, 255, 28), (111, 64, 38, 255), (39, 27, 23, 255), 2)
    draw.pieslice((231, 3, 255, 19), 180, 360, fill=(147, 82, 42, 255), outline=(39, 27, 23, 255), width=2)
    draw.line((232, 13, 254, 13), fill=(61, 39, 29, 255), width=2)
    draw.rectangle((241, 11, 246, 20), fill=(220, 163, 64, 255), outline=(57, 39, 24, 255))

    # Row 1: low-profile biome decor and readable service markers.
    row_y = 32

    # Withered grass tuft.
    for x, lean, height in [(6, -3, 15), (11, 1, 21), (16, -1, 24), (21, 4, 18), (26, 2, 13)]:
        draw.line((x, row_y + 29, x + lean, row_y + 29 - height), fill=(109, 99, 55, 255), width=2)
        draw.line((x + 1, row_y + 28, x + lean + 4, row_y + 17), fill=(66, 77, 46, 255))
    draw.ellipse((4, row_y + 27, 28, row_y + 31), fill=(34, 38, 29, 150))

    # Bone scatter.
    bone = (207, 194, 153, 255)
    bone_shadow = (92, 83, 67, 255)
    draw.line((37, row_y + 22, 50, row_y + 12), fill=bone_shadow, width=4)
    draw.line((37, row_y + 21, 50, row_y + 11), fill=bone, width=2)
    for x, y in [(36, row_y + 21), (50, row_y + 11), (43, row_y + 26), (55, row_y + 23)]:
        draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=bone, outline=bone_shadow)
    draw.arc((50, row_y + 16, 60, row_y + 27), 185, 355, fill=bone, width=2)

    # Small stones.
    for box, color in [
        ((68, row_y + 20, 78, row_y + 28), (91, 92, 85, 255)),
        ((77, row_y + 13, 89, row_y + 27), (113, 111, 100, 255)),
        ((87, row_y + 21, 94, row_y + 28), (72, 75, 71, 255)),
    ]:
        draw.polygon(
            [(box[0], box[3]), (box[0] + 2, box[1] + 3), (box[2] - 3, box[1]), (box[2], box[3] - 2)],
            fill=color,
            outline=(43, 44, 42, 255),
        )

    # Broken boards.
    draw.polygon(
        [(98, row_y + 23), (121, row_y + 9), (125, row_y + 14), (102, row_y + 28)],
        fill=(103, 68, 42, 255),
        outline=(47, 33, 27, 255),
    )
    draw.polygon(
        [(101, row_y + 10), (124, row_y + 24), (121, row_y + 29), (97, row_y + 15)],
        fill=(128, 82, 45, 255),
        outline=(47, 33, 27, 255),
    )
    for x, y in [(105, row_y + 15), (118, row_y + 21)]:
        draw.ellipse((x, y, x + 2, y + 2), fill=(55, 54, 50, 255))

    # Rubble pile.
    rubble = [
        ((130, row_y + 21, 140, row_y + 29), (82, 82, 77, 255)),
        ((138, row_y + 14, 151, row_y + 28), (112, 108, 98, 255)),
        ((149, row_y + 20, 158, row_y + 29), (70, 72, 69, 255)),
        ((132, row_y + 12, 143, row_y + 21), (96, 94, 88, 255)),
    ]
    for box, color in rubble:
        draw.polygon(
            [(box[0], box[3]), (box[0] + 2, box[1] + 2), (box[2] - 3, box[1]), (box[2], box[3] - 2)],
            fill=color,
            outline=(41, 42, 41, 255),
        )

    # Grim route signpost.
    draw.rectangle((174, row_y + 9, 178, row_y + 31), fill=(72, 47, 31, 255), outline=(35, 27, 23, 255))
    draw.polygon(
        [(163, row_y + 9), (184, row_y + 9), (190, row_y + 15), (184, row_y + 20), (163, row_y + 20)],
        fill=(117, 73, 40, 255),
        outline=(39, 29, 24, 255),
    )
    draw.line((166, row_y + 13, 183, row_y + 13), fill=(164, 111, 58, 255))
    draw.line((170, row_y + 17, 182, row_y + 17), fill=(65, 43, 31, 255))

    # Ember brazier.
    draw.ellipse((197, row_y + 18, 219, row_y + 27), fill=(59, 51, 46, 255), outline=(27, 25, 24, 255), width=2)
    draw.rectangle((201, row_y + 23, 215, row_y + 28), fill=(72, 59, 49, 255), outline=(28, 25, 23, 255))
    draw.line((204, row_y + 27, 201, row_y + 31), fill=(45, 39, 35, 255), width=2)
    draw.line((212, row_y + 27, 215, row_y + 31), fill=(45, 39, 35, 255), width=2)
    draw.polygon(
        [(208, row_y + 19), (203, row_y + 14), (207, row_y + 5), (211, row_y + 12), (215, row_y + 8), (214, row_y + 18)],
        fill=(222, 87, 34, 255),
        outline=(104, 48, 29, 255),
    )
    draw.polygon([(208, row_y + 17), (207, row_y + 10), (211, row_y + 13), (212, row_y + 18)], fill=(255, 183, 65, 255))

    # Marsh reeds.
    for x, bend, height in [(228, 1, 18), (234, -1, 25), (240, 2, 21), (247, -2, 27), (253, 0, 17)]:
        draw.line((x, row_y + 30, x + bend, row_y + 30 - height), fill=(76, 93, 52, 255), width=2)
        draw.ellipse((x + bend - 2, row_y + 22 - height, x + bend + 2, row_y + 27 - height), fill=(95, 70, 39, 255))
    draw.line((226, row_y + 30, 255, row_y + 30), fill=(46, 55, 39, 255), width=2)

    # Row 2: structural ruin, crypt, and dungeon props.
    row_y = 64

    # Grave marker.
    draw.ellipse((6, row_y + 4, 25, row_y + 20), fill=(99, 99, 94, 255), outline=(42, 43, 42, 255), width=2)
    draw.rectangle((6, row_y + 12, 25, row_y + 29), fill=(99, 99, 94, 255), outline=(42, 43, 42, 255), width=2)
    draw.line((15, row_y + 9, 15, row_y + 23), fill=(57, 57, 55, 255), width=2)
    draw.line((10, row_y + 15, 20, row_y + 15), fill=(57, 57, 55, 255), width=2)
    draw.line((8, row_y + 27, 23, row_y + 24), fill=(126, 122, 111, 255))

    # Sarcophagus.
    draw.polygon(
        [(38, row_y + 8), (57, row_y + 8), (62, row_y + 14), (60, row_y + 29), (36, row_y + 29), (34, row_y + 14)],
        fill=(90, 89, 84, 255),
        outline=(38, 39, 38, 255),
    )
    draw.polygon(
        [(40, row_y + 11), (55, row_y + 11), (58, row_y + 15), (56, row_y + 25), (39, row_y + 25), (37, row_y + 15)],
        fill=(118, 114, 103, 255),
        outline=(54, 53, 50, 255),
    )
    draw.line((47, row_y + 13, 47, row_y + 23), fill=(70, 67, 63, 255))
    draw.ellipse((44, row_y + 13, 50, row_y + 18), outline=(69, 65, 60, 255))

    # Sacrificial altar.
    draw.rectangle((68, row_y + 16, 91, row_y + 28), fill=(84, 80, 76, 255), outline=(37, 37, 36, 255), width=2)
    draw.polygon(
        [(66, row_y + 13), (93, row_y + 13), (89, row_y + 19), (70, row_y + 19)],
        fill=(115, 108, 98, 255),
        outline=(41, 40, 38, 255),
    )
    draw.line((72, row_y + 16, 87, row_y + 16), fill=(122, 42, 38, 255), width=2)
    draw.ellipse((77, row_y + 8, 82, row_y + 13), fill=(207, 190, 143, 255), outline=(76, 68, 56, 255))

    # Funerary urn.
    draw.ellipse((103, row_y + 8, 120, row_y + 14), fill=(110, 80, 54, 255), outline=(44, 33, 27, 255))
    draw.polygon(
        [(104, row_y + 11), (119, row_y + 11), (122, row_y + 25), (117, row_y + 30), (106, row_y + 30), (101, row_y + 25)],
        fill=(89, 60, 44, 255),
        outline=(42, 31, 26, 255),
    )
    draw.line((104, row_y + 19, 120, row_y + 19), fill=(139, 91, 53, 255))

    # Ruined wall left, center, and right modules.
    wall_specs = [
        (128, [0, 6, 10, 8]),
        (160, [8, 7, 9, 8]),
        (192, [10, 8, 6, 0]),
    ]
    for x0, heights in wall_specs:
        for index, height in enumerate(heights):
            if height <= 0:
                continue
            bx = x0 + index * 8
            top = row_y + 31 - height * 2
            draw.rectangle((bx, top, bx + 7, row_y + 31), fill=(83, 82, 78, 255), outline=(39, 40, 39, 255))
            draw.line((bx + 1, top + 3, bx + 6, top + 3), fill=(120, 116, 106, 255))
        draw.line((x0, row_y + 23, x0 + 31, row_y + 23), fill=(47, 47, 45, 255))

    # Spiked barricade.
    for x in range(229, 255, 7):
        draw.polygon(
            [(x, row_y + 28), (x + 3, row_y + 5), (x + 6, row_y + 28)],
            fill=(96, 67, 44, 255),
            outline=(42, 31, 26, 255),
        )
    draw.line((226, row_y + 18, 255, row_y + 27), fill=(123, 76, 42, 255), width=4)
    draw.line((226, row_y + 27, 255, row_y + 16), fill=(87, 57, 39, 255), width=4)

    save(img, "assets/tilesets/custom/poe_object_tiles.png")


def draw_house():
    img = Image.new("RGBA", (144, 112), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((12, 94, 132, 109), fill=(0, 0, 0, 70))
    draw.rectangle((24, 52, 120, 101), fill=(181, 151, 102, 255), outline=(54, 38, 29, 255), width=3)
    draw.rectangle((24, 52, 120, 61), fill=(126, 84, 51, 255))
    for x in (31, 58, 112):
        draw.rectangle((x, 54, x + 5, 101), fill=(91, 59, 38, 255))
    draw.rectangle((20, 80, 124, 86), fill=(96, 61, 38, 255))
    draw.polygon((9, 54, 72, 9, 135, 54), fill=(66, 37, 36, 255), outline=(31, 24, 24, 255))
    draw.polygon((15, 51, 72, 15, 129, 51), fill=(135, 56, 42, 255), outline=(46, 31, 30, 255))
    for y in range(25, 52, 7):
        reach = int((y - 15) * 57 / 36)
        left = max(16, 72 - reach)
        right = min(128, 72 + reach)
        draw.line((left, y, right, y), fill=(75, 38, 34, 255))
        for x in range(left + 8, right - 8, 18):
            draw.rectangle((x, y - 2, x + 9, y - 1), fill=(181, 82, 50, 255))
    draw.rectangle((102, 14, 114, 35), fill=(87, 69, 58, 255), outline=(39, 31, 28, 255), width=2)
    draw.rectangle((100, 10, 116, 16), fill=(55, 47, 43, 255))
    for box in [(35, 66, 53, 84), (91, 66, 109, 84)]:
        outline_rect(draw, box, (245, 202, 116, 255), (43, 31, 25, 255), 2)
        x0, y0, x1, y1 = box
        draw.line((x0 + 9, y0, x0 + 9, y1), fill=(84, 55, 34, 255))
        draw.line((x0, y0 + 9, x1, y0 + 9), fill=(84, 55, 34, 255))
        draw.rectangle((x0 - 2, y1 + 1, x1 + 2, y1 + 4), fill=(93, 61, 39, 255))
    outline_rect(draw, (63, 69, 82, 101), (91, 51, 32, 255), (40, 29, 24, 255), 2)
    draw.line((73, 70, 73, 101), fill=(50, 31, 24, 255))
    draw.ellipse((78, 84, 81, 87), fill=(232, 178, 74, 255))
    for x in (31, 94):
        draw.rectangle((x, 91, x + 20, 96), fill=(61, 100, 56, 255), outline=(38, 57, 36, 255))
        for fx in range(x + 3, x + 18, 5):
            draw.rectangle((fx, 88, fx + 3, 91), fill=(230, 93, 101, 255))
    save(img, "assets/objects/buildings/hub_house_small.png")


def draw_guild_hall():
    img = Image.new("RGBA", (160, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((12, 108, 148, 124), fill=(0, 0, 0, 78))
    draw.rectangle((23, 56, 137, 112), fill=(126, 119, 102, 255), outline=(41, 38, 35, 255), width=3)
    for y in range(61, 110, 10):
        draw.line((25, y, 135, y + 1), fill=(82, 78, 70, 255))
    for x in range(32, 130, 20):
        draw.line((x, 58, x + 6, 112), fill=(90, 83, 72, 255))
    draw.polygon((7, 58, 80, 8, 153, 58), fill=(36, 37, 48, 255), outline=(18, 19, 25, 255))
    draw.polygon((15, 55, 80, 14, 145, 55), fill=(68, 69, 88, 255), outline=(27, 28, 36, 255))
    for y in range(24, 56, 8):
        reach = int((y - 14) * 65 / 41)
        left = max(16, 80 - reach)
        right = min(144, 80 + reach)
        draw.line((left, y, right, y), fill=(38, 39, 51, 255))
        for x in range(left + 8, right - 8, 18):
            draw.rectangle((x, y - 2, x + 10, y - 1), fill=(94, 96, 117, 255))
    outline_rect(draw, (69, 76, 91, 112), (76, 44, 31, 255), (32, 25, 22, 255), 2)
    draw.arc((68, 62, 92, 88), 180, 360, fill=(32, 25, 22, 255), width=3)
    for box in [(38, 70, 56, 87), (104, 70, 122, 87)]:
        outline_rect(draw, box, (228, 190, 110, 255), (34, 28, 25, 255), 2)
        x0, y0, x1, y1 = box
        draw.line((x0 + 9, y0, x0 + 9, y1), fill=(70, 53, 35, 255))
        draw.line((x0, y0 + 9, x1, y0 + 9), fill=(70, 53, 35, 255))
    draw.rectangle((73, 32, 87, 61), fill=(106, 37, 46, 255), outline=(38, 24, 27, 255))
    draw.polygon((73, 61, 80, 54, 87, 61), fill=(205, 160, 61, 255))
    save(img, "assets/objects/buildings/guild_hall.png")


def draw_vendor_stall():
    img = Image.new("RGBA", (112, 80), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((8, 66, 104, 77), fill=(0, 0, 0, 70))
    draw.rectangle((18, 37, 94, 61), fill=(96, 61, 38, 255), outline=(39, 28, 22, 255), width=2)
    draw.rectangle((15, 30, 97, 40), fill=(145, 86, 47, 255), outline=(43, 31, 24, 255), width=2)
    draw.polygon((8, 31, 56, 8, 104, 31), fill=(63, 38, 35, 255), outline=(31, 24, 23, 255))
    for x in range(14, 100, 14):
        color = (210, 171, 77, 255) if (x // 14) % 2 == 0 else (132, 45, 40, 255)
        draw.polygon((x, 29, x + 14, 22, x + 14, 38, x, 38), fill=color, outline=(61, 37, 30, 255))
    for x in (21, 88):
        draw.rectangle((x, 39, x + 5, 69), fill=(62, 43, 31, 255), outline=(32, 23, 18, 255))
    for x, y, color in [(29, 48, (91, 146, 64, 255)), (45, 47, (204, 78, 64, 255)), (62, 49, (232, 174, 72, 255)), (77, 48, (73, 122, 176, 255))]:
        draw.ellipse((x, y, x + 10, y + 7), fill=color, outline=(38, 28, 21, 255))
    outline_rect(draw, (12, 55, 31, 70), (119, 76, 42, 255), (42, 29, 22, 255), 1)
    outline_rect(draw, (82, 55, 101, 70), (116, 72, 39, 255), (42, 29, 22, 255), 1)
    save(img, "assets/objects/buildings/vendor_stall.png")


def draw_corrupted_oak():
    img = Image.new("RGBA", (72, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((10, 82, 62, 94), fill=(0, 0, 0, 70))
    draw.polygon((30, 38, 43, 39, 47, 86, 24, 86), fill=(84, 53, 38, 255), outline=(35, 24, 20, 255))
    draw.line((38, 48, 56, 29), fill=(58, 38, 29, 255), width=5)
    draw.line((34, 51, 15, 31), fill=(58, 38, 29, 255), width=5)
    draw.line((36, 62, 51, 56), fill=(41, 30, 24, 255), width=3)
    leaf_colors = [(31, 103, 72, 255), (22, 79, 63, 255), (54, 142, 81, 255), (52, 83, 105, 255)]
    for box in [(15, 12, 47, 40), (30, 9, 64, 42), (5, 28, 37, 58), (28, 31, 66, 63), (16, 43, 50, 73)]:
        draw.ellipse(box, fill=RNG.choice(leaf_colors), outline=(15, 55, 44, 255), width=2)
    scatter(draw, 8, 14, 62, 70, [(78, 170, 91, 255), (88, 99, 151, 255), (16, 52, 43, 255)], 90)
    draw.line((31, 58, 24, 80), fill=(36, 25, 22, 255), width=2)
    save(img, "assets/objects/trees/corrupted_oak.png")


def main():
    draw_ground_tiles()
    draw_environment_tiles()
    draw_building_tiles()
    draw_route_tiles()
    draw_object_tiles()
    draw_house()
    draw_guild_hall()
    draw_vendor_stall()
    draw_corrupted_oak()


if __name__ == "__main__":
    main()
