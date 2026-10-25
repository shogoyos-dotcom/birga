import bpy
import os
import math
import random
from mathutils import Vector

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, base_color, roughness=0.7):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
    return mat

def load_glb(fpath):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=fpath)
    new_objs = list(set(bpy.data.objects) - before)
    # find top object or create empty to group if multiple
    top_objs = [o for o in new_objs if o.parent is None]
    if len(top_objs) == 1:
        return top_objs[0], new_objs
    grp = bpy.data.objects.new("Group", None)
    bpy.context.scene.collection.objects.link(grp)
    for o in top_objs:
        o.parent = grp
    return grp, new_objs

def duplicate_hierarchy(root_obj, new_parent=None):
    # duplicate object and all its children
    obj_map = {}
    def copy_obj(src):
        new_o = src.copy()
        if src.data:
            new_o.data = src.data.copy()
        bpy.context.scene.collection.objects.link(new_o)
        obj_map[src] = new_o
        for ch in src.children:
            ch_copy = copy_obj(ch)
            ch_copy.parent = new_o
        return new_o

    top_copy = copy_obj(root_obj)
    if new_parent:
        top_copy.parent = new_parent
    return top_copy

def build_mountain():
    reset_scene()
    random.seed(42)

    root = bpy.data.objects.new("CraggyMountainFormation", None)
    bpy.context.scene.collection.objects.link(root)

    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"

    # Preload master assets
    assets = {}
    master_keys = [
        "cliff_large_stone",
        "cliff_block_stone",
        "rock_tallA",
        "rock_tallB",
        "rock_largeA",
        "rock_largeB",
        "tree_pineTallA_detailed",
        "tree_pineTallB_detailed"
    ]

    for k in master_keys:
        p = os.path.join(nature_dir, f"{k}.glb")
        if os.path.exists(p):
            top_o, all_o = load_glb(p)
            top_o.location = (1000, 1000, 1000) # hide master away
            assets[k] = top_o

    def spawn_asset(key, loc, rot_z_deg=0, scale=(1, 1, 1)):
        if key not in assets:
            return None
        src = assets[key]
        clone = duplicate_hierarchy(src, new_parent=root)
        clone.location = loc
        clone.rotation_euler = (0, 0, math.radians(rot_z_deg))
        clone.scale = scale
        return clone

    # 1. Base tier of cliffs (Massive mountain base: width ~12, depth ~10)
    base_cliff_positions = [
        # Front row
        ("cliff_large_stone", (-3.5, -2.5, 0.0), 15, (2.8, 2.5, 2.8)),
        ("cliff_large_stone", (0.5, -3.0, 0.0), -20, (3.2, 2.8, 3.2)),
        ("cliff_large_stone", (4.0, -2.2, 0.0), 45, (2.6, 2.4, 2.6)),
        # Back/mid row
        ("cliff_large_stone", (-4.2, 0.5, 0.5), -75, (3.0, 2.8, 3.0)),
        ("cliff_large_stone", (-1.0, 1.2, 0.8), 110, (3.4, 3.0, 3.4)),
        ("cliff_large_stone", (3.2, 1.0, 0.6), -135, (3.2, 2.7, 3.2)),
        ("cliff_large_stone", (0.0, -0.5, 0.4), 0, (3.0, 3.0, 3.0)),
    ]
    for key, loc, rot, scl in base_cliff_positions:
        spawn_asset(key, loc, rot, scl)

    # 2. Second tier (Mid-mountain cliffs: width ~8, elevation +2.5 to +4.5)
    mid_cliff_positions = [
        ("cliff_block_stone", (-2.2, -1.2, 2.6), 35, (2.5, 2.5, 2.5)),
        ("cliff_large_stone", (0.8, -0.8, 2.8), -40, (2.8, 2.8, 2.8)),
        ("cliff_block_stone", (2.5, 0.2, 2.4), 85, (2.3, 2.3, 2.3)),
        ("cliff_large_stone", (-1.2, 0.8, 3.2), 160, (2.7, 2.7, 2.7)),
        ("cliff_large_stone", (1.5, 1.2, 3.0), -90, (2.5, 2.5, 2.5)),
    ]
    for key, loc, rot, scl in mid_cliff_positions:
        spawn_asset(key, loc, rot, scl)

    # 3. Third tier (High craggy ridge: elevation +5.0 to +7.5)
    high_cliff_positions = [
        ("rock_tallA", (-0.8, -0.3, 5.2), 25, (3.2, 3.0, 4.0)),
        ("rock_tallB", (0.6, 0.2, 5.5), -60, (3.0, 2.8, 4.2)),
        ("cliff_block_stone", (-0.2, 0.8, 5.0), 120, (2.2, 2.2, 2.5)),
    ]
    for key, loc, rot, scl in high_cliff_positions:
        spawn_asset(key, loc, rot, scl)

    # 4. Jagged Alpine Peak Summit (Elevation +8.0 to +10.5)
    summit_positions = [
        ("rock_tallA", (0.0, 0.1, 7.8), 10, (2.2, 2.2, 3.6)),
        ("rock_tallB", (-0.5, 0.3, 7.5), -45, (1.8, 1.8, 3.2)),
        ("rock_tallB", (0.4, -0.2, 7.6), 75, (1.9, 1.9, 3.3)),
    ]
    for key, loc, rot, scl in summit_positions:
        spawn_asset(key, loc, rot, scl)

    # 5. Talus Scree & Boulders at base and on terraces
    scree_positions = [
        ("rock_largeA", (-5.2, -2.8, 0.0), 30, (1.8, 1.8, 1.5)),
        ("rock_largeB", (-4.0, -4.0, 0.0), -65, (1.5, 1.5, 1.3)),
        ("rock_largeA", (-1.5, -4.2, 0.0), 105, (1.9, 1.9, 1.6)),
        ("rock_largeB", (2.2, -4.5, 0.0), -20, (2.0, 2.0, 1.7)),
        ("rock_largeA", (5.5, -2.5, 0.0), 80, (1.7, 1.7, 1.4)),
        ("rock_largeB", (4.8, -0.8, 0.0), -115, (1.6, 1.6, 1.5)),
        # Ledge boulders
        ("rock_largeA", (-2.8, -0.5, 2.9), 40, (1.2, 1.2, 1.0)),
        ("rock_largeB", (1.8, -1.5, 3.2), -35, (1.1, 1.1, 0.9)),
        ("rock_largeA", (-0.2, 1.8, 3.5), 95, (1.3, 1.3, 1.1)),
    ]
    for key, loc, rot, scl in scree_positions:
        spawn_asset(key, loc, rot, scl)

    # 6. Clustered Lush Pine Trees on Ledges and Slopes (matching reference!)
    pine_positions = [
        # Base clusters
        ("tree_pineTallA_detailed", (-4.8, -3.2, 0.0), 12, (1.6, 1.6, 1.6)),
        ("tree_pineTallB_detailed", (-5.6, -2.2, 0.0), -45, (1.4, 1.4, 1.4)),
        ("tree_pineTallA_detailed", (-3.8, -4.5, 0.0), 80, (1.2, 1.2, 1.2)),
        ("tree_pineTallB_detailed", (3.8, -3.8, 0.0), -25, (1.5, 1.5, 1.5)),
        ("tree_pineTallA_detailed", (5.2, -3.2, 0.0), 60, (1.7, 1.7, 1.7)),
        ("tree_pineTallB_detailed", (6.0, -1.8, 0.0), -90, (1.3, 1.3, 1.3)),
        # Mid-tier ledge clusters
        ("tree_pineTallA_detailed", (-3.2, -1.8, 2.7), 35, (1.3, 1.3, 1.3)),
        ("tree_pineTallB_detailed", (-3.8, -1.0, 2.6), -15, (1.1, 1.1, 1.1)),
        ("tree_pineTallA_detailed", (2.8, -1.8, 2.5), 110, (1.4, 1.4, 1.4)),
        ("tree_pineTallB_detailed", (3.2, -0.8, 2.6), -70, (1.2, 1.2, 1.2)),
        # High shelf pines
        ("tree_pineTallA_detailed", (-1.8, 0.2, 5.1), 45, (1.1, 1.1, 1.1)),
        ("tree_pineTallB_detailed", (1.2, 0.5, 5.2), -55, (1.0, 1.0, 1.0)),
    ]
    for key, loc, rot, scl in pine_positions:
        spawn_asset(key, loc, rot, scl)

    # Ground Plane with lush stylized green grass
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = create_material("M_MountainGround", (0.32, 0.62, 0.24, 1.0), roughness=0.65)
    g.data.materials.append(mat_g)

    # Render Setup
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_mountain_pro_render.png"
    scene.render.filepath = out_path

    # Lighting (Warm directional sun with cool sky fill)
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.2
    sun.color = (1.0, 0.96, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(52), math.radians(20), math.radians(-35))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.9
    fill.color = (0.58, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-40), math.radians(15), math.radians(145))

    # Camera
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 48
    cam_obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (12.0, -16.0, 10.5)
    target = Vector((0.0, -0.5, 4.5))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    print("RENDERING MOUNTAIN PRO...")
    bpy.ops.render.render(write_still=True)
    print("RENDER_COMPLETE:", out_path)

if __name__ == "__main__":
    build_mountain()
