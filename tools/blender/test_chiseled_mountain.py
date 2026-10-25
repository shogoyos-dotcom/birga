import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, noise

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_rock_material():
    mat = bpy.data.materials.new("M_StylizedRock")
    mat.use_nodes = True
    tree = mat.node_tree
    nodes = tree.nodes
    links = tree.links
    nodes.clear()

    # Geometry node for Pointiness / Normal
    geom = nodes.new("ShaderNodeNewGeometry")
    geom.location = (-600, 200)

    # Color Ramp for height / slope gradient
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-600, -100)

    sep_xyz = nodes.new("ShaderNodeSeparateXYZ")
    sep_xyz.location = (-400, -100)
    links.new(tex_coord.outputs["Object"], sep_xyz.inputs["Vector"])

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-200, -100)
    # Slate grey-brown rock at bottom to pale warm limestone grey at top
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.35, 0.33, 0.31, 1.0)
    ramp.color_ramp.elements[1].position = 0.7
    ramp.color_ramp.elements[1].color = (0.58, 0.55, 0.50, 1.0)
    # Add snow/chalk highlight at summit
    el = ramp.color_ramp.elements.new(0.95)
    el.color = (0.82, 0.84, 0.86, 1.0)
    links.new(sep_xyz.outputs["Z"], ramp.inputs["Fac"])

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (100, 0)
    bsdf.inputs["Roughness"].default_value = 0.75
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat

def generate_chiseled_mountain():
    reset_scene()

    # Create grid
    res = 80
    size = 14.0
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=res, y_subdivisions=res, size=size, location=(0, 0, 0))
    mtn = bpy.context.active_object
    mtn.name = "ChiseledMountain"

    mesh = mtn.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    for v in bm.verts:
        x, y = v.co.x, v.co.y
        dist = math.sqrt(x*x + y*y)
        # Radial mountain mask (peaks at center, fades to flat ground at r=6)
        r_norm = dist / (size * 0.45)
        if r_norm >= 1.0:
            v.co.z = 0.0
            continue
        mask = math.cos(r_norm * math.pi * 0.5) ** 2.0

        # Multi-frequency ridged noise
        # Primary sharp ridge using genuine procedural ridged multifractal
        pos = Vector((x * 0.28, y * 0.28, 0.0))
        rmf = noise.ridged_multi_fractal(pos, 0.9, 2.1, 4, 1.0, 2.0)
        
        # Terracing formula for horizontal rock strata
        raw_h = max(0.0, rmf * 3.8 * mask)
        step_freq = 1.4
        terrace = math.floor(raw_h * step_freq) / step_freq
        blend = 0.55
        h = raw_h * (1.0 - blend) + terrace * blend

        v.co.z = max(0.0, h)

    bm.to_mesh(mesh)
    bm.free()

    # Modifiers:
    # 1. Bevel / Decimate for sharp stylized faceted rock look
    dec = mtn.modifiers.new("Decimate", 'DECIMATE')
    dec.decimate_type = 'COLLAPSE'
    dec.ratio = 0.28  # Keep clean low-poly chiseled facets!

    # Apply decimate
    bpy.ops.object.select_all(action='DESELECT')
    mtn.select_set(True)
    bpy.context.view_layer.objects.active = mtn
    bpy.ops.object.modifier_apply(modifier="Decimate")

    # Flat shading for crystal-clear stylized facets!
    for p in mtn.data.polygons:
        p.use_smooth = False

    mtn.data.materials.append(create_rock_material())

    # Add pine trees around mountain base and ledges
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    pine_path = os.path.join(nature_dir, "tree_pineTallA_detailed.glb")
    if os.path.exists(pine_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=pine_path)
        pine_src = list(set(bpy.data.objects) - before)[0]
        pine_src.location = (1000, 1000, 1000)

        # Spawn pine trees along slopes
        random.seed(123)
        for i in range(22):
            ang = random.uniform(0, 2 * math.pi)
            rad = random.uniform(3.5, 6.2)
            px = math.cos(ang) * rad
            py = math.sin(ang) * rad
            # find height near point
            clone = pine_src.copy()
            if pine_src.data: clone.data = pine_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (px, py, 0.0)
            scl = random.uniform(0.9, 1.4)
            clone.scale = (scl, scl, scl)
            clone.rotation_euler = (0, 0, random.uniform(0, 2*math.pi))

    # Ground Plane
    bpy.ops.mesh.primitive_plane_add(size=35, location=(0, 0, -0.02))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_Grass")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.62, 0.22, 1.0)
    g.data.materials.append(mat_g)

    # Lighting
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.0
    sun.color = (1.0, 0.96, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), math.radians(20), math.radians(-35))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.8
    fill.color = (0.55, 0.80, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(10), math.radians(145))

    # Camera
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 45
    cam_obj = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (11.0, -15.0, 9.5)
    target = Vector((0.0, 0.0, 2.2))
    cam_obj.rotation_euler = (target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # Render
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\test_chiseled_mountain_render.png"
    scene.render.filepath = out_path

    print("RENDERING CHISELED MOUNTAIN...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    generate_chiseled_mountain()
