import bpy
import bmesh
import math
import os
from mathutils import Vector

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def apply_bevel(obj, width=0.035, segments=2):
    bev = obj.modifiers.new("Bevel", 'BEVEL')
    bev.width = width
    bev.segments = segments
    bev.profile = 0.7
    bev.limit_method = 'ANGLE'
    bev.angle_limit = math.radians(35)
    return bev

def create_pbr_material(name, base_color, metallic=0.0, roughness=0.5, specular=0.5):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = specular
        elif "Specular" in bsdf.inputs:
            bsdf.inputs["Specular"].default_value = specular
    return mat

def create_golden_onion_dome(name, radius=1.0, height=1.65, ribs=16):
    """Creates a lavish Arabian / Sheikh Zayed gold onion dome"""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    v_segments = 28
    u_segments = 32
    verts_grid = []

    for v in range(v_segments + 1):
        t = v / v_segments
        z = t * height
        # Onion dome profile: flares wide in lower half, curves in, then shoots to sharp needle
        if t < 0.4:
            base_r = radius * (0.92 + 0.28 * math.sin(t / 0.4 * (math.pi / 2)))
        elif t < 0.82:
            tn = (t - 0.4) / 0.42
            base_r = radius * (1.20 - 0.72 * math.sin(tn * (math.pi / 2)))
        else:
            tn = max(0.0, min(1.0, (t - 0.82) / 0.18))
            base_r = radius * 0.48 * ((1.0 - tn) ** 1.35)

        row = []
        for u in range(u_segments):
            phi = u * (2 * math.pi / u_segments)
            # Subtle radial ribs
            rib = 1.0 + 0.04 * math.cos(ribs * phi) * math.sin(t * math.pi)
            x = base_r * rib * math.cos(phi)
            y = base_r * rib * math.sin(phi)
            row.append(bm.verts.new((x, y, z)))
        verts_grid.append(row)

    apex = bm.verts.new((0, 0, height + 0.08))

    for v in range(v_segments - 1):
        for u in range(u_segments):
            u_next = (u + 1) % u_segments
            bm.faces.new((verts_grid[v][u], verts_grid[v][u_next], verts_grid[v + 1][u_next], verts_grid[v + 1][u]))

    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        bm.faces.new((verts_grid[v_segments - 1][u], verts_grid[v_segments - 1][u_next], apex))

    base_center = bm.verts.new((0, 0, 0))
    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        bm.faces.new((base_center, verts_grid[0][u_next], verts_grid[0][u]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    for p in mesh.polygons:
        p.use_smooth = True

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def build_dubai_palace_master():
    reset_scene()

    # Luxury materials
    mat_white_marble = create_pbr_material("M_WhiteMarble", (0.96, 0.96, 0.94, 1.0), roughness=0.25, specular=0.85)
    mat_gold = create_pbr_material("M_LuxuryGold", (1.0, 0.84, 0.24, 1.0), metallic=0.98, roughness=0.15)
    mat_stone_plinth = create_pbr_material("M_PlinthGoldTrim", (0.88, 0.82, 0.70, 1.0), roughness=0.45)
    mat_arch_shadow = create_pbr_material("M_ArchShadow", (0.10, 0.08, 0.05, 1.0), roughness=0.50)

    root = bpy.data.objects.new("DubaiPalaceMaster", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Multi-Tiered Marble Podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    pod = bpy.context.active_object
    pod.scale = (8.8, 5.8, 0.5)
    pod.parent = root
    pod.data.materials.append(mat_white_marble)
    apply_bevel(pod, width=0.04)

    # Golden Perimeter Curb Trim
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.52))
    curb = bpy.context.active_object
    curb.scale = (9.0, 6.0, 0.08)
    curb.parent = root
    curb.data.materials.append(mat_gold)

    # Grand Double Curved Staircase
    for i, (sw, sl, sz) in enumerate([(4.8, 1.2, 0.18), (4.4, 0.85, 0.35), (4.0, 0.5, 0.52)]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -3.1 - (2 - i) * 0.28, sz / 2))
        st = bpy.context.active_object
        st.scale = (sw, 0.38, sz)
        st.parent = root
        st.data.materials.append(mat_white_marble)
        apply_bevel(st, width=0.02)

    # 2. Main Palace Body
    body_w, body_d, body_h = 7.4, 4.0, 2.6
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.52 + body_h / 2))
    body = bpy.context.active_object
    body.scale = (body_w, body_d, body_h)
    body.parent = root
    body.data.materials.append(mat_white_marble)
    apply_bevel(body, width=0.04)

    # Golden Cornice Bands
    for mz in [0.52 + 1.3, 0.52 + body_h]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, mz))
        cornice = bpy.context.active_object
        cornice.scale = (body_w * 1.03, body_d * 1.03, 0.14)
        cornice.parent = root
        cornice.data.materials.append(mat_gold)

    # Colonnade of Arches along Facade
    for cx in [-2.7, -1.8, -0.9, 0.9, 1.8, 2.7]:
        # Arched niche
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, -2.22, 0.52 + 0.9))
        niche = bpy.context.active_object
        niche.scale = (0.65, 0.15, 1.4)
        niche.parent = root
        niche.data.materials.append(mat_arch_shadow)

        # Arch Horseshoe Crown
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.36, depth=0.18, location=(cx, -2.22, 0.52 + 1.6))
        crown = bpy.context.active_object
        crown.rotation_euler = (math.radians(90), 0, 0)
        crown.parent = root
        crown.data.materials.append(mat_gold)

        # Columns
        for col_side in [-0.42, 0.42]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.08, depth=1.5, location=(cx + col_side, -2.25, 0.52 + 0.75))
            c_col = bpy.context.active_object
            c_col.parent = root
            c_col.data.materials.append(mat_white_marble)

    # Grand Central Arched Entrance
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.22, 0.52 + 1.15))
    c_arch = bpy.context.active_object
    c_arch.scale = (1.4, 0.25, 1.8)
    c_arch.parent = root
    c_arch.data.materials.append(mat_arch_shadow)

    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.75, depth=0.28, location=(0, -2.22, 0.52 + 2.05))
    c_crown = bpy.context.active_object
    c_crown.rotation_euler = (math.radians(90), 0, 0)
    c_crown.parent = root
    c_crown.data.materials.append(mat_gold)

    # 3. Central Grand Golden Onion Dome
    drum_z = 0.52 + body_h + 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.65, depth=1.0, location=(0, 0.0, drum_z))
    c_drum = bpy.context.active_object
    c_drum.parent = root
    c_drum.data.materials.append(mat_white_marble)

    # Drum Gold Frieze
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.72, depth=0.22, location=(0, 0.0, drum_z - 0.25))
    c_drum_gold = bpy.context.active_object
    c_drum_gold.parent = root
    c_drum_gold.data.materials.append(mat_gold)

    # Giant Gleaming Golden Onion Dome
    dome = create_golden_onion_dome("Central_Gold_Dome", radius=1.70, height=2.4, ribs=20)
    dome.location = (0, 0.0, drum_z + 0.5)
    dome.parent = root
    dome.data.materials.append(mat_gold)

    # Grand Golden Finial
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.28, location=(0, 0.0, drum_z + 3.05))
    fin_orb = bpy.context.active_object
    fin_orb.parent = root
    fin_orb.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.10, radius2=0.0, depth=0.9, location=(0, 0.0, drum_z + 3.55))
    fin_cone = bpy.context.active_object
    fin_cone.parent = root
    fin_cone.data.materials.append(mat_gold)

    # 4. Four Corner Golden Onion Domes & Minarets
    corner_locs = [(-3.6, -1.8), (3.6, -1.8), (-3.6, 1.4), (3.6, 1.4)]
    for idx, (cx, cy) in enumerate(corner_locs):
        # Corner Tower
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.85, depth=body_h + 0.8, location=(cx, cy, 0.52 + (body_h + 0.8)/2))
        tower = bpy.context.active_object
        tower.parent = root
        tower.data.materials.append(mat_white_marble)

        # Gold Trim
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.92, depth=0.2, location=(cx, cy, 0.52 + body_h + 0.85))
        t_gold = bpy.context.active_object
        t_gold.parent = root
        t_gold.data.materials.append(mat_gold)

        # Corner Dome
        s_dome = create_golden_onion_dome(f"Corner_Dome_{idx}", radius=0.88, height=1.35, ribs=12)
        s_dome.location = (cx, cy, 0.52 + body_h + 0.95)
        s_dome.parent = root
        s_dome.data.materials.append(mat_gold)

        # Corner Spire
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.07, radius2=0.0, depth=0.7, location=(cx, cy, 0.52 + body_h + 2.5))
        s_spire = bpy.context.active_object
        s_spire.parent = root
        s_spire.data.materials.append(mat_gold)

    # 5. Tropical Date Palms & Lush Lawn around Dubai Palace
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    palm_path = os.path.join(nature_dir, "tree_palmDetailedTall.glb")
    if os.path.exists(palm_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=palm_path)
        palm_src = list(set(bpy.data.objects) - before)[0]
        palm_src.location = (1000, 1000, 1000)

        palm_locs = [
            (-5.2, -2.4, 0.0), (-5.6, -0.6, 0.0), (-4.8, 1.2, 0.0),
            (5.2, -2.4, 0.0), (5.6, -0.6, 0.0), (4.8, 1.2, 0.0),
            (-3.2, 2.5, 0.0), (0.0, 2.6, 0.0), (3.2, 2.5, 0.0)
        ]
        for px, py, pz in palm_locs:
            clone = palm_src.copy()
            if palm_src.data: clone.data = palm_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (px, py, pz)
            clone.scale = (1.4, 1.4, 1.4)
            clone.parent = root

    # Ground Plane
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_DubaiLawn")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.34, 0.65, 0.22, 1.0)
    g.data.materials.append(mat_g)

    # Glossy Yellow Captured Territory Disc (Dubai Yellow in reference!)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=5.8, depth=0.03, location=(0, -0.2, 0.02))
    territory = bpy.context.active_object
    territory.parent = root
    mat_yellow = bpy.data.materials.new("M_TerritoryYellow")
    mat_yellow.use_nodes = True
    b_y = mat_yellow.node_tree.nodes['Principled BSDF']
    b_y.inputs['Base Color'].default_value = (0.95, 0.78, 0.12, 1.0)
    b_y.inputs['Roughness'].default_value = 0.15
    if 'Specular IOR Level' in b_y.inputs: b_y.inputs['Specular IOR Level'].default_value = 0.95
    territory.data.materials.append(mat_yellow)

    # Lighting Setup: Warm golden sunlight 50 deg + blue sky fill
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.2
    sun.color = (1.0, 0.96, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), math.radians(20), math.radians(-32))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.8
    fill.color = (0.55, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(10), math.radians(145))

    # Camera
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 42
    cam_obj = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (11.0, -15.5, 9.8)
    target = Vector((0.0, -0.2, 3.4))
    cam_obj.rotation_euler = (target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # Render Settings
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 28
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_dubai_master_render.png"
    scene.render.filepath = out_path

    print("RENDERING DUBAI MASTER...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    build_dubai_palace_master()
