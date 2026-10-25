import bpy
import os
import math
from mathutils import Vector

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def assemble():
    reset()
    glb_dir = r"D:\antigravity\blender_assets\kenney_castle\Models\GLB format"

    root = bpy.data.objects.new("ModularCastle", None)
    bpy.context.scene.collection.objects.link(root)

    def place_glb(filename, loc, rot_z=0, scale=(1, 1, 1)):
        fpath = os.path.join(glb_dir, filename)
        if not os.path.exists(fpath):
            print("MISSING:", fpath)
            return None
        # record objects before
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=fpath)
        after = set(bpy.data.objects)
        new_objs = after - before
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

    # 1. Four corner towers
    corners = [(-1.5, -1.5), (1.5, -1.5), (-1.5, 1.5), (1.5, 1.5)]
    for cx, cy in corners:
        place_glb("tower-hexagon-base.glb", (cx, cy, 0))
        place_glb("tower-hexagon-mid.glb", (cx, cy, 1))
        place_glb("tower-hexagon-top.glb", (cx, cy, 2))
        place_glb("tower-hexagon-roof.glb", (cx, cy, 3))
        place_glb("flag-pennant.glb", (cx, cy, 4))

    # 2. Curtain walls
    place_glb("wall.glb", (0, 1.5, 0), rot_z=180) # Back
    place_glb("wall.glb", (-1.5, 0, 0), rot_z=90)  # Left
    place_glb("wall.glb", (1.5, 0, 0), rot_z=-90) # Right
    place_glb("gate.glb", (0, -1.5, 0))            # Front Gate
    place_glb("door.glb", (0, -1.5, 0))            # Front Door
    place_glb("stairs-stone.glb", (0, -2.1, 0), rot_z=180) # Steps

    # 3. Central Keep
    place_glb("tower-square-base.glb", (0, 0, 0))
    place_glb("tower-square-mid-windows.glb", (0, 0, 1))
    place_glb("tower-square-top-roof-high-windows.glb", (0, 0, 2))
    place_glb("tower-square-top-roof-high.glb", (0, 0, 3.2), scale=(0.8, 0.8, 1.1))
    place_glb("flag-banner-long.glb", (0, 0, 4.6))

    # Render
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\test_modular_castle_render.png"
    scene.render.filepath = out_path

    # Ground
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_G")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.60, 0.22, 1.0)
    g.data.materials.append(mat_g)

    # Lighting
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 4.5
    sun.color = (1.0, 0.98, 0.92)
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(52), math.radians(22), math.radians(-35))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.8
    fill.color = (0.55, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-50), math.radians(10), math.radians(145))

    cam = bpy.data.cameras.new("Cam")
    cam.lens = 42
    cam_obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (6.5, -8.5, 6.0)
    target = Vector((0.0, 0.0, 1.8))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    bpy.ops.render.render(write_still=True)
    print("MODULAR_CASTLE_RENDER_SUCCESS")

if __name__ == "__main__":
    assemble()
