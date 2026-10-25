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

def create_stylized_stone_material():
    mat = bpy.data.materials.new("M_StylizedStone")
    mat.use_nodes = True
    tree = mat.node_tree
    nodes = tree.nodes
    links = tree.links
    nodes.clear()

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-800, 0)

    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-600, 0)
    mapping.inputs["Scale"].default_value = (3.0, 3.0, 3.0)
    links.new(tex_coord.outputs["Object"], mapping.inputs["Vector"])

    # Brick texture for stylized masonry blocks
    brick = nodes.new("ShaderNodeTexBrick")
    brick.location = (-400, 0)
    brick.inputs["Color1"].default_value = (0.94, 0.92, 0.88, 1.0) # Light cream stone
    brick.inputs["Color2"].default_value = (0.86, 0.83, 0.78, 1.0) # Slightly darker stone block
    brick.inputs["Mortar"].default_value = (0.65, 0.62, 0.58, 1.0) # Mortar seam
    brick.inputs["Mortar Size"].default_value = 0.015
    brick.inputs["Mortar Smooth"].default_value = 0.3
    brick.inputs["Bias"].default_value = 0.0
    brick.inputs["Scale"].default_value = 4.0
    brick.inputs["Row Height"].default_value = 0.4
    brick.inputs["Brick Width"].default_value = 0.8
    links.new(mapping.outputs["Vector"], brick.inputs["Vector"])

    # Ambient Occlusion for crevices
    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.location = (-400, -250)
    ao.inputs["Distance"].default_value = 0.5

    # Mix Brick color with AO
    mix = nodes.new("ShaderNodeMix")
    mix.location = (-150, 0)
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs["Factor"].default_value = 0.65
    links.new(brick.outputs["Color"], mix.inputs[6]) # Color1
    links.new(ao.outputs["Color"], mix.inputs[7])    # Color2

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (100, 0)
    bsdf.inputs["Roughness"].default_value = 0.55
    links.new(mix.outputs[2], bsdf.inputs["Base Color"])

    # Subtle bump from mortar
    bump = nodes.new("ShaderNodeBump")
    bump.location = (-150, -250)
    bump.inputs["Strength"].default_value = 0.15
    bump.inputs["Distance"].default_value = 0.05
    links.new(brick.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (350, 0)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat

def create_stylized_roof_material():
    mat = bpy.data.materials.new("M_StylizedRedRoof")
    mat.use_nodes = True
    tree = mat.node_tree
    nodes = tree.nodes
    links = tree.links
    nodes.clear()

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-800, 0)

    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-600, 0)
    mapping.inputs["Scale"].default_value = (5.0, 5.0, 5.0)
    links.new(tex_coord.outputs["Object"], mapping.inputs["Vector"])

    # Brick texture for terracotta scalloped roof shingles
    brick = nodes.new("ShaderNodeTexBrick")
    brick.location = (-400, 0)
    brick.inputs["Color1"].default_value = (0.82, 0.22, 0.15, 1.0) # Vibrant red shingle
    brick.inputs["Color2"].default_value = (0.68, 0.16, 0.10, 1.0) # Darker red shingle
    brick.inputs["Mortar"].default_value = (0.42, 0.08, 0.05, 1.0) # Shadow between shingles
    brick.inputs["Mortar Size"].default_value = 0.02
    brick.inputs["Mortar Smooth"].default_value = 0.2
    brick.inputs["Scale"].default_value = 6.0
    brick.inputs["Row Height"].default_value = 0.35
    brick.inputs["Brick Width"].default_value = 0.6
    links.new(mapping.outputs["Vector"], brick.inputs["Vector"])

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (100, 0)
    bsdf.inputs["Roughness"].default_value = 0.38
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.65
    links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])

    # Bump for shingles
    bump = nodes.new("ShaderNodeBump")
    bump.location = (-150, -250)
    bump.inputs["Strength"].default_value = 0.25
    bump.inputs["Distance"].default_value = 0.04
    links.new(brick.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (350, 0)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat

def create_baroque_dome(name, radius=1.0, height=1.6, segments=24):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    v_segments = 24
    verts_grid = []

    for v in range(v_segments + 1):
        t = v / v_segments
        z = t * height
        if t < 0.2:
            r = radius * (1.12 - 0.26 * (t / 0.2))
        elif t < 0.65:
            tm = (t - 0.2) / 0.45
            r = radius * (0.86 + 0.32 * math.sin(tm * math.pi))
        else:
            tu = (t - 0.65) / 0.35
            r = radius * 0.86 * ((1.0 - tu) ** 1.25)

        row = []
        for u in range(segments):
            phi = u * (2 * math.pi / segments)
            # Add subtle vertical fluting ribs to the baroque dome
            rib = 1.0 + 0.05 * math.cos(segments * phi) * math.sin(t * math.pi)
            x = r * rib * math.cos(phi)
            y = r * rib * math.sin(phi)
            row.append(bm.verts.new((x, y, z)))
        verts_grid.append(row)

    apex = bm.verts.new((0, 0, height + 0.06))

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

def build_showcase_berlin():
    reset_scene()

    mat_stone = create_stylized_stone_material()
    mat_roof = create_stylized_roof_material()

    # PBR materials
    mat_gold = bpy.data.materials.new("M_Gold")
    mat_gold.use_nodes = True
    b_gold = mat_gold.node_tree.nodes['Principled BSDF']
    b_gold.inputs['Base Color'].default_value = (1.0, 0.84, 0.25, 1.0)
    b_gold.inputs['Metallic'].default_value = 0.98
    b_gold.inputs['Roughness'].default_value = 0.16

    mat_win = bpy.data.materials.new("M_WinGlass")
    mat_win.use_nodes = True
    b_win = mat_win.node_tree.nodes['Principled BSDF']
    b_win.inputs['Base Color'].default_value = (0.05, 0.12, 0.24, 1.0)
    b_win.inputs['Roughness'].default_value = 0.12
    if 'Specular IOR Level' in b_win.inputs: b_win.inputs['Specular IOR Level'].default_value = 0.95

    root = bpy.data.objects.new("BerlinShowcase", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Foundation Podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    pod = bpy.context.active_object
    pod.scale = (8.8, 5.6, 0.5)
    pod.parent = root
    pod.data.materials.append(mat_stone)
    apply_bevel(pod, width=0.04)

    # Stepped Grand Staircase
    for i, (sw, sl, sz) in enumerate([(4.8, 1.2, 0.18), (4.4, 0.85, 0.35), (4.0, 0.5, 0.52)]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.9 - (2 - i) * 0.28, sz / 2))
        st = bpy.context.active_object
        st.scale = (sw, 0.38, sz)
        st.parent = root
        st.data.materials.append(mat_stone)
        apply_bevel(st, width=0.02)

    # 2. Main Palace Body
    body_w, body_d, body_h = 7.6, 3.8, 2.8
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.52 + body_h / 2))
    body = bpy.context.active_object
    body.scale = (body_w, body_d, body_h)
    body.parent = root
    body.data.materials.append(mat_stone)
    apply_bevel(body, width=0.04)

    # Horizontal Cornice Moldings
    for mz in [0.52 + 1.4, 0.52 + body_h]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, mz))
        cornice = bpy.context.active_object
        cornice.scale = (body_w * 1.04, body_d * 1.04, 0.16)
        cornice.parent = root
        cornice.data.materials.append(mat_stone)
        apply_bevel(cornice, width=0.03)

    # Classical Columns along Ground Floor
    for col_x in [-2.8, -1.9, -1.0, 1.0, 1.9, 2.8]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.15, depth=1.35, location=(col_x, -2.18, 0.52 + 0.68))
        col = bpy.context.active_object
        col.parent = root
        col.data.materials.append(mat_stone)
        apply_bevel(col, width=0.02)

        # Capital head and base plinth
        for pz in [0.52 + 0.06, 0.52 + 1.32]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(col_x, -2.18, pz))
            cap = bpy.context.active_object
            cap.scale = (0.36, 0.36, 0.12)
            cap.parent = root
            cap.data.materials.append(mat_stone)
            apply_bevel(cap, width=0.02)

    # Arched Windows across 2nd floor with molded frames and mullions
    for wx in [-3.0, -2.2, -1.4, 1.4, 2.2, 3.0]:
        # Recessed window glass
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -2.12, 0.52 + 2.05))
        w_glass = bpy.context.active_object
        w_glass.scale = (0.55, 0.06, 0.85)
        w_glass.parent = root
        w_glass.data.materials.append(mat_win)

        # Molded window frame surround
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -2.16, 0.52 + 2.05))
        w_trim = bpy.context.active_object
        w_trim.scale = (0.65, 0.04, 0.95)
        w_trim.parent = root
        w_trim.data.materials.append(mat_stone)
        apply_bevel(w_trim, width=0.02)

        # Arched window crown
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.32, depth=0.12, location=(wx, -2.15, 0.52 + 2.52))
        w_arch = bpy.context.active_object
        w_arch.rotation_euler = (math.radians(90), 0, 0)
        w_arch.parent = root
        w_arch.data.materials.append(mat_stone)

    # Classical Balustrades along Roofline
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 2.2, -2.15, 0.52 + body_h + 0.20))
        rail = bpy.context.active_object
        rail.scale = (2.8, 0.12, 0.35)
        rail.parent = root
        rail.data.materials.append(mat_stone)
        apply_bevel(rail, width=0.02)

    # 3. Rich Red Mansard Roof on Wings with Dormers
    for side in [-1, 1]:
        rx = side * 2.2
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(rx, -0.2, 0.52 + body_h + 0.8))
        m_roof = bpy.context.active_object
        m_roof.scale = (2.7, body_d * 0.95, 1.5)
        m_roof.parent = root
        m_roof.data.materials.append(mat_roof)
        apply_bevel(m_roof, width=0.04)

        # Dormer windows
        for dorm_x in [rx - 0.75, rx + 0.75]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(dorm_x, -2.0, 0.52 + body_h + 0.7))
            dorm = bpy.context.active_object
            dorm.scale = (0.45, 0.55, 0.7)
            dorm.parent = root
            dorm.data.materials.append(mat_stone)
            apply_bevel(dorm, width=0.02)

            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(dorm_x, -2.28, 0.52 + body_h + 0.7))
            d_win = bpy.context.active_object
            d_win.scale = (0.28, 0.05, 0.45)
            d_win.parent = root
            d_win.data.materials.append(mat_win)

            bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.38, radius2=0.0, depth=0.5, location=(dorm_x, -2.0, 0.52 + body_h + 1.25))
            d_roof = bpy.context.active_object
            d_roof.rotation_euler = (0, 0, math.radians(45))
            d_roof.parent = root
            d_roof.data.materials.append(mat_roof)

    # 4. Central Grand Belfry Clock Tower
    tower_w, tower_d = 2.4, 2.2
    tower_base_z = 0.52 + body_h

    # Clock stage
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, tower_base_z + 1.0))
    t_stage1 = bpy.context.active_object
    t_stage1.scale = (tower_w, tower_d, 2.0)
    t_stage1.parent = root
    t_stage1.data.materials.append(mat_stone)
    apply_bevel(t_stage1, width=0.035)

    # Gold Clock Face with molded bezel
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.52, depth=0.14, location=(0, -1.52, tower_base_z + 1.15))
    clock_rim = bpy.context.active_object
    clock_rim.rotation_euler = (math.radians(90), 0, 0)
    clock_rim.parent = root
    clock_rim.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.45, depth=0.16, location=(0, -1.53, tower_base_z + 1.15))
    clock_face = bpy.context.active_object
    clock_face.rotation_euler = (math.radians(90), 0, 0)
    clock_face.parent = root
    clock_face.data.materials.append(mat_stone)

    # Belfry stage
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, tower_base_z + 2.7))
    t_stage2 = bpy.context.active_object
    t_stage2.scale = (tower_w * 0.85, tower_d * 0.85, 1.4)
    t_stage2.parent = root
    t_stage2.data.materials.append(mat_stone)
    apply_bevel(t_stage2, width=0.03)

    # Belfry Arched Opening
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.35, tower_base_z + 2.65))
    belfry_open = bpy.context.active_object
    belfry_open.scale = (0.75, 0.35, 1.0)
    belfry_open.parent = root
    belfry_open.data.materials.append(mat_win)

    # Grand Baroque Red Bell-Cupola
    c_dome = create_baroque_dome("Central_Baroque_Cupola", radius=1.15, height=1.75, segments=24)
    c_dome.location = (0, -0.4, tower_base_z + 3.4)
    c_dome.parent = root
    c_dome.data.materials.append(mat_roof)

    # Golden Lantern Pavilion above cupola
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.44, depth=0.65, location=(0, -0.4, tower_base_z + 5.45))
    lantern = bpy.context.active_object
    lantern.parent = root
    lantern.data.materials.append(mat_gold)

    # Golden Spire with German Flag
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.12, radius2=0.0, depth=1.3, location=(0, -0.4, tower_base_z + 6.4))
    spire = bpy.context.active_object
    spire.parent = root
    spire.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.16, location=(0, -0.4, tower_base_z + 7.05))
    spire_orb = bpy.context.active_object
    spire_orb.parent = root
    spire_orb.data.materials.append(mat_gold)

    # Flag Pole and German Flag Banner
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=2.0, location=(0, -0.4, tower_base_z + 7.7))
    flag_pole = bpy.context.active_object
    flag_pole.parent = root
    flag_pole.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.65, -0.4, tower_base_z + 8.1))
    flag_cloth = bpy.context.active_object
    flag_cloth.scale = (1.2, 1.0, 0.7)
    flag_cloth.parent = root
    flag_cloth.data.materials.append(mat_roof)

    # 5. Corner Towers with Baroque Domes
    for side in [-1, 1]:
        tx = side * 3.8
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.68, depth=body_h + 0.8, location=(tx, -0.2, 0.52 + (body_h + 0.8) / 2))
        c_tower = bpy.context.active_object
        c_tower.parent = root
        c_tower.data.materials.append(mat_stone)

        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.78, depth=0.2, location=(tx, -0.2, 0.52 + body_h + 0.88))
        c_corn = bpy.context.active_object
        c_corn.parent = root
        c_corn.data.materials.append(mat_stone)
        apply_bevel(c_corn, width=0.025)

        s_dome = create_baroque_dome(f"CornerDome_{side}", radius=0.72, height=1.15, segments=16)
        s_dome.location = (tx, -0.2, 0.52 + body_h + 0.98)
        s_dome.parent = root
        s_dome.data.materials.append(mat_roof)

        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.06, radius2=0.0, depth=0.7, location=(tx, -0.2, 0.52 + body_h + 2.45))
        s_spire = bpy.context.active_object
        s_spire.parent = root
        s_spire.data.materials.append(mat_gold)

    # 6. Pine Trees & Lawn
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

    # Ground Plane with lush emerald grass
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_Lawn")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.62, 0.20, 1.0)
    g.data.materials.append(mat_g)

    # Glossy Red Captured Territory Disc
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=5.8, depth=0.03, location=(0, -0.2, 0.02))
    territory = bpy.context.active_object
    territory.parent = root
    mat_red = bpy.data.materials.new("M_TerritoryRed")
    mat_red.use_nodes = True
    b_red = mat_red.node_tree.nodes['Principled BSDF']
    b_red.inputs['Base Color'].default_value = (0.90, 0.15, 0.18, 1.0)
    b_red.inputs['Roughness'].default_value = 0.15
    if 'Specular IOR Level' in b_red.inputs: b_red.inputs['Specular IOR Level'].default_value = 0.95
    territory.data.materials.append(mat_red)

    # Lighting Setup: Warm golden sunlight 48 deg + sky fill
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
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_berlin_textured_render.png"
    scene.render.filepath = out_path

    print("RENDERING BERLIN TEXTURED...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    build_showcase_berlin()
