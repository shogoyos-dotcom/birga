import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, roughness=0.5, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def build_samarkand_palace():
    reset_scene()
    
    # Authentic Registan Color Palette
    mat_sandstone = create_mat("M_SamSandstone", (0.86, 0.78, 0.65, 1.0), roughness=0.8)
    mat_stone_dark = create_mat("M_SamStoneDark", (0.70, 0.62, 0.52, 1.0), roughness=0.85)
    mat_turquoise = create_mat("M_SamTurquoise", (0.05, 0.72, 0.85, 1.0), roughness=0.35)
    mat_lapis = create_mat("M_SamLapisBlue", (0.08, 0.32, 0.78, 1.0), roughness=0.45)
    mat_gold = create_mat("M_SamGold", (1.0, 0.82, 0.12, 1.0), roughness=0.25, metallic=0.9)
    mat_wood = create_mat("M_SamWood", (0.32, 0.18, 0.10, 1.0), roughness=0.85)

    root = bpy.data.objects.new("Castle_Samarkand_AAA", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Base Stepped Foundation Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    plinth = bpy.context.active_object
    plinth.name = "Plinth_Tier1"
    plinth.scale = (8.2, 7.0, 0.8)
    plinth.data.materials.append(mat_stone_dark)
    plinth.parent = root

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.9))
    plinth2 = bpy.context.active_object
    plinth2.name = "Plinth_Tier2"
    plinth2.scale = (7.6, 6.4, 0.3)
    plinth2.data.materials.append(mat_sandstone)
    plinth2.parent = root

    # 2. Grand Monumental Pishtaq (Central Iwan Entrance Portal)
    # The massive rectangular portal tower
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.8, 3.8))
    pishtaq = bpy.context.active_object
    pishtaq.name = "Pishtaq_Facade"
    pishtaq.scale = (4.4, 1.6, 5.6)
    pishtaq.data.materials.append(mat_sandstone)
    pishtaq.parent = root

    # Lapis blue decorative outer frame band
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.62, 3.8))
    frame = bpy.context.active_object
    frame.name = "Pishtaq_MosaicFrame"
    frame.scale = (4.1, 0.08, 5.3)
    frame.data.materials.append(mat_lapis)
    frame.parent = root

    # Golden calligraphic frieze border inside the frame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.65, 3.8))
    gold_frieze = bpy.context.active_object
    gold_frieze.scale = (3.7, 0.06, 4.9)
    gold_frieze.data.materials.append(mat_gold)
    gold_frieze.parent = root

    # Deep pointed iwan arch recess (cutout look)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.2, 3.0))
    iwan_niche = bpy.context.active_object
    iwan_niche.name = "Iwan_Niche"
    iwan_niche.scale = (2.4, 1.1, 3.8)
    iwan_niche.data.materials.append(mat_turquoise)
    iwan_niche.parent = root

    # Vaulted inner arch vault
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=1.2, depth=1.0, location=(0, -2.2, 4.9))
    arch_vault = bpy.context.active_object
    arch_vault.rotation_euler = (math.radians(90), 0, 0)
    arch_vault.data.materials.append(mat_lapis)
    arch_vault.parent = root

    # Carved wooden door at the back of the iwan
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.6, 1.8))
    door = bpy.context.active_object
    door.scale = (1.4, 0.15, 2.2)
    door.data.materials.append(mat_wood)
    door.parent = root

    # Decorative cresting crenellations on top of pishtaq
    for cx in range(-6, 7):
        bpy.ops.mesh.primitive_cube_add(size=0.25, location=(cx * 0.32, -1.8, 6.75))
        crenel = bpy.context.active_object
        crenel.data.materials.append(mat_turquoise)
        crenel.parent = root

    # 3. Flanking Madrasah Wings (Arcaded halls)
    for wing_side in [-1, 1]:
        # Wing body
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wing_side * 2.8, 0.8, 2.4))
        wing = bpy.context.active_object
        wing.name = f"MadrasahWing_{wing_side}"
        wing.scale = (2.2, 3.8, 3.2)
        wing.data.materials.append(mat_sandstone)
        wing.parent = root

        # Wing roof terrace with balustrade
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wing_side * 2.8, 0.8, 4.05))
        wroof = bpy.context.active_object
        wroof.scale = (2.3, 3.9, 0.15)
        wroof.data.materials.append(mat_stone_dark)
        wroof.parent = root

        # Two tiers of arched student niches (Hujra cells)
        for tier in [1.6, 3.0]:
            for ny in [-0.6, 0.8, 2.2]:
                bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wing_side * 3.92, ny, tier))
                niche = bpy.context.active_object
                niche.scale = (0.1, 0.8, 1.0)
                niche.data.materials.append(mat_lapis)
                niche.parent = root

    # 4. Two Fluted Ribbed Turquoise Melon Domes on Drums
    dome_coords = [(-2.0, 1.2), (2.0, 1.2)]
    for d_idx, (dx, dy) in enumerate(dome_coords):
        # Tall cylindrical drum
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.1, depth=1.4, location=(dx, dy, 4.6))
        drum = bpy.context.active_object
        drum.name = f"DomeDrum_{d_idx}"
        drum.data.materials.append(mat_sandstone)
        drum.parent = root

        # Lapis band on drum
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.14, depth=0.35, location=(dx, dy, 4.9))
        drum_band = bpy.context.active_object
        drum_band.data.materials.append(mat_lapis)
        drum_band.parent = root

        # Ribbed Fluted Turquoise Melon Dome (Scale sphere to melon shape)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=1.28, location=(dx, dy, 5.8))
        dome = bpy.context.active_object
        dome.name = f"TurquoiseDome_{d_idx}"
        dome.scale = (1.0, 1.0, 1.35)
        dome.data.materials.append(mat_turquoise)
        dome.parent = root

        # Pointed dome tip
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.45, depth=0.9, location=(dx, dy, 7.5))
        tip = bpy.context.active_object
        tip.data.materials.append(mat_turquoise)
        tip.parent = root

        # Golden Spire with Crescent Moon
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=1.1, location=(dx, dy, 8.2))
        spire = bpy.context.active_object
        spire.data.materials.append(mat_gold)
        spire.parent = root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.18, location=(dx, dy, 8.8))
        orb = bpy.context.active_object
        orb.data.materials.append(mat_gold)
        orb.parent = root

    # 5. Twin Soaring Minarets (Flanking the Pishtaq Façade)
    minaret_coords = [(-2.6, -2.4), (2.6, -2.4)]
    for m_idx, (mx, my) in enumerate(minaret_coords):
        # Octagonal base
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.72, depth=1.6, location=(mx, my, 1.3))
        m_base = bpy.context.active_object
        m_base.data.materials.append(mat_stone_dark)
        m_base.parent = root

        # Tapered shaft with turquoise/lapis chevron rings
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.58, depth=5.8, location=(mx, my, 4.6))
        m_shaft = bpy.context.active_object
        m_shaft.name = f"MinaretShaft_{m_idx}"
        m_shaft.data.materials.append(mat_sandstone)
        m_shaft.parent = root

        # Decorative mosaic belt on minaret
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.62, depth=0.6, location=(mx, my, 5.2))
        m_belt = bpy.context.active_object
        m_belt.data.materials.append(mat_turquoise)
        m_belt.parent = root

        # Corbeled Muqarnas Balcony (Sharfa)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.82, depth=0.4, location=(mx, my, 7.6))
        balcony = bpy.context.active_object
        balcony.data.materials.append(mat_gold)
        balcony.parent = root

        # Upper lantern pavilion
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.48, depth=0.9, location=(mx, my, 8.2))
        lantern = bpy.context.active_object
        lantern.data.materials.append(mat_sandstone)
        lantern.parent = root

        # Conical turquoise tiled cap
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.62, depth=1.4, location=(mx, my, 9.2))
        m_cap = bpy.context.active_object
        m_cap.data.materials.append(mat_turquoise)
        m_cap.parent = root

        # Gold finial
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.14, location=(mx, my, 10.0))
        m_fin = bpy.context.active_object
        m_fin.data.materials.append(mat_gold)
        m_fin.parent = root

    # 6. Grand Front Staircase
    for st in range(4):
        sz = 0.15 + st * 0.14
        sy = -3.0 - st * 0.32
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, sy, sz))
        step = bpy.context.active_object
        step.scale = (3.2 - st * 0.3, 0.35, 0.14)
        step.data.materials.append(mat_stone_dark)
        step.parent = root

    return root

def render_preview(output_path):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    scene.render.filepath = output_path
    
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    floor = bpy.context.active_object
    mat_floor = create_mat("M_StudioFloor", (0.35, 0.70, 0.28, 1.0), roughness=0.85)
    floor.data.materials.append(mat_floor)
    
    # Warm key sun
    sun_data = bpy.data.lights.new(name="SunKey", type='SUN')
    sun_data.energy = 4.6
    sun_data.color = (1.0, 0.96, 0.88)
    sun = bpy.data.objects.new("SunKey", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(20), math.radians(-32))
    
    # Sky fill
    fill_data = bpy.data.lights.new(name="SkyFill", type='SUN')
    fill_data.energy = 1.8
    fill_data.color = (0.55, 0.82, 1.0)
    fill = bpy.data.objects.new("SkyFill", fill_data)
    scene.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(-50), math.radians(10), math.radians(140))
    
    # Camera
    cam_data = bpy.data.cameras.new("SamCam")
    cam_data.lens = 50
    cam_obj = bpy.data.objects.new("SamCam", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (11.0, -14.0, 9.5)
    
    target = Vector((0.0, 0.0, 4.2))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    
    bpy.ops.render.render(write_still=True)
    print(f"[SAMARKAND RENDER COMPLETE] {output_path}")

if __name__ == "__main__":
    build_samarkand_palace()
    render_preview(r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_samarkand_render.png")
