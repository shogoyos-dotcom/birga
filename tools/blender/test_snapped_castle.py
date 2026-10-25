import bpy
import os
import math
from mathutils import Vector

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def assemble_snapped_castle():
    reset_scene()
    glb_dir = r"D:\antigravity\blender_assets\kenney_castle\Models\GLB format"
    tex_dir = r"D:\antigravity\blender_assets\kenney_castle\Models\Textures"

    root = bpy.data.objects.new("ModularCastle", None)
    bpy.context.scene.collection.objects.link(root)

    def place_glb(filename, loc, rot_z=0, scale=(1, 1, 1)):
        fpath = os.path.join(glb_dir, filename)
        if not os.path.exists(fpath):
            print("MISSING:", fpath)
            return None
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=fpath)
        new_objs = set(bpy.data.objects) - before
        top_obj = None
        for o in new_objs:
            if o.parent is None:
                top_obj = o
                break
        if top_obj:
            top_obj.location = loc
            top_obj.rotation_euler = (0, 0, math.radians(rot_z))
            top_obj.scale = scale
            top_obj.parent = root
        return top_obj

    # 1. Four corner towers (Hexagonal or Square)
    # Tower base: z=0..1. Mid: z=1..2. Roof: sits at z=2.0
    corners = [(-2.0, -2.0), (2.0, -2.0), (-2.0, 2.0), (2.0, 2.0)]
    for cx, cy in corners:
        place_glb("tower-square-base.glb", (cx, cy, 0.0))
        place_glb("tower-square-mid-windows.glb", (cx, cy, 1.0))
        place_glb("tower-square-top-roof-high.glb", (cx, cy, 2.0))
        place_glb("flag-pennant.glb", (cx, cy, 4.0))

    # 2. Curtain Walls connecting towers
    # Wall length is 1.0. Distance between -2 and +2 is 4.0, towers occupy 1.0. Walls at -1.0, 0.0, 1.0
    for side, rot, y_fix in [(1, 0, 2.0), (-1, 180, -2.0)]:
        place_glb("wall.glb", (-1.0, y_fix, 0.0), rot_z=rot)
        place_glb("wall.glb", (1.0, y_fix, 0.0), rot_z=rot)

    # Front Gate & Steps
    place_glb("wall-doorway.glb", (0.0, -2.0, 0.0))
    place_glb("door.glb", (0.0, -2.0, 0.0))
    place_glb("stairs-stone.glb", (0.0, -2.6, 0.0), rot_z=180)

    # Back Wall
    place_glb("wall.glb", (0.0, 2.0, 0.0))

    # Left & Right Walls
    for x_fix, rot in [(-2.0, 90), (2.0, -90)]:
        place_glb("wall.glb", (x_fix, -1.0, 0.0), rot_z=rot)
        place_glb("wall.glb", (x_fix, 0.0, 0.0), rot_z=rot)
        place_glb("wall.glb", (x_fix, 1.0, 0.0), rot_z=rot)

    # 3. Central Great Keep (Grand central cathedral tower)
    # Tier 1
    place_glb("tower-square-base.glb", (0.0, 0.0, 0.0), scale=(1.8, 1.8, 1.0))
    place_glb("tower-square-mid-windows.glb", (0.0, 0.0, 1.0), scale=(1.8, 1.8, 1.2))
    # Tier 2 (upper retreat)
    place_glb("tower-square-mid.glb", (0.0, 0.0, 2.2), scale=(1.4, 1.4, 1.0))
    place_glb("tower-square-mid-windows.glb", (0.0, 0.0, 3.2), scale=(1.2, 1.2, 1.0))
    # High Roof Spire
    place_glb("tower-square-roof.glb", (0.0, 0.0, 4.2), scale=(1.2, 1.2, 1.4))
    place_glb("flag-banner-long.glb", (0.0, 0.0, 7.0))

    # Swap texture to Red Roof variation (variation-b.png)
    var_b_path = os.path.join(tex_dir, "variation-b.png")
    if os.path.exists(var_b_path):
        img_b = bpy.data.images.load(var_b_path)
        for m in bpy.data.materials:
            if m.use_nodes:
                for n in m.node_tree.nodes:
                    if n.type == 'TEX_IMAGE':
                        n.image = img_b

    # Add pine trees around castle
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    pine_path = os.path.join(nature_dir, "tree_pineTallA_detailed.glb")
    if os.path.exists(pine_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=pine_path)
        pine_src = list(set(bpy.data.objects) - before)[0]
        pine_src.location = (1000, 1000, 1000)

        for tx, ty in [(-3.5, -2.5), (-4.0, 0.0), (-3.2, 2.8), (3.5, -2.5), (4.0, 0.0), (3.2, 2.8)]:
            clone = pine_src.copy()
            if pine_src.data: clone.data = pine_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (tx, ty, 0.0)
            clone.scale = (1.3, 1.3, 1.3)
            clone.parent = root

    # Ground Plane with Red Territory Disc
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_Grass")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.62, 0.20, 1.0)
    g.data.materials.append(mat_g)

    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=4.8, depth=0.03, location=(0, 0, 0.02))
    terr = bpy.context.active_object
    terr.parent = root
    mat_t = bpy.data.materials.new("M_Terr")
    mat_t.use_nodes = True
    mat_t.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.90, 0.16, 0.18, 1.0)
    mat_t.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.15
    terr.data.materials.append(mat_t)

    # Lighting
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.2
    sun.color = (1.0, 0.96, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(52), math.radians(20), math.radians(-35))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.8
    fill.color = (0.55, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(10), math.radians(145))

    # Camera
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 45
    cam_obj = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (9.5, -13.5, 9.5)
    target = Vector((0.0, -0.2, 2.6))
    cam_obj.rotation_euler = (target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # Render
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 28
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_modular_castle_perfect.png"
    scene.render.filepath = out_path

    print("RENDERING MODULAR CASTLE PERFECT...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    assemble_snapped_castle()
