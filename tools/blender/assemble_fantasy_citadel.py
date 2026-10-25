import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

GLB_DIR = r"D:\antigravity\blender_assets\kenney_castle\Models\GLB format"
TEX_DIR = r"D:\antigravity\blender_assets\kenney_castle\Models\Textures"

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_glb_piece(name):
    path = os.path.join(GLB_DIR, name)
    if not os.path.exists(path):
        print(f"ERROR: Missing piece {path}")
        return []
    existing = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in existing and o.type == 'MESH']
    return new_objs

def assemble_fantasy_castle():
    reset_scene()
    
    root = bpy.data.objects.new("FantasyCitadel_AAA", None)
    bpy.context.scene.collection.objects.link(root)
    
    tex_path = os.path.join(TEX_DIR, "variation-a.png")
    mat_castle = bpy.data.materials.new("M_FantasyCastleAtlas")
    mat_castle.use_nodes = True
    bsdf = mat_castle.node_tree.nodes['Principled BSDF']
    tex_node = mat_castle.node_tree.nodes.new('ShaderNodeTexImage')
    if os.path.exists(tex_path):
        tex_node.image = bpy.data.images.load(tex_path)
        tex_node.interpolation = 'Closest'
        mat_castle.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
    bsdf.inputs['Roughness'].default_value = 0.55
    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = 0.4
        
    all_pieces = []
    
    def place(piece_name, loc, rot_z_deg=0, scale=(1,1,1)):
        objs = import_glb_piece(piece_name)
        for obj in objs:
            obj.location = Vector(loc)
            obj.rotation_euler = Euler((0, 0, math.radians(rot_z_deg)), 'XYZ')
            obj.scale = Vector(scale)
            obj.parent = root
            obj.data.materials.clear()
            obj.data.materials.append(mat_castle)
            all_pieces.append(obj)
        return objs

    # 1. FOUR CORNER TURRETS (Hexagonal towers with conical spires & flags)
    # Front-Left Corner (-1.5, -1.5)
    place("tower-hexagon-base.glb", (-1.5, -1.5, 0), 0)
    place("tower-hexagon-mid.glb", (-1.5, -1.5, 1.31), 0)
    place("tower-hexagon-top.glb", (-1.5, -1.5, 1.77), 0)
    place("tower-hexagon-roof.glb", (-1.5, -1.5, 1.90), 0)
    place("flag-pennant.glb", (-1.5, -1.5, 2.73), 45)

    # Front-Right Corner (+1.5, -1.5)
    place("tower-hexagon-base.glb", (1.5, -1.5, 0), 0)
    place("tower-hexagon-mid.glb", (1.5, -1.5, 1.31), 0)
    place("tower-hexagon-top.glb", (1.5, -1.5, 1.77), 0)
    place("tower-hexagon-roof.glb", (1.5, -1.5, 1.90), 0)
    place("flag-pennant.glb", (1.5, -1.5, 2.73), -45)

    # Back-Left Corner (-1.5, 1.5)
    place("tower-hexagon-base.glb", (-1.5, 1.5, 0), 0)
    place("tower-hexagon-mid.glb", (-1.5, 1.5, 1.31), 0)
    place("tower-hexagon-top.glb", (-1.5, 1.5, 1.77), 0)
    place("tower-hexagon-roof.glb", (-1.5, 1.5, 1.90), 0)
    place("flag-pennant.glb", (-1.5, 1.5, 2.73), 135)

    # Back-Right Corner (+1.5, 1.5)
    place("tower-hexagon-base.glb", (1.5, 1.5, 0), 0)
    place("tower-hexagon-mid.glb", (1.5, 1.5, 1.31), 0)
    place("tower-hexagon-top.glb", (1.5, 1.5, 1.77), 0)
    place("tower-hexagon-roof.glb", (1.5, 1.5, 1.90), 0)
    place("flag-pennant.glb", (1.5, 1.5, 2.73), -135)

    # 2. CURTAIN WALLS & BATTLEMENTS
    place("wall.glb", (-1.5, 0, 0), 90)
    place("wall.glb", (1.5, 0, 0), -90)
    place("wall.glb", (0, 1.5, 0), 180)
    
    # Front Gatehouse
    place("wall-doorway.glb", (-0.5, -1.5, 0), 0)
    place("wall-doorway.glb", (0.5, -1.5, 0), 180)
    place("metal-gate.glb", (0, -1.5, 0), 0)
    
    # Courtyard Stairs
    place("stairs-stone.glb", (-1.0, -0.6, 0), 0)
    place("stairs-stone.glb", (1.0, -0.6, 0), 0)

    # 3. GRAND CENTRAL KEEP (Multi-tiered soaring keep)
    place("tower-square-base.glb", (0, 0.2, 0), 0, scale=(1.8, 1.8, 1.0))
    place("tower-square-mid-door.glb", (0, 0.2, 1.01), 0, scale=(1.75, 1.75, 1.0))
    place("tower-square-mid-windows.glb", (0, 0.2, 2.02), 0, scale=(1.65, 1.65, 1.0))
    place("tower-square-top.glb", (0, 0.2, 3.03), 0, scale=(1.7, 1.7, 1.0))
    
    # Upper Tier
    place("tower-square-mid-windows.glb", (0, 0.2, 3.33), 0, scale=(1.25, 1.25, 1.1))
    place("tower-square-top-roof-high-windows.glb", (0, 0.2, 4.44), 0, scale=(1.35, 1.35, 1.35))
    
    # High Spire & Royal Banner
    place("tower-square-roof.glb", (0, 0.2, 5.89), 0, scale=(0.85, 0.85, 1.4))
    place("flag-banner-long.glb", (0, -0.5, 3.5), 0, scale=(1.2, 1.2, 1.2))

    # Front Causeway Ramp
    place("bridge-straight.glb", (0, -2.5, 0), 90)

    # Join pieces into single mesh
    bpy.ops.object.select_all(action='DESELECT')
    for p in all_pieces:
        p.select_set(True)
    bpy.context.view_layer.objects.active = all_pieces[0]
    bpy.ops.object.join()
    
    citadel = bpy.context.active_object
    citadel.name = "FantasyCastle_ProofOfQuality"
    citadel.parent = root

    # Calculate Z min of geometry and shift so bottom is exactly at Z=0!
    min_z = min(v.co.z for v in citadel.data.vertices)
    for v in citadel.data.vertices:
        v.co.z -= min_z
        
    verts = len(citadel.data.vertices)
    tris = len(citadel.data.polygons)
    print(f"=== ASSEMBLED CITADEL STATS ===")
    print(f"Total Vertices: {verts}")
    print(f"Total Triangles: {tris}")
    print(f"Materials: {len(citadel.data.materials)}")
    
    return citadel, root

def render_preview():
    citadel, root = assemble_fantasy_castle()
    
    # Ground platform placed strictly underneath the castle (z <= 0)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=6.5, depth=0.3, location=(0, -0.5, -0.15))
    ground = bpy.context.active_object
    ground.name = "GroundPedestal"
    g_mat = bpy.data.materials.new("M_ForestPedestal")
    g_mat.use_nodes = True
    g_bsdf = g_mat.node_tree.nodes['Principled BSDF']
    g_bsdf.inputs['Base Color'].default_value = (0.22, 0.42, 0.16, 1.0) # Rich stylized grass green
    g_bsdf.inputs['Roughness'].default_value = 0.85
    ground.data.materials.append(g_mat)
    
    # Camera aiming at castle center (x=0, y=-0.5, z=2.8)
    cam_data = bpy.data.cameras.new("CastleCam")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new("CastleCam", cam_data)
    cam_obj.location = (11.0, -12.0, 9.5)
    
    # Aim camera directly at (0, -0.5, 2.8)
    target = Vector((0, -0.5, 2.8))
    dir_vec = target - cam_obj.location
    rot_quat = dir_vec.to_track_quat('-Z', 'Y')
    cam_obj.rotation_euler = rot_quat.to_euler()
    
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    # Three-Point Lighting
    # 1. Warm Sun Key
    sun_data = bpy.data.lights.new("Sun_Key", type='SUN')
    sun_data.energy = 5.5
    sun_data.color = (1.0, 0.95, 0.88)
    sun_data.angle = 0.06
    sun_obj = bpy.data.objects.new("Sun_Key", sun_data)
    sun_obj.rotation_euler = (math.radians(48), math.radians(18), math.radians(-35))
    bpy.context.scene.collection.objects.link(sun_obj)
    
    # 2. Cyan Sky Fill
    sky_data = bpy.data.lights.new("Sky_Fill", type='SUN')
    sky_data.energy = 2.0
    sky_data.color = (0.68, 0.85, 1.0)
    sky_obj = bpy.data.objects.new("Sky_Fill", sky_data)
    sky_obj.rotation_euler = (math.radians(60), math.radians(-35), math.radians(145))
    bpy.context.scene.collection.objects.link(sky_obj)
    
    # 3. Warm Bounce Rim
    rim_data = bpy.data.lights.new("Rim_Bounce", type='SUN')
    rim_data.energy = 1.2
    rim_data.color = (1.0, 0.9, 0.7)
    rim_obj = bpy.data.objects.new("Rim_Bounce", rim_data)
    rim_obj.rotation_euler = (math.radians(-30), 0, math.radians(60))
    bpy.context.scene.collection.objects.link(rim_obj)
    
    # World background
    world = bpy.data.worlds.new("World_Studio")
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.12, 0.15, 0.18, 1.0)
    bg.inputs['Strength'].default_value = 0.6
    bpy.context.scene.world = world
    
    # Export FBX for Unity
    fbx_out = r"d:\antigravity\color land\color_land_unity\Assets\Models\fantasy_castle_proof.fbx"
    bpy.ops.object.select_all(action='DESELECT')
    citadel.select_set(True)
    bpy.context.view_layer.objects.active = citadel
    bpy.ops.export_scene.fbx(
        filepath=fbx_out,
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y'
    )
    print(f"Exported FBX to: {fbx_out}")
    
    # Render with Cycles
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 64
    scene.render.resolution_x = 1000
    scene.render.resolution_y = 1000
    out_render = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_fantasy_castle_proof.png"
    scene.render.filepath = out_render
    
    bpy.ops.render.render(write_still=True)
    print(f"Rendered proof image: {out_render}")

render_preview()
