import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, base_color, metallic=0.0, roughness=0.5, specular=0.5):
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

def create_fluted_dome(name, radius=1.0, height=1.6, ribs=24, rib_depth=0.07, u_segments=48, v_segments=36):
    """Creates a classic Samarkand / Gur-e-Amir ribbed melon dome"""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()

    # Parametric profile of onion dome
    verts_grid = []
    for v in range(v_segments + 1):
        t = v / v_segments  # 0 at bottom, 1 at top
        z = t * height
        # Onion dome profile curve
        if t <= 0.001:
            base_r = radius * 0.95
        elif t < 0.45:
            # lower bulge
            base_r = radius * (0.95 + 0.22 * math.sin(t / 0.45 * (math.pi / 2)))
        elif t < 0.85:
            # necking inwards
            tn = max(0.0, min(1.0, (t - 0.45) / 0.40))
            base_r = radius * (1.17 - 0.70 * math.sin(tn * (math.pi / 2)))
        else:
            # pointed spire tip
            tn = max(0.0, min(1.0, (t - 0.85) / 0.15))
            base_r = radius * 0.47 * ((1.0 - tn) ** 1.3)

        row = []
        for u in range(u_segments):
            phi = u * (2 * math.pi / u_segments)
            # Rib scallop modulation (fluting)
            rib_factor = 1.0 + rib_depth * math.cos(ribs * phi) * math.sin(t * math.pi)
            r = base_r * rib_factor
            x = r * math.cos(phi)
            y = r * math.sin(phi)
            vert = bm.verts.new((x, y, z))
            row.append(vert)
        verts_grid.append(row)

    # Top apex vertex
    apex_vert = bm.verts.new((0, 0, height + 0.05))

    # Faces
    for v in range(v_segments - 1):
        for u in range(u_segments):
            u_next = (u + 1) % u_segments
            v0 = verts_grid[v][u]
            v1 = verts_grid[v][u_next]
            v2 = verts_grid[v + 1][u_next]
            v3 = verts_grid[v + 1][u]
            bm.faces.new((v0, v1, v2, v3))

    # Connect top row to apex
    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        v0 = verts_grid[v_segments - 1][u]
        v1 = verts_grid[v_segments - 1][u_next]
        bm.faces.new((v0, v1, apex_vert))

    # Bottom cap (if needed)
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

def build_minaret(name, loc, height=6.0, base_radius=0.35, mat_stone=None, mat_tile=None, mat_gold=None):
    """Builds an elegant oriental minaret with balcony and golden finial"""
    root = bpy.data.objects.new(name, None)
    root.location = loc
    bpy.context.scene.collection.objects.link(root)

    # Octagonal Plinth Base
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=base_radius * 1.35, depth=0.8, location=(0, 0, 0.4))
    b = bpy.context.active_object
    b.parent = root
    if mat_stone: b.data.materials.append(mat_stone)

    # Molded base collar
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=base_radius * 1.15, depth=0.25, location=(0, 0, 0.92))
    b_col = bpy.context.active_object
    b_col.parent = root
    if mat_tile: b_col.data.materials.append(mat_tile)

    # Main Tapered Shaft
    shaft_len = height - 2.2
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=base_radius, radius2=base_radius * 0.72, depth=shaft_len, location=(0, 0, 1.05 + shaft_len / 2))
    shaft = bpy.context.active_object
    shaft.parent = root
    if mat_stone: shaft.data.materials.append(mat_stone)

    # Decorative Blue Geometric Bands on Shaft
    for z_pct in [0.25, 0.55, 0.85]:
        bz = 1.05 + shaft_len * z_pct
        r_band = base_radius * (1.0 - 0.28 * z_pct) * 1.03
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=r_band, depth=0.22, location=(0, 0, bz))
        band = bpy.context.active_object
        band.parent = root
        if mat_tile: band.data.materials.append(mat_tile)

    # Balcony (Muqarnas cornice + railing)
    balc_z = 1.05 + shaft_len
    # Corbel flare
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=base_radius * 0.72, radius2=base_radius * 1.3, depth=0.35, location=(0, 0, balc_z + 0.17))
    corbel = bpy.context.active_object
    corbel.parent = root
    if mat_tile: corbel.data.materials.append(mat_tile)

    # Railing
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=base_radius * 1.32, depth=0.32, location=(0, 0, balc_z + 0.50))
    rail = bpy.context.active_object
    rail.parent = root
    if mat_stone: rail.data.materials.append(mat_stone)

    # Upper Pavilion Drum
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=base_radius * 0.65, depth=0.65, location=(0, 0, balc_z + 0.65 + 0.32))
    pav = bpy.context.active_object
    pav.parent = root
    if mat_tile: pav.data.materials.append(mat_tile)

    # Conical Spire with Golden Tip
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=base_radius * 0.75, radius2=0.02, depth=0.9, location=(0, 0, balc_z + 1.30 + 0.45))
    spire = bpy.context.active_object
    spire.parent = root
    if mat_tile: spire.data.materials.append(mat_tile)

    # Golden Finial Orb and Crescent
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.10, location=(0, 0, balc_z + 2.22))
    orb = bpy.context.active_object
    orb.parent = root
    if mat_gold: orb.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.03, radius2=0.0, depth=0.25, location=(0, 0, balc_z + 2.38))
    fin_tip = bpy.context.active_object
    fin_tip.parent = root
    if mat_gold: fin_tip.data.materials.append(mat_gold)

    return root

def build_pointed_arch_mesh(name, width, height, depth, wall_thickness=0.25):
    """Creates a classic Persian/Timurid pointed arch portal frame"""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()

    half_w = width / 2
    r = half_w
    steps = 14
    pts = []
    # Left vertical
    pts.append(Vector((-half_w, 0, 0)))
    spring_z = height - half_w * 0.95
    pts.append(Vector((-half_w, 0, spring_z)))

    # Pointed arch curve (two intersecting circles)
    c_right = Vector((half_w * 0.35, 0, spring_z))
    r_curve = half_w * 1.35
    for i in range(steps + 1):
        t = i / steps
        ang = math.pi - t * (math.pi / 2.3)
        px = c_right.x + r_curve * math.cos(ang)
        pz = c_right.y + r_curve * math.sin(ang)
        if px >= 0:
            pts.append(Vector((0, 0, pz)))
            break
        pts.append(Vector((px, 0, pz)))

    # Mirror for right side
    right_pts = []
    for p in reversed(pts[:-1]):
        right_pts.append(Vector((-p.x, 0, p.z)))
    arch_inner_profile = pts + right_pts

    # Outer rectangle
    outer_w = half_w + wall_thickness
    outer_h = height + wall_thickness
    outer_pts = [
        Vector((-outer_w, 0, 0)),
        Vector((-outer_w, 0, outer_h)),
        Vector((outer_w, 0, outer_h)),
        Vector((outer_w, 0, 0))
    ]

    # Create front face
    v_in = [bm.verts.new(p) for p in arch_inner_profile]
    v_out = [bm.verts.new(p) for p in outer_pts]

    # Extrude both to depth
    geom = list(v_in) + list(v_out)
    res = bmesh.ops.extrude_vert_indiv(bm, verts=geom)
    d_vec = Vector((0, depth, 0))
    for v in res['verts']:
        v.co += d_vec

    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def assemble_samarkand_palace():
    reset_scene()

    # Materials
    mat_stone = create_material("M_Sandstone", (0.88, 0.78, 0.64, 1.0), roughness=0.68)
    mat_stone_dark = create_material("M_SandstoneTrim", (0.76, 0.65, 0.51, 1.0), roughness=0.62)
    mat_tile = create_material("M_TurquoiseTile", (0.05, 0.68, 0.84, 1.0), roughness=0.22, specular=0.85)
    mat_lapis = create_material("M_LapisBlue", (0.04, 0.16, 0.58, 1.0), roughness=0.30, specular=0.75)
    mat_gold = create_material("M_Gold", (1.0, 0.82, 0.22, 1.0), metallic=0.95, roughness=0.18)
    mat_white = create_material("M_WhiteMarble", (0.95, 0.94, 0.90, 1.0), roughness=0.35)

    root = bpy.data.objects.new("SamarkandPalace", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Main Foundation Terrace (Multi-tier stone podium)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    pod = bpy.context.active_object
    pod.scale = (7.5, 5.0, 0.5)
    pod.parent = root
    pod.data.materials.append(mat_stone_dark)

    # Front Staircase
    for i, (sw, sl, sz) in enumerate([(4.0, 1.0, 0.16), (3.6, 0.7, 0.32), (3.2, 0.4, 0.48)]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.6 - (2 - i) * 0.25, sz / 2))
        st = bpy.context.active_object
        st.scale = (sw, 0.35, sz)
        st.parent = root
        st.data.materials.append(mat_stone)

    # 2. Central High Pishtaq (Grand Portal)
    portal_w, portal_d, portal_h = 3.2, 1.4, 4.8
    # Outer Portal Block
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.5 + portal_h / 2))
    p_body = bpy.context.active_object
    p_body.scale = (portal_w, portal_d, portal_h)
    p_body.parent = root
    p_body.data.materials.append(mat_stone)

    # Portal Front Decorative Border (Lapis blue framing)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.92, 0.5 + portal_h / 2))
    p_trim = bpy.context.active_object
    p_trim.scale = (portal_w * 1.03, 0.08, portal_h * 1.02)
    p_trim.parent = root
    p_trim.data.materials.append(mat_lapis)

    # Inset Grand Vaulted Iwan Niches (Deep recessed arched alcove)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.65, 0.5 + 2.1))
    iwan_alcove = bpy.context.active_object
    iwan_alcove.scale = (1.9, 1.0, 3.4)
    iwan_alcove.parent = root
    iwan_alcove.data.materials.append(mat_tile)

    # Inner arched doorway
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.7, 0.5 + 0.9))
    inner_door = bpy.context.active_object
    inner_door.scale = (0.9, 0.95, 1.8)
    inner_door.parent = root
    inner_door.data.materials.append(mat_stone_dark)

    # 3. Central Grand Fluted Ribbed Melon Dome
    # Drum cylinder with tile band
    drum_z = 0.5 + portal_h + 0.45
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.35, depth=0.9, location=(0, 0.3, drum_z))
    drum = bpy.context.active_object
    drum.parent = root
    drum.data.materials.append(mat_lapis)

    # Decorative frieze band around drum
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.42, depth=0.22, location=(0, 0.3, drum_z - 0.25))
    drum_band = bpy.context.active_object
    drum_band.parent = root
    drum_band.data.materials.append(mat_gold)

    # Fluted Dome itself
    dome = create_fluted_dome("Samarkand_Main_Dome", radius=1.38, height=1.9, ribs=24, rib_depth=0.08)
    dome.location = (0, 0.3, drum_z + 0.45)
    dome.parent = root
    dome.data.materials.append(mat_tile)

    # Golden Finial on Central Dome
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.22, location=(0, 0.3, drum_z + 2.45))
    fin_sphere = bpy.context.active_object
    fin_sphere.parent = root
    fin_sphere.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.08, radius2=0.0, depth=0.6, location=(0, 0.3, drum_z + 2.8))
    fin_cone = bpy.context.active_object
    fin_cone.parent = root
    fin_cone.data.materials.append(mat_gold)

    # 4. Side Gallery Wings (Left & Right)
    wing_w, wing_d, wing_h = 1.9, 1.2, 3.2
    for side in [-1, 1]:
        wx = side * (portal_w / 2 + wing_w / 2)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.2, 0.5 + wing_h / 2))
        wing = bpy.context.active_object
        wing.scale = (wing_w, wing_d, wing_h)
        wing.parent = root
        wing.data.materials.append(mat_stone)

        # 2 Tiers of Arched Niches on Wing Facade
        for tier, tz in enumerate([0.5 + 0.8, 0.5 + 2.2]):
            for col in [-0.45, 0.45]:
                # Niche recess
                bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx + col, -0.82, tz))
                niche = bpy.context.active_object
                niche.scale = (0.55, 0.15, 0.95)
                niche.parent = root
                niche.data.materials.append(mat_tile)

        # Wing Roof Parapet / Cresting
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.2, 0.5 + wing_h + 0.12))
        parapet = bpy.context.active_object
        parapet.scale = (wing_w * 1.05, wing_d * 1.05, 0.24)
        parapet.parent = root
        parapet.data.materials.append(mat_lapis)

        # Fluted corner secondary dome on each wing
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.65, depth=0.45, location=(wx, 0.0, 0.5 + wing_h + 0.45))
        s_drum = bpy.context.active_object
        s_drum.parent = root
        s_drum.data.materials.append(mat_lapis)

        s_dome = create_fluted_dome(f"SideDome_{side}", radius=0.65, height=0.95, ribs=16, rib_depth=0.07)
        s_dome.location = (wx, 0.0, 0.5 + wing_h + 0.67)
        s_dome.parent = root
        s_dome.data.materials.append(mat_tile)

        # Golden Spire on side dome
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.05, radius2=0.0, depth=0.4, location=(wx, 0.0, 0.5 + wing_h + 1.8))
        s_fin = bpy.context.active_object
        s_fin.parent = root
        s_fin.data.materials.append(mat_gold)

    # 5. Four Elegant Minarets
    # 2 Flanking Portal
    min_flank_1 = build_minaret("Minaret_Front_L", (-1.85, -0.9, 0.5), height=5.6, base_radius=0.30, mat_stone=mat_stone, mat_tile=mat_tile, mat_gold=mat_gold)
    min_flank_1.parent = root
    min_flank_2 = build_minaret("Minaret_Front_R", (1.85, -0.9, 0.5), height=5.6, base_radius=0.30, mat_stone=mat_stone, mat_tile=mat_tile, mat_gold=mat_gold)
    min_flank_2.parent = root

    # 2 Outer Wing Corners
    min_outer_1 = build_minaret("Minaret_Outer_L", (-3.65, -0.85, 0.5), height=6.4, base_radius=0.34, mat_stone=mat_stone, mat_tile=mat_tile, mat_gold=mat_gold)
    min_outer_1.parent = root
    min_outer_2 = build_minaret("Minaret_Outer_R", (3.65, -0.85, 0.5), height=6.4, base_radius=0.34, mat_stone=mat_stone, mat_tile=mat_tile, mat_gold=mat_gold)
    min_outer_2.parent = root

    # 6. Flag pole with Uzbek Star/Crescent banner
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=2.0, location=(0, -0.8, 0.5 + portal_h + 1.0))
    fp = bpy.context.active_object
    fp.parent = root
    fp.data.materials.append(mat_gold)

    # Render Setup
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_samarkand_pro_render.png"
    scene.render.filepath = out_path

    # Ground Plane
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = create_material("M_Ground", (0.32, 0.65, 0.25, 1.0), roughness=0.6)
    g.data.materials.append(mat_g)

    # Lighting (Sun & Fill to match reference)
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 5.0
    sun.color = (1.0, 0.96, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), math.radians(18), math.radians(-32))

    fill = bpy.data.lights.new("Fill", 'SUN')
    fill.energy = 1.8
    fill.color = (0.6, 0.85, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(10), math.radians(140))

    # Camera
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 52
    cam_obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (8.0, -11.0, 7.5)
    target = Vector((0.0, -0.2, 2.6))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    print("RENDERING SAMARKAND PRO...")
    bpy.ops.render.render(write_still=True)
    print("RENDER_COMPLETE:", out_path)

if __name__ == "__main__":
    assemble_samarkand_palace()
