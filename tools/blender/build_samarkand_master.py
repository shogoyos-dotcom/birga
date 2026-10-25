import bpy
import bmesh
import math
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

def create_fluted_dome(name, radius=1.0, height=1.6, ribs=24, rib_depth=0.08, u_segments=48, v_segments=36):
    """Creates a classic Samarkand / Gur-e-Amir ribbed melon dome"""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()

    verts_grid = []
    for v in range(v_segments + 1):
        t = v / v_segments
        z = t * height
        if t <= 0.001:
            base_r = radius * 0.95
        elif t < 0.45:
            base_r = radius * (0.95 + 0.22 * math.sin(t / 0.45 * (math.pi / 2)))
        elif t < 0.85:
            tn = max(0.0, min(1.0, (t - 0.45) / 0.40))
            base_r = radius * (1.17 - 0.70 * math.sin(tn * (math.pi / 2)))
        else:
            tn = max(0.0, min(1.0, (t - 0.85) / 0.15))
            base_r = radius * 0.47 * ((1.0 - tn) ** 1.3)

        row = []
        for u in range(u_segments):
            phi = u * (2 * math.pi / u_segments)
            rib_factor = 1.0 + rib_depth * math.cos(ribs * phi) * math.sin(t * math.pi)
            r = base_r * rib_factor
            x = r * math.cos(phi)
            y = r * math.sin(phi)
            row.append(bm.verts.new((x, y, z)))
        verts_grid.append(row)

    apex_vert = bm.verts.new((0, 0, height + 0.05))

    for v in range(v_segments - 1):
        for u in range(u_segments):
            u_next = (u + 1) % u_segments
            bm.faces.new((verts_grid[v][u], verts_grid[v][u_next], verts_grid[v + 1][u_next], verts_grid[v + 1][u]))

    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        bm.faces.new((verts_grid[v_segments - 1][u], verts_grid[v_segments - 1][u_next], apex_vert))

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

def build_pointed_arch_niche(name, width, height, depth, mat_frame, mat_back, mat_inner):
    """Creates a recessed pointed Islamic arch alcove with molded reveal"""
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)

    # Outer Frame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, depth/2, height/2))
    frame = bpy.context.active_object
    frame.scale = (width, depth, height)
    frame.parent = root
    frame.data.materials.append(mat_frame)

    # Recessed Dark Backwall
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, depth * 0.45, height * 0.48))
    back = bpy.context.active_object
    back.scale = (width * 0.72, depth * 0.25, height * 0.82)
    back.parent = root
    back.data.materials.append(mat_back)

    # Arch inner decorative panel (pointed top)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=width * 0.36, depth=depth * 0.2, location=(0, depth * 0.4, height * 0.72))
    arch_top = bpy.context.active_object
    arch_top.rotation_euler = (math.radians(90), 0, 0)
    arch_top.scale = (1.0, 1.3, 1.0)
    arch_top.parent = root
    arch_top.data.materials.append(mat_inner)

    # Flanking decorative colonnettes
    for side in [-1, 1]:
        cx = side * width * 0.42
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=width * 0.05, depth=height * 0.75, location=(cx, depth * 0.1, height * 0.4))
        col = bpy.context.active_object
        col.parent = root
        col.data.materials.append(mat_inner)

    return root

def build_minaret(name, loc, height=6.2, base_radius=0.34, mat_stone=None, mat_tile=None, mat_lapis=None, mat_gold=None):
    root = bpy.data.objects.new(name, None)
    root.location = loc
    bpy.context.scene.collection.objects.link(root)

    # Octagonal Plinth Base
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=base_radius * 1.35, depth=0.8, location=(0, 0, 0.4))
    b = bpy.context.active_object
    b.parent = root
    if mat_stone: b.data.materials.append(mat_stone)

    # Base collar
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=base_radius * 1.15, depth=0.25, location=(0, 0, 0.92))
    b_col = bpy.context.active_object
    b_col.parent = root
    if mat_lapis: b_col.data.materials.append(mat_lapis)

    # Main Tapered Shaft
    shaft_len = height - 2.2
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=base_radius, radius2=base_radius * 0.72, depth=shaft_len, location=(0, 0, 1.05 + shaft_len / 2))
    shaft = bpy.context.active_object
    shaft.parent = root
    if mat_stone: shaft.data.materials.append(mat_stone)

    # Decorative Bands on Shaft
    for z_pct in [0.25, 0.55, 0.85]:
        bz = 1.05 + shaft_len * z_pct
        r_band = base_radius * (1.0 - 0.28 * z_pct) * 1.04
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=r_band, depth=0.24, location=(0, 0, bz))
        band = bpy.context.active_object
        band.parent = root
        if mat_tile: band.data.materials.append(mat_tile)

        # Gold accent rings
        for dz in [-0.14, 0.14]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=r_band * 1.02, depth=0.04, location=(0, 0, bz + dz))
            g_ring = bpy.context.active_object
            g_ring.parent = root
            if mat_gold: g_ring.data.materials.append(mat_gold)

    # Balcony (Muqarnas cornice + railing)
    balc_z = 1.05 + shaft_len
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=base_radius * 0.72, radius2=base_radius * 1.35, depth=0.4, location=(0, 0, balc_z + 0.2))
    corbel = bpy.context.active_object
    corbel.parent = root
    if mat_lapis: corbel.data.materials.append(mat_lapis)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=base_radius * 1.36, depth=0.35, location=(0, 0, balc_z + 0.55))
    rail = bpy.context.active_object
    rail.parent = root
    if mat_stone: rail.data.materials.append(mat_stone)

    # Upper Pavilion Drum with arched window openings
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=base_radius * 0.70, depth=0.75, location=(0, 0, balc_z + 0.75 + 0.35))
    pav = bpy.context.active_object
    pav.parent = root
    if mat_tile: pav.data.materials.append(mat_tile)

    # Conical Spire with Golden Tip
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=base_radius * 0.78, radius2=0.02, depth=1.0, location=(0, 0, balc_z + 1.45 + 0.5))
    spire = bpy.context.active_object
    spire.parent = root
    if mat_tile: spire.data.materials.append(mat_tile)

    # Golden Finial Orb and Crescent
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.12, location=(0, 0, balc_z + 2.5))
    orb = bpy.context.active_object
    orb.parent = root
    if mat_gold: orb.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.03, radius2=0.0, depth=0.32, location=(0, 0, balc_z + 2.7))
    fin_tip = bpy.context.active_object
    fin_tip.parent = root
    if mat_gold: fin_tip.data.materials.append(mat_gold)

    return root

def build_samarkand_palace_master():
    reset_scene()

    # Materials
    mat_sandstone = create_pbr_material("M_Sandstone", (0.86, 0.76, 0.61, 1.0), roughness=0.68)
    mat_stone_dark = create_pbr_material("M_SandstoneDark", (0.68, 0.57, 0.44, 1.0), roughness=0.62)
    mat_turquoise = create_pbr_material("M_TurquoiseTile", (0.05, 0.68, 0.82, 1.0), roughness=0.20, specular=0.85)
    mat_lapis = create_pbr_material("M_LapisBlue", (0.04, 0.16, 0.58, 1.0), roughness=0.28, specular=0.75)
    mat_gold = create_pbr_material("M_Gold", (1.0, 0.82, 0.22, 1.0), metallic=0.95, roughness=0.18)
    mat_recess = create_pbr_material("M_ArchRecess", (0.02, 0.08, 0.22, 1.0), roughness=0.50)

    root = bpy.data.objects.new("SamarkandPalaceMaster", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Multi-Tier Foundation Podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    pod1 = bpy.context.active_object
    pod1.scale = (8.4, 5.2, 0.5)
    pod1.parent = root
    pod1.data.materials.append(mat_stone_dark)

    # Molded stone top lip of podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.52))
    pod_lip = bpy.context.active_object
    pod_lip.scale = (8.6, 5.4, 0.08)
    pod_lip.parent = root
    pod_lip.data.materials.append(mat_sandstone)

    # Grand Staircase (Stepped approach)
    for i, (sw, sl, sz) in enumerate([(4.6, 1.2, 0.18), (4.2, 0.85, 0.35), (3.8, 0.5, 0.52)]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.7 - (2 - i) * 0.28, sz / 2))
        st = bpy.context.active_object
        st.scale = (sw, 0.38, sz)
        st.parent = root
        st.data.materials.append(mat_sandstone)

    # 2. Central High Pishtaq (Grand Monumental Portal)
    portal_w, portal_d, portal_h = 3.4, 1.6, 5.0
    # Portal Main Masonry Block
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.55 + portal_h / 2))
    p_body = bpy.context.active_object
    p_body.scale = (portal_w, portal_d, portal_h)
    p_body.parent = root
    p_body.data.materials.append(mat_sandstone)

    # Lapis Blue Calligraphic / Mosaic Border Framing
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.02, 0.55 + portal_h / 2))
    p_border = bpy.context.active_object
    p_border.scale = (portal_w * 1.02, 0.06, portal_h * 1.02)
    p_border.parent = root
    p_border.data.materials.append(mat_lapis)

    # Inner Golden Filigree Band
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.04, 0.55 + portal_h / 2))
    p_gold_band = bpy.context.active_object
    p_gold_band.scale = (portal_w * 0.94, 0.04, portal_h * 0.94)
    p_gold_band.parent = root
    p_gold_band.data.materials.append(mat_gold)

    # Recessed Vaulted Iwan Alcove
    iwan_w, iwan_h, iwan_d = 2.1, 3.8, 1.2
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.65, 0.55 + iwan_h / 2 + 0.2))
    iwan_alcove = bpy.context.active_object
    iwan_alcove.scale = (iwan_w, iwan_d, iwan_h)
    iwan_alcove.parent = root
    iwan_alcove.data.materials.append(mat_turquoise)

    # Pointed arch crown inside Iwan vault
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=iwan_w * 0.5, depth=iwan_d * 1.02, location=(0, -0.65, 0.55 + iwan_h - 0.2))
    iwan_vault = bpy.context.active_object
    iwan_vault.rotation_euler = (math.radians(90), 0, 0)
    iwan_vault.scale = (1.0, 1.35, 1.0)
    iwan_vault.parent = root
    iwan_vault.data.materials.append(mat_lapis)

    # Deep Portal Entrance Doorway
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.85, 0.55 + 1.1))
    door = bpy.context.active_object
    door.scale = (1.1, 0.8, 2.2)
    door.parent = root
    door.data.materials.append(mat_recess)

    # Ornamental Muqarnas / Stalactite Band above door
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.82, 0.55 + 2.35))
    muqarnas_band = bpy.context.active_object
    muqarnas_band.scale = (1.6, 0.6, 0.35)
    muqarnas_band.parent = root
    muqarnas_band.data.materials.append(mat_gold)

    # Pishtaq Cresting Parapet
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.55 + portal_h + 0.16))
    crest = bpy.context.active_object
    crest.scale = (portal_w * 1.04, portal_d * 1.04, 0.32)
    crest.parent = root
    crest.data.materials.append(mat_lapis)

    # 3. Central Grand Fluted Ribbed Melon Dome (Gur-e-Amir Style)
    drum_z = 0.55 + portal_h + 0.55
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.45, depth=1.1, location=(0, 0.35, drum_z))
    drum = bpy.context.active_object
    drum.parent = root
    drum.data.materials.append(mat_lapis)

    # Drum Decorative Gold Calligraphy Band
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.52, depth=0.28, location=(0, 0.35, drum_z - 0.28))
    drum_gold = bpy.context.active_object
    drum_gold.parent = root
    drum_gold.data.materials.append(mat_gold)

    # Fluted Dome
    dome = create_fluted_dome("Samarkand_Main_Dome", radius=1.48, height=2.1, ribs=24, rib_depth=0.09)
    dome.location = (0, 0.35, drum_z + 0.55)
    dome.parent = root
    dome.data.materials.append(mat_turquoise)

    # Finial Base & Golden Orb
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.22, depth=0.35, location=(0, 0.35, drum_z + 2.7))
    fin_base = bpy.context.active_object
    fin_base.parent = root
    fin_base.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.25, location=(0, 0.35, drum_z + 2.95))
    fin_orb = bpy.context.active_object
    fin_orb.parent = root
    fin_orb.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.09, radius2=0.0, depth=0.75, location=(0, 0.35, drum_z + 3.4))
    fin_spire = bpy.context.active_object
    fin_spire.parent = root
    fin_spire.data.materials.append(mat_gold)

    # 4. Symmetrical Side Gallery Wings (Left & Right)
    wing_w, wing_d, wing_h = 2.1, 1.4, 3.4
    for side in [-1, 1]:
        wx = side * (portal_w / 2 + wing_w / 2)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.2, 0.55 + wing_h / 2))
        wing = bpy.context.active_object
        wing.scale = (wing_w, wing_d, wing_h)
        wing.parent = root
        wing.data.materials.append(mat_sandstone)

        # 2 Tiers of Arched Niches on Wing Facades
        for tier_idx, tz in enumerate([0.55 + 0.85, 0.55 + 2.35]):
            for col_x in [-0.5, 0.5]:
                niche = build_pointed_arch_niche(f"WingNiche_{side}_{tier_idx}_{col_x}",
                                                width=0.75, height=1.1, depth=0.25,
                                                mat_frame=mat_sandstone,
                                                mat_back=mat_recess,
                                                mat_inner=mat_turquoise)
                niche.location = (wx + col_x, -0.92, tz - 0.55)
                niche.parent = root

        # Wing Roof Parapet / Cresting
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.2, 0.55 + wing_h + 0.14))
        w_crest = bpy.context.active_object
        w_crest.scale = (wing_w * 1.05, wing_d * 1.05, 0.28)
        w_crest.parent = root
        w_crest.data.materials.append(mat_lapis)

        # Fluted Secondary Dome on Each Wing
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.72, depth=0.55, location=(wx, 0.0, 0.55 + wing_h + 0.55))
        s_drum = bpy.context.active_object
        s_drum.parent = root
        s_drum.data.materials.append(mat_lapis)

        s_dome = create_fluted_dome(f"SideDome_{side}", radius=0.72, height=1.1, ribs=16, rib_depth=0.08)
        s_dome.location = (wx, 0.0, 0.55 + wing_h + 0.82)
        s_dome.parent = root
        s_dome.data.materials.append(mat_turquoise)

        # Golden Spire on Side Dome
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.12, location=(wx, 0.0, 0.55 + wing_h + 1.95))
        s_orb = bpy.context.active_object
        s_orb.parent = root
        s_orb.data.materials.append(mat_gold)

        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.05, radius2=0.0, depth=0.5, location=(wx, 0.0, 0.55 + wing_h + 2.25))
        s_fin = bpy.context.active_object
        s_fin.parent = root
        s_fin.data.materials.append(mat_gold)

    # 5. Four Slender Tower Minarets (Matching Registan!)
    # Portal flanking minarets
    min_flank_l = build_minaret("Minaret_Portal_L", (-2.0, -1.0, 0.55), height=5.8, base_radius=0.30, mat_stone=mat_sandstone, mat_tile=mat_turquoise, mat_lapis=mat_lapis, mat_gold=mat_gold)
    min_flank_l.parent = root

    min_flank_r = build_minaret("Minaret_Portal_R", (2.0, -1.0, 0.55), height=5.8, base_radius=0.30, mat_stone=mat_sandstone, mat_tile=mat_turquoise, mat_lapis=mat_lapis, mat_gold=mat_gold)
    min_flank_r.parent = root

    # Outer corner minarets (taller and more prominent)
    min_corner_l = build_minaret("Minaret_Corner_L", (-4.0, -0.95, 0.55), height=6.8, base_radius=0.36, mat_stone=mat_sandstone, mat_tile=mat_turquoise, mat_lapis=mat_lapis, mat_gold=mat_gold)
    min_corner_l.parent = root

    min_corner_r = build_minaret("Minaret_Corner_R", (4.0, -0.95, 0.55), height=6.8, base_radius=0.36, mat_stone=mat_sandstone, mat_tile=mat_turquoise, mat_lapis=mat_lapis, mat_gold=mat_gold)
    min_corner_r.parent = root

    # 6. Flag Banner on Grand Portal
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.03, depth=2.4, location=(0, -0.9, 0.55 + portal_h + 1.2))
    fp = bpy.context.active_object
    fp.parent = root
    fp.data.materials.append(mat_gold)

    # Uzbekistan Flag cloth
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.6, -0.9, 0.55 + portal_h + 1.8))
    flag = bpy.context.active_object
    flag.scale = (1.1, 1.0, 0.65)
    flag.parent = root
    flag.data.materials.append(mat_turquoise)

    # Ground Plane
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = create_pbr_material("M_Ground", (0.30, 0.60, 0.22, 1.0), roughness=0.65)
    g.data.materials.append(mat_g)

    # Pine Trees around the palace base (just like reference image!)
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    pine_path = os.path.join(nature_dir, "tree_pineTallA_detailed.glb")
    if os.path.exists(pine_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=pine_path)
        pine_src = list(set(bpy.data.objects) - before)[0]
        pine_src.location = (1000, 1000, 1000)

        tree_locs = [
            (-5.2, -1.8, 0.0), (-5.6, -0.5, 0.0), (-4.8, 1.2, 0.0),
            (5.2, -1.8, 0.0), (5.6, -0.5, 0.0), (4.8, 1.2, 0.0),
            (-3.5, 2.5, 0.0), (0.0, 2.8, 0.0), (3.5, 2.5, 0.0)
        ]
        for tx, ty, tz in tree_locs:
            clone = pine_src.copy()
            if pine_src.data: clone.data = pine_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (tx, ty, tz)
            clone.scale = (1.3, 1.3, 1.3)
            clone.parent = root

    # Lighting Setup (Matching reference: warm golden sun 48 deg + sky fill)
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

    # Camera Angle (Framed beautifully to show the entire palace and spires)
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 42
    cam_obj = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (11.0, -15.5, 9.8)
    target = Vector((0.0, -0.2, 3.2))
    cam_obj.rotation_euler = (target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # Render Settings
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 28
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_samarkand_master_render.png"
    scene.render.filepath = out_path

    print("RENDERING SAMARKAND MASTER...")
    bpy.ops.render.render(write_still=True)
    print("FINISHED:", out_path)

if __name__ == "__main__":
    import os
    build_samarkand_palace_master()
