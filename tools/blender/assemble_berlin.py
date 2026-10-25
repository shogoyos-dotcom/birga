import bpy
import os
import math
from mathutils import Vector

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def assemble_berlin():
    reset()
    fbx_dir = r"D:\antigravity\blender_assets\kenney_castle\Models\FBX format"
    tex_path = r"D:\antigravity\blender_assets\kenney_castle\Models\Textures\variation-b.png" # Red roof variation

    root = bpy.data.objects.new("Castle_Berlin_Modular", None)
    bpy.context.scene.collection.objects.link(root)

    # Helper to import piece, set texture, and position
    def add_piece(filename, loc, rot_z=0, scale=(1, 1, 1)):
        filepath = os.path.join(fbx_dir, filename)
        if not os.path.exists(filepath):
            print(f"NOT FOUND: {filepath}")
            return None
        # Deselect all
        bpy.ops.object.select_all(action='DESELECT')
        bpy.ops.import_scene.fbx(filepath=filepath)
        imported = bpy.context.selected_objects
        if not imported:
            return None
        main_obj = imported[0]
        main_obj.location = loc
        main_obj.rotation_euler = (0, 0, math.radians(rot_z))
        main_obj.scale = scale
        main_obj.parent = root
        return main_obj

    # Assemble modular fairytale castle:
    # 1. Four corner round towers
    # Front-left
    add_piece("tower-hexagon-base.fbx", (-2, -2, 0))
    add_piece("tower-hexagon-mid.fbx", (-2, -2, 1))
    add_piece("tower-hexagon-top.fbx", (-2, -2, 2))
    add_piece("tower-hexagon-roof.fbx", (-2, -2, 3))
    add_piece("flag-pennant.fbx", (-2, -2, 4))

    # Front-right
    add_piece("tower-hexagon-base.fbx", (2, -2, 0))
    add_piece("tower-hexagon-mid.fbx", (2, -2, 1))
    add_piece("tower-hexagon-top.fbx", (2, -2, 2))
    add_piece("tower-hexagon-roof.fbx", (2, -2, 3))
    add_piece("flag-pennant.fbx", (2, -2, 4))

    # Back-left
    add_piece("tower-hexagon-base.fbx", (-2, 2, 0))
    add_piece("tower-hexagon-mid.fbx", (-2, 2, 1))
    add_piece("tower-hexagon-top.fbx", (-2, 2, 2))
    add_piece("tower-hexagon-roof.fbx", (-2, 2, 3))
    add_piece("flag-pennant.fbx", (-2, 2, 4))

    # Back-right
    add_piece("tower-hexagon-base.fbx", (2, 2, 0))
    add_piece("tower-hexagon-mid.fbx", (2, 2, 1))
    add_piece("tower-hexagon-top.fbx", (2, 2, 2))
    add_piece("tower-hexagon-roof.fbx", (2, 2, 3))
    add_piece("flag-pennant.fbx", (2, 2, 4))

    # 2. Curtain walls connecting towers
    add_piece("wall.fbx", (0, 2, 0), rot_z=180) # Back wall
    add_piece("wall.fbx", (-2, 0, 0), rot_z=90) # Left wall
    add_piece("wall.fbx", (2, 0, 0), rot_z=-90) # Right wall
    add_piece("gate.fbx", (0, -2, 0)) # Front gate
    add_piece("door.fbx", (0, -2, 0)) # Gate door

    # 3. Central Keep & Spires
    add_piece("tower-square-base.fbx", (0, 0, 0))
    add_piece("tower-square-mid-windows.fbx", (0, 0, 1))
    add_piece("tower-square-top-roof-high-windows.fbx", (0, 0, 2))
    add_piece("tower-square-top-roof-high.fbx", (0, 0, 3.5), scale=(0.85, 0.85, 1.2))
    add_piece("flag-banner-long.fbx", (0, 0, 5.2))

    # 4. Stone entrance stairs
    add_piece("stairs-stone.fbx", (0, -2.8, 0), rot_z=180)

    # 5. Apply texture to all imported materials
    if os.path.exists(tex_path):
        tex_image = bpy.data.images.load(tex_path)
        for mat in bpy.data.materials:
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                # Add image texture node
                tex_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
                tex_node.image = tex_image
                tex_node.interpolation = 'Closest' # Crisp pixel-art / toon mobile texture
                mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
                bsdf.inputs['Roughness'].default_value = 0.65

    # 6. Render preview
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_berlin_modular_render.png"
    scene.render.filepath = out_path

    # Ground
    bpy.ops.mesh.primitive_plane_add(size=25, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_Floor")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.58, 0.22, 1.0)
    g.data.materials.append(mat_g)

    # Three-point studio lighting
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.0
    sun.color = (1.0, 0.98, 0.92)
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(52), math.radians(22), math.radians(-35))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 2.0
    fill.color = (0.55, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-50), math.radians(10), math.radians(145))

    cam = bpy.data.cameras.new("Cam")
    cam.lens = 45
    cam_obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (8.5, -10.5, 7.5)
    target = Vector((0.0, 0.0, 2.2))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    bpy.ops.render.render(write_still=True)
    print(f"RENDER COMPLETE: {out_path}")

if __name__ == "__main__":
    assemble_berlin()
