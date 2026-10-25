import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, roughness=0.35, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def build_dubai_palace():
    reset_scene()
    
    # Opulent Arabian Marble & Gold Palette
    mat_marble_white = create_mat("M_DubaiMarbleWhite", (0.95, 0.94, 0.92, 1.0), roughness=0.35)
    mat_marble_warm = create_mat("M_DubaiMarbleWarm", (0.88, 0.82, 0.72, 1.0), roughness=0.45)
    mat_gold = create_mat("M_DubaiPureGold", (1.0, 0.84, 0.10, 1.0), roughness=0.18, metallic=0.92)
    mat_gold_trim = create_mat("M_DubaiGoldTrim", (0.92, 0.75, 0.15, 1.0), roughness=0.25, metallic=0.85)
    mat_wood = create_mat("M_DubaiWood", (0.35, 0.20, 0.10, 1.0), roughness=0.8)

    root = bpy.data.objects.new("Castle_Dubai_AAA", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Grand White Marble Terrace Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    base1 = bpy.context.active_object
    base1.name = "Plinth_Tier1"
    base1.scale = (8.5, 7.5, 0.8)
    base1.data.materials.append(mat_marble_warm)
    base1.parent = root

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.95))
    base2 = bpy.context.active_object
    base2.name = "Plinth_Tier2"
    base2.scale = (7.8, 6.8, 0.3)
    base2.data.materials.append(mat_marble_white)
    base2.parent = root

    # Gold rim border around the terrace
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.12))
    rim = bpy.context.active_object
    rim.scale = (7.85, 6.85, 0.08)
    rim.data.materials.append(mat_gold_trim)
    rim.parent = root

    # 2. Main Central Palace Pavilion (Tier 1 & Tier 2)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.4))
    body1 = bpy.context.active_object
    body1.name = "PalaceBody_Tier1"
    body1.scale = (5.6, 4.8, 2.4)
    body1.data.materials.append(mat_marble_white)
    body1.parent = root

    # Second tier stepped terrace
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.0))
    body2 = bpy.context.active_object
    body2.name = "PalaceBody_Tier2"
    body2.scale = (4.0, 3.4, 1.2)
    body2.data.materials.append(mat_marble_white)
    body2.parent = root

    # Golden balustrade frieze on second tier
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.65))
    frieze = bpy.context.active_object
    frieze.scale = (4.1, 3.5, 0.12)
    frieze.data.materials.append(mat_gold)
    frieze.parent = root

    # 3. Grand Central Gilded Onion Dome
    # Drum for main dome
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.35, depth=1.1, location=(0, 0, 5.2))
    drum = bpy.context.active_object
    drum.name = "CentralDrum"
    drum.data.materials.append(mat_marble_white)
    drum.parent = root

    # Gold ring around drum
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.42, depth=0.25, location=(0, 0, 5.5))
    drum_ring = bpy.context.active_object
    drum_ring.data.materials.append(mat_gold)
    drum_ring.parent = root

    # Central Gilded Onion Dome (Slightly bulged sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=12, radius=1.55, location=(0, 0, 6.4))
    main_dome = bpy.context.active_object
    main_dome.name = "CentralGoldDome"
    main_dome.scale = (1.0, 1.0, 1.35)
    main_dome.data.materials.append(mat_gold)
    main_dome.parent = root

    # Pointed tip of onion dome
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.65, depth=1.3, location=(0, 0, 8.2))
    dome_tip = bpy.context.active_object
    dome_tip.data.materials.append(mat_gold)
    dome_tip.parent = root

    # Spire and crescent
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.08, depth=1.2, location=(0, 0, 9.2))
    spire = bpy.context.active_object
    spire.data.materials.append(mat_gold)
    spire.parent = root

    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.22, location=(0, 0, 9.9))
    finial = bpy.context.active_object
    finial.data.materials.append(mat_gold)
    finial.parent = root

    # 4. 4 Flanking Corner Kiosks (Chhatris) with Small Gold Onion Domes
    kiosk_coords = [
        (-2.8, -2.4),
        (2.8, -2.4),
        (-2.8, 2.4),
        (2.8, 2.4)
    ]
    for k_idx, (kx, ky) in enumerate(kiosk_coords):
        # Pavilion square base tower
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(kx, ky, 2.6))
        k_tower = bpy.context.active_object
        k_tower.name = f"CornerKiosk_{k_idx}"
        k_tower.scale = (1.3, 1.3, 3.2)
        k_tower.data.materials.append(mat_marble_white)
        k_tower.parent = root

        # Open pillared kiosk terrace
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(kx, ky, 4.3))
        k_roof = bpy.context.active_object
        k_roof.scale = (1.45, 1.45, 0.2)
        k_roof.data.materials.append(mat_gold_trim)
        k_roof.parent = root

        # Small golden onion dome
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.72, location=(kx, ky, 5.0))
        k_dome = bpy.context.active_object
        k_dome.name = f"KioskDome_{k_idx}"
        k_dome.scale = (1.0, 1.0, 1.3)
        k_dome.data.materials.append(mat_gold)
        k_dome.parent = root

        # Small cone tip
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.32, depth=0.75, location=(kx, ky, 5.9))
        k_tip = bpy.context.active_object
        k_tip.data.materials.append(mat_gold)
        k_tip.parent = root

        # Gold ball finial
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.12, location=(kx, ky, 6.4))
        k_fin = bpy.context.active_object
        k_fin.data.materials.append(mat_gold)
        k_fin.parent = root

    # 5. Grand Arched Portico & Colonnade Entrance
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.7, 2.0))
    portico = bpy.context.active_object
    portico.scale = (3.2, 1.2, 2.2)
    portico.data.materials.append(mat_marble_white)
    portico.parent = root

    # Arched portal cut
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.75, depth=0.6, location=(0, -3.2, 1.8))
    arch = bpy.context.active_object
    arch.rotation_euler = (math.radians(90), 0, 0)
    arch.data.materials.append(mat_gold_trim)
    arch.parent = root

    # Grand Palace Entrance Staircase (Wide cascading marble steps)
    for st in range(5):
        sz = 0.12 + st * 0.15
        sy = -3.4 - st * 0.35
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, sy, sz))
        step = bpy.context.active_object
        step.scale = (3.6 - st * 0.25, 0.40, 0.15)
        step.data.materials.append(mat_marble_warm)
        step.parent = root

    # Side decorative columns along the portico
    for col_x in [-1.4, -0.7, 0.7, 1.4]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.14, depth=2.2, location=(col_x, -3.25, 2.0))
        col = bpy.context.active_object
        col.data.materials.append(mat_marble_white)
        col.parent = root

        # Column gold capital
        bpy.ops.mesh.primitive_cube_add(size=0.35, location=(col_x, -3.25, 3.15))
        cap = bpy.context.active_object
        cap.data.materials.append(mat_gold)
        cap.parent = root

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
    sun_data.energy = 4.8
    sun_data.color = (1.0, 0.98, 0.90)
    sun = bpy.data.objects.new("SunKey", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(52), math.radians(20), math.radians(-35))
    
    # Sky fill
    fill_data = bpy.data.lights.new(name="SkyFill", type='SUN')
    fill_data.energy = 1.8
    fill_data.color = (0.55, 0.82, 1.0)
    fill = bpy.data.objects.new("SkyFill", fill_data)
    scene.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(-50), math.radians(10), math.radians(140))
    
    # Camera
    cam_data = bpy.data.cameras.new("DubaiCam")
    cam_data.lens = 50
    cam_obj = bpy.data.objects.new("DubaiCam", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (11.5, -14.5, 9.8)
    
    target = Vector((0.0, 0.0, 4.5))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    
    bpy.ops.render.render(write_still=True)
    print(f"[DUBAI RENDER COMPLETE] {output_path}")

if __name__ == "__main__":
    build_dubai_palace()
    render_preview(r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_dubai_render.png")
