import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

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

def create_baroque_dome(name, radius=1.0, height=1.5, segments=24):
    """Creates a classic European baroque bell-shaped dome / cupola"""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    v_segments = 24
    verts_grid = []

    for v in range(v_segments + 1):
        t = v / v_segments  # 0 at bottom, 1 at top
        z = t * height
        # Baroque bell profile: flares at base, narrows, bulges, then tapers to spire
        if t < 0.2:
            r = radius * (1.1 - 0.25 * (t / 0.2))
        elif t < 0.65:
            # mid bulge
            tm = (t - 0.2) / 0.45
            r = radius * (0.85 + 0.3 * math.sin(tm * math.pi))
        else:
            # upper taper
            tu = (t - 0.65) / 0.35
            r = radius * 0.85 * ((1.0 - tu) ** 1.2)

        row = []
        for u in range(segments):
            phi = u * (2 * math.pi / segments)
            x = r * math.cos(phi)
            y = r * math.sin(phi)
            row.append(bm.verts.new((x, y, z)))
        verts_grid.append(row)

    apex = bm.verts.new((0, 0, height + 0.05))

    for v in range(v_segments - 1):
        for u in range(segments):
            u_next = (u + 1) % segments
            bm.faces.new((verts_grid[v][u], verts_grid[v][u_next], verts_grid[v + 1][u_next], verts_grid[v + 1][u]))

    for u in range(segments):
        u_next = (u + 1) % segments
        bm.faces.new((verts_grid[v_segments - 1][u], verts_grid[v_segments - 1][u_next], apex))

    base_center = bm.verts.new((0, 0, 0))
    for u in range(segments):
        u_next = (u + 1) % segments
        bm.faces.new((base_center, verts_grid[0][u_next], verts_grid[0][u]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    for p in mesh.polygons:
        p.use_smooth = True

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def build_berlin_castle_master():
    reset_scene()

    # Materials matching reference
    mat_white = create_pbr_material("M_WhiteStone", (0.94, 0.92, 0.88, 1.0), roughness=0.45)
    mat_stone_dark = create_pbr_material("M_StonePlinth", (0.75, 0.72, 0.68, 1.0), roughness=0.60)
    mat_roof_red = create_pbr_material("M_MansardRed", (0.78, 0.22, 0.16, 1.0), roughness=0.35, specular=0.6)
    mat_roof_dark = create_pbr_material("M_RoofTrim", (0.60, 0.16, 0.12, 1.0), roughness=0.40)
    mat_gold = create_pbr_material("M_Gold", (1.0, 0.82, 0.22, 1.0), metallic=0.95, roughness=0.18)
    mat_window = create_pbr_material("M_WindowDark", (0.08, 0.12, 0.20, 1.0), roughness=0.15, specular=0.9)

    root = bpy.data.objects.new("BerlinCastleMaster", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Foundation Podium & Steps
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    pod = bpy.context.active_object
    pod.scale = (8.6, 5.4, 0.5)
    pod.parent = root
    pod.data.materials.append(mat_stone_dark)

    # Grand Curved Palace Staircase
    for i, (sw, sl, sz) in enumerate([(4.8, 1.2, 0.18), (4.4, 0.85, 0.35), (4.0, 0.5, 0.52)]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.8 - (2 - i) * 0.28, sz / 2))
        st = bpy.context.active_object
        st.scale = (sw, 0.38, sz)
        st.parent = root
        st.data.materials.append(mat_white)

    # 2. Main Palace Body (Ground floor + Upper floor)
    body_w, body_d, body_h = 7.6, 3.8, 2.8
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.52 + body_h / 2))
    body = bpy.context.active_object
    body.scale = (body_w, body_d, body_h)
    body.parent = root
    body.data.materials.append(mat_white)

    # Horizontal Cornice Moldings (Belts dividing floors and roofline)
    for mz in [0.52 + 1.4, 0.52 + body_h]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, mz))
        cornice = bpy.context.active_object
        cornice.scale = (body_w * 1.03, body_d * 1.03, 0.15)
        cornice.parent = root
        cornice.data.materials.append(mat_stone_dark)

    # Classical Columns & Arched Loggia along Ground Floor Front
    for col_x in [-2.8, -1.9, -1.0, 1.0, 1.9, 2.8]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.14, depth=1.35, location=(col_x, -2.15, 0.52 + 0.68))
        c_col = bpy.context.active_object
        c_col.parent = root
        c_col.data.materials.append(mat_white)

    # Arched Windows across 2nd floor
    for wx in [-3.0, -2.2, -1.4, 1.4, 2.2, 3.0]:
        # Window frame
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -2.12, 0.52 + 2.05))
        w_frame = bpy.context.active_object
        w_frame.scale = (0.55, 0.08, 0.85)
        w_frame.parent = root
        w_frame.data.materials.append(mat_window)

        # Arched window crown
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.28, depth=0.1, location=(wx, -2.12, 0.52 + 2.48))
        w_arch = bpy.context.active_object
        w_arch.rotation_euler = (math.radians(90), 0, 0)
        w_arch.parent = root
        w_arch.data.materials.append(mat_white)

    # Classical Balustrade railing on Roof Edge
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 2.2, -2.12, 0.52 + body_h + 0.18))
        rail = bpy.context.active_object
        rail.scale = (2.8, 0.12, 0.32)
        rail.parent = root
        rail.data.materials.append(mat_white)

    # 3. Rich Red Mansard Roof on Wings
    for side in [-1, 1]:
        rx = side * 2.2
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(rx, -0.2, 0.52 + body_h + 0.75))
        m_roof = bpy.context.active_object
        m_roof.scale = (2.7, body_d * 0.95, 1.4)
        m_roof.parent = root
        m_roof.data.materials.append(mat_roof_red)

        # Dormer windows protruding from red roof
        for dorm_x in [rx - 0.75, rx + 0.75]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(dorm_x, -1.95, 0.52 + body_h + 0.65))
            dorm = bpy.context.active_object
            dorm.scale = (0.45, 0.55, 0.65)
            dorm.parent = root
            dorm.data.materials.append(mat_white)

            bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.35, radius2=0.0, depth=0.45, location=(dorm_x, -1.95, 0.52 + body_h + 1.15))
            d_roof = bpy.context.active_object
            d_roof.rotation_euler = (0, 0, math.radians(45))
            d_roof.parent = root
            d_roof.data.materials.append(mat_roof_dark)

    # 4. Central Grand Tower & Clock Belfry (Rising high above wings)
    tower_w, tower_d = 2.4, 2.2
    tower_base_z = 0.52 + body_h
    # Tier 1: Clock stage
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, tower_base_z + 1.0))
    t_stage1 = bpy.context.active_object
    t_stage1.scale = (tower_w, tower_d, 2.0)
    t_stage1.parent = root
    t_stage1.data.materials.append(mat_white)

    # Gold Clock Face
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.45, depth=0.1, location=(0, -1.52, tower_base_z + 1.15))
    clock = bpy.context.active_object
    clock.rotation_euler = (math.radians(90), 0, 0)
    clock.parent = root
    clock.data.materials.append(mat_gold)

    # Tier 2: Arched Belfry
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, tower_base_z + 2.7))
    t_stage2 = bpy.context.active_object
    t_stage2.scale = (tower_w * 0.85, tower_d * 0.85, 1.4)
    t_stage2.parent = root
    t_stage2.data.materials.append(mat_white)

    # Belfry Arched Opening
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.35, tower_base_z + 2.65))
    belfry_open = bpy.context.active_object
    belfry_open.scale = (0.7, 0.3, 0.95)
    belfry_open.parent = root
    belfry_open.data.materials.append(mat_window)

    # Tier 3: Grand Baroque Red Bell-Cupola
    c_dome = create_baroque_dome("Central_Baroque_Cupola", radius=1.1, height=1.65, segments=24)
    c_dome.location = (0, -0.4, tower_base_z + 3.4)
    c_dome.parent = root
    c_dome.data.materials.append(mat_roof_red)

    # Golden Lantern Pavilion above cupola
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.42, depth=0.6, location=(0, -0.4, tower_base_z + 5.35))
    lantern = bpy.context.active_object
    lantern.parent = root
    lantern.data.materials.append(mat_gold)

    # Golden Spire with German Flag
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.12, radius2=0.0, depth=1.2, location=(0, -0.4, tower_base_z + 6.25))
    spire = bpy.context.active_object
    spire.parent = root
    spire.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.15, location=(0, -0.4, tower_base_z + 6.85))
    spire_orb = bpy.context.active_object
    spire_orb.parent = root
    spire_orb.data.materials.append(mat_gold)

    # Flag Pole and German Flag Banner
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=1.8, location=(0, -0.4, tower_base_z + 7.4))
    flag_pole = bpy.context.active_object
    flag_pole.parent = root
    flag_pole.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.6, -0.4, tower_base_z + 7.7))
    flag_cloth = bpy.context.active_object
    flag_cloth.scale = (1.1, 1.0, 0.65)
    flag_cloth.parent = root
    flag_cloth.data.materials.append(mat_roof_red)

    # 5. Corner Towers with Baroque Red Cupolas & Golden Spires
    for side in [-1, 1]:
        tx = side * 3.8
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.65, depth=body_h + 0.8, location=(tx, -0.2, 0.52 + (body_h + 0.8) / 2))
        c_tower = bpy.context.active_object
        c_tower.parent = root
        c_tower.data.materials.append(mat_white)

        # Tower Cornice
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.75, depth=0.18, location=(tx, -0.2, 0.52 + body_h + 0.85))
        c_corn = bpy.context.active_object
        c_corn.parent = root
        c_corn.data.materials.append(mat_stone_dark)

        # Baroque Dome on Corner Tower
        s_dome = create_baroque_dome(f"CornerDome_{side}", radius=0.68, height=1.05, segments=16)
        s_dome.location = (tx, -0.2, 0.52 + body_h + 0.95)
        s_dome.parent = root
        s_dome.data.materials.append(mat_roof_red)

        # Golden Spire on Corner Tower
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.06, radius2=0.0, depth=0.65, location=(tx, -0.2, 0.52 + body_h + 2.3))
        s_spire = bpy.context.active_object
        s_spire.parent = root
        s_spire.data.materials.append(mat_gold)

    # 6. Lush Pine Trees & Green Lawn Surrounding Berlin Castle
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    pine_path = os.path.join(nature_dir, "tree_pineTallA_detailed.glb")
    if os.path.exists(pine_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=pine_path)
        pine_src = list(set(bpy.data.objects) - before)[0]
        pine_src.location = (1000, 1000, 1000)

        tree_locs = [
            (-5.2, -2.2, 0.0), (-5.8, -0.8, 0.0), (-5.0, 1.0, 0.0),
            (5.2, -2.2, 0.0), (5.8, -0.8, 0.0), (5.0, 1.0, 0.0),
            (-3.8, 2.4, 0.0), (0.0, 2.6, 0.0), (3.8, 2.4, 0.0)
        ]
        for tx, ty, tz in tree_locs:
            clone = pine_src.copy()
            if pine_src.data: clone.data = pine_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (tx, ty, tz)
            clone.scale = (1.3, 1.3, 1.3)
            clone.parent = root

    # Ground Plane with Red Captured Territory Disc (matching reference image!)
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = create_pbr_material("M_Ground", (0.30, 0.60, 0.22, 1.0), roughness=0.65)
    g.data.materials.append(mat_g)

    # Red glossy territory splat around Berlin castle (exactly like reference!)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=5.8, depth=0.03, location=(0, -0.2, 0.02))
    territory = bpy.context.active_object
    territory.parent = root
    mat_red_terr = create_pbr_material("M_RedTerritory", (0.88, 0.15, 0.18, 1.0), roughness=0.18, specular=0.9)
    territory.data.materials.append(mat_red_terr)

    # Lighting Setup (Warm golden sun + blue sky fill)
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
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_berlin_master_render.png"
    scene.render.filepath = out_path

    print("RENDERING BERLIN MASTER...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    build_berlin_castle_master()
