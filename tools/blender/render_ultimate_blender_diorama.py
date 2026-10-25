import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, noise

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

def load_glb(fpath):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=fpath)
    new_objs = list(set(bpy.data.objects) - before)
    top_objs = [o for o in new_objs if o.parent is None]
    if len(top_objs) == 1:
        return top_objs[0]
    grp = bpy.data.objects.new("Group", None)
    bpy.context.scene.collection.objects.link(grp)
    for o in top_objs:
        o.parent = grp
    return grp

def duplicate_obj(src, new_parent=None):
    obj_map = {}
    def copy_rec(o):
        clone = o.copy()
        if o.data:
            clone.data = o.data.copy()
        bpy.context.scene.collection.objects.link(clone)
        obj_map[o] = clone
        for ch in o.children:
            ch_c = copy_rec(ch)
            ch_c.parent = clone
        return clone
    top_clone = copy_rec(src)
    if new_parent:
        top_clone.parent = new_parent
    return top_clone

# ----------------- MATERIALS -----------------
def create_materials():
    mats = {}

    # Grass
    mat_grass = bpy.data.materials.new("M_LushGrass")
    mat_grass.use_nodes = True
    b_g = mat_grass.node_tree.nodes['Principled BSDF']
    b_g.inputs['Base Color'].default_value = (0.28, 0.64, 0.20, 1.0)
    b_g.inputs['Roughness'].default_value = 0.65
    mats['grass'] = mat_grass

    # Sand
    mat_sand = bpy.data.materials.new("M_GoldenSand")
    mat_sand.use_nodes = True
    b_s = mat_sand.node_tree.nodes['Principled BSDF']
    b_s.inputs['Base Color'].default_value = (0.86, 0.76, 0.52, 1.0)
    b_s.inputs['Roughness'].default_value = 0.75
    mats['sand'] = mat_sand

    # Turquoise Water
    mat_water = bpy.data.materials.new("M_TurquoiseWater")
    mat_water.use_nodes = True
    b_w = mat_water.node_tree.nodes['Principled BSDF']
    b_w.inputs['Base Color'].default_value = (0.12, 0.82, 0.84, 1.0)
    b_w.inputs['Roughness'].default_value = 0.05
    if 'Transmission Weight' in b_w.inputs:
        b_w.inputs['Transmission Weight'].default_value = 0.85
    elif 'Transmission' in b_w.inputs:
        b_w.inputs['Transmission'].default_value = 0.85
    if 'IOR' in b_w.inputs:
        b_w.inputs['IOR'].default_value = 1.333
    mats['water'] = mat_water

    # Foam
    mat_foam = bpy.data.materials.new("M_WaterFoam")
    mat_foam.use_nodes = True
    b_f = mat_foam.node_tree.nodes['Principled BSDF']
    b_f.inputs['Base Color'].default_value = (0.95, 0.98, 1.0, 1.0)
    b_f.inputs['Roughness'].default_value = 0.25
    mats['foam'] = mat_foam

    # Alpine Rock
    mat_rock = bpy.data.materials.new("M_ChiseledRock")
    mat_rock.use_nodes = True
    b_r = mat_rock.node_tree.nodes['Principled BSDF']
    b_r.inputs['Base Color'].default_value = (0.52, 0.50, 0.46, 1.0)
    b_r.inputs['Roughness'].default_value = 0.85
    mats['rock'] = mat_rock

    # Sandstone
    mat_stone = bpy.data.materials.new("M_Sandstone")
    mat_stone.use_nodes = True
    b_st = mat_stone.node_tree.nodes['Principled BSDF']
    b_st.inputs['Base Color'].default_value = (0.88, 0.80, 0.65, 1.0)
    b_st.inputs['Roughness'].default_value = 0.55
    mats['sandstone'] = mat_stone

    # White Marble
    mat_marble = bpy.data.materials.new("M_WhiteMarble")
    mat_marble.use_nodes = True
    b_m = mat_marble.node_tree.nodes['Principled BSDF']
    b_m.inputs['Base Color'].default_value = (0.95, 0.94, 0.90, 1.0)
    b_m.inputs['Roughness'].default_value = 0.28
    mats['marble'] = mat_marble

    # Ceramic Turquoise Dome
    mat_turq = bpy.data.materials.new("M_CeramicTurquoise")
    mat_turq.use_nodes = True
    b_tq = mat_turq.node_tree.nodes['Principled BSDF']
    b_tq.inputs['Base Color'].default_value = (0.04, 0.68, 0.82, 1.0)
    b_tq.inputs['Roughness'].default_value = 0.18
    if 'Specular IOR Level' in b_tq.inputs: b_tq.inputs['Specular IOR Level'].default_value = 0.9
    mats['turq_dome'] = mat_turq

    # Lapis Blue
    mat_lapis = bpy.data.materials.new("M_LapisBlue")
    mat_lapis.use_nodes = True
    b_l = mat_lapis.node_tree.nodes['Principled BSDF']
    b_l.inputs['Base Color'].default_value = (0.04, 0.16, 0.60, 1.0)
    b_l.inputs['Roughness'].default_value = 0.25
    mats['lapis'] = mat_lapis

    # Luxury Gold
    mat_gold = bpy.data.materials.new("M_Gold")
    mat_gold.use_nodes = True
    b_gld = mat_gold.node_tree.nodes['Principled BSDF']
    b_gld.inputs['Base Color'].default_value = (1.0, 0.84, 0.24, 1.0)
    b_gld.inputs['Metallic'].default_value = 0.98
    b_gld.inputs['Roughness'].default_value = 0.15
    mats['gold'] = mat_gold

    # Red Mansard Roof
    mat_red = bpy.data.materials.new("M_RedRoof")
    mat_red.use_nodes = True
    b_rd = mat_red.node_tree.nodes['Principled BSDF']
    b_rd.inputs['Base Color'].default_value = (0.80, 0.20, 0.14, 1.0)
    b_rd.inputs['Roughness'].default_value = 0.35
    mats['red_roof'] = mat_red

    # Territory Red
    mat_tred = bpy.data.materials.new("M_TerritoryRed")
    mat_tred.use_nodes = True
    b_tr = mat_tred.node_tree.nodes['Principled BSDF']
    b_tr.inputs['Base Color'].default_value = (0.92, 0.14, 0.18, 1.0)
    b_tr.inputs['Roughness'].default_value = 0.12
    if 'Specular IOR Level' in b_tr.inputs: b_tr.inputs['Specular IOR Level'].default_value = 0.95
    mats['terr_red'] = mat_tred

    # Territory Yellow
    mat_tyel = bpy.data.materials.new("M_TerritoryYellow")
    mat_tyel.use_nodes = True
    b_ty = mat_tyel.node_tree.nodes['Principled BSDF']
    b_ty.inputs['Base Color'].default_value = (0.96, 0.80, 0.10, 1.0)
    b_ty.inputs['Roughness'].default_value = 0.12
    if 'Specular IOR Level' in b_ty.inputs: b_ty.inputs['Specular IOR Level'].default_value = 0.95
    mats['terr_yellow'] = mat_tyel

    # Caterpillar Red
    mat_cat = bpy.data.materials.new("M_PlayerCaterpillar")
    mat_cat.use_nodes = True
    b_c = mat_cat.node_tree.nodes['Principled BSDF']
    b_c.inputs['Base Color'].default_value = (0.98, 0.18, 0.22, 1.0)
    b_c.inputs['Roughness'].default_value = 0.08
    if 'Specular IOR Level' in b_c.inputs: b_c.inputs['Specular IOR Level'].default_value = 1.0
    mats['caterpillar'] = mat_cat

    # Dark Glass
    mat_gl = bpy.data.materials.new("M_DarkGlass")
    mat_gl.use_nodes = True
    b_gl = mat_gl.node_tree.nodes['Principled BSDF']
    b_gl.inputs['Base Color'].default_value = (0.04, 0.08, 0.16, 1.0)
    b_gl.inputs['Roughness'].default_value = 0.10
    mats['glass'] = mat_gl

    # Dark Wood
    mat_wd = bpy.data.materials.new("M_DarkWood")
    mat_wd.use_nodes = True
    b_wd = mat_wd.node_tree.nodes['Principled BSDF']
    b_wd.inputs['Base Color'].default_value = (0.42, 0.28, 0.18, 1.0)
    b_wd.inputs['Roughness'].default_value = 0.70
    mats['wood'] = mat_wd

    return mats

# ----------------- PARAMETRIC DOMES -----------------
def create_fluted_dome(name, radius=1.0, height=1.6, ribs=24, rib_depth=0.08):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    v_segments = 24
    u_segments = 36
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
            row.append(bm.verts.new((base_r * rib_factor * math.cos(phi), base_r * rib_factor * math.sin(phi), z)))
        verts_grid.append(row)

    apex = bm.verts.new((0, 0, height + 0.05))

    for v in range(v_segments - 1):
        for u in range(u_segments):
            u_next = (u + 1) % u_segments
            bm.faces.new((verts_grid[v][u], verts_grid[v][u_next], verts_grid[v + 1][u_next], verts_grid[v + 1][u]))

    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        bm.faces.new((verts_grid[v_segments - 1][u], verts_grid[v_segments - 1][u_next], apex))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons: p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def create_baroque_dome(name, radius=1.0, height=1.6):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    v_segments = 20
    u_segments = 24
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
        for u in range(u_segments):
            phi = u * (2 * math.pi / u_segments)
            rib = 1.0 + 0.04 * math.cos(u_segments * phi) * math.sin(t * math.pi)
            row.append(bm.verts.new((r * rib * math.cos(phi), r * rib * math.sin(phi), z)))
        verts_grid.append(row)

    apex = bm.verts.new((0, 0, height + 0.06))

    for v in range(v_segments - 1):
        for u in range(u_segments):
            u_next = (u + 1) % u_segments
            bm.faces.new((verts_grid[v][u], verts_grid[v][u_next], verts_grid[v + 1][u_next], verts_grid[v + 1][u]))

    for u in range(u_segments):
        u_next = (u + 1) % u_segments
        bm.faces.new((verts_grid[v_segments - 1][u], verts_grid[v_segments - 1][u_next], apex))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons: p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

# ----------------- ASSEMBLE COMPLETE DIORAMA -----------------
def render_diorama():
    reset_scene()
    random.seed(42)

    mats = create_materials()

    root = bpy.data.objects.new("AAA_World_Diorama", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. LANDSCAPE TERRAIN (Winding river gorge + rolling hills)
    grid_res = 120
    grid_size = 28.0
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=grid_res, y_subdivisions=grid_res, size=grid_size, location=(0, 0, 0))
    terrain = bpy.context.active_object
    terrain.name = "DioramaTerrain"
    terrain.parent = root

    mesh = terrain.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    for v in bm.verts:
        x, y = v.co.x, v.co.y
        river_x = 0.45 * y - 0.02 * (y ** 2)
        dist_to_river = abs(x - river_x)

        if dist_to_river < 2.2:
            t_riv = dist_to_river / 2.2
            v.co.z = -1.2 + 0.3 * (t_riv ** 2)
        elif dist_to_river < 3.8:
            t_bank = (dist_to_river - 2.2) / 1.6
            v.co.z = -0.9 + 1.2 * math.sin(t_bank * (math.pi / 2))
        else:
            hill_noise = noise.noise(Vector((x * 0.15, y * 0.15, 0.0))) * 0.6
            v.co.z = 0.3 + hill_noise

    bm.to_mesh(mesh)
    bm.free()

    for p in terrain.data.polygons: p.use_smooth = True
    terrain.data.materials.append(mats['grass'])

    # 2. TURQUOISE WATER PLANE & FOAM
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, -0.42))
    water = bpy.context.active_object
    water.parent = root
    water.data.materials.append(mats['water'])

    # White shoreline foam contours
    for side in [-1, 1]:
        curve_data = bpy.data.curves.new(f"FoamCurve_{side}", type='CURVE')
        curve_data.dimensions = '3D'
        polyline = curve_data.splines.new('POLY')
        pts_count = 32
        polyline.points.add(pts_count - 1)
        for i in range(pts_count):
            y_val = -12.0 + i * (24.0 / (pts_count - 1))
            river_x = 0.45 * y_val - 0.02 * (y_val ** 2)
            polyline.points[i].co = (river_x + side * 2.3, y_val, -0.38, 1.0)
        curve_data.bevel_depth = 0.15
        curve_data.bevel_resolution = 3
        foam_obj = bpy.data.objects.new(f"FoamLine_{side}", curve_data)
        bpy.context.scene.collection.objects.link(foam_obj)
        foam_obj.parent = root
        foam_obj.data.materials.append(mats['foam'])

    # 3. CRAGGY ALPINE MOUNTAIN (Back-Left, Circle 2!)
    mtn_res = 60
    mtn_size = 11.0
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=mtn_res, y_subdivisions=mtn_res, size=mtn_size, location=(-7.5, 4.5, 0.0))
    mtn = bpy.context.active_object
    mtn.name = "CraggyMountainPeak"
    mtn.parent = root

    m_mesh = mtn.data
    m_bm = bmesh.new()
    m_bm.from_mesh(m_mesh)

    for v in m_bm.verts:
        lx, ly = v.co.x, v.co.y
        dist = math.sqrt(lx*lx + ly*ly)
        r_norm = dist / (mtn_size * 0.46)
        if r_norm >= 1.0:
            v.co.z = 0.0
            continue
        mask = math.cos(r_norm * math.pi * 0.5) ** 2.2
        pos = Vector((lx * 0.35, ly * 0.35, 0.0))
        rmf = noise.ridged_multi_fractal(pos, 0.9, 2.1, 4, 1.0, 2.0)
        raw_h = max(0.0, rmf * 4.2 * mask)
        step_freq = 1.3
        terrace = math.floor(raw_h * step_freq) / step_freq
        v.co.z = max(0.0, raw_h * 0.5 + terrace * 0.5)

    m_bm.to_mesh(m_mesh)
    m_bm.free()

    dec = mtn.modifiers.new("Decimate", 'DECIMATE')
    dec.decimate_type = 'COLLAPSE'
    dec.ratio = 0.30
    bpy.ops.object.select_all(action='DESELECT')
    mtn.select_set(True)
    bpy.context.view_layer.objects.active = mtn
    bpy.ops.object.modifier_apply(modifier="Decimate")

    for p in mtn.data.polygons: p.use_smooth = False
    mtn.data.materials.append(mats['rock'])

    # 4. SAMARKAND REGISTAN ENSEMBLE (Circle 2!)
    sam_root = bpy.data.objects.new("Samarkand_Palace", None)
    sam_root.location = (-6.5, -0.5, 0.3)
    sam_root.parent = root
    bpy.context.scene.collection.objects.link(sam_root)

    # Multi-tier podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.2))
    s_pod = bpy.context.active_object
    s_pod.scale = (5.6, 3.8, 0.4)
    s_pod.parent = sam_root
    s_pod.data.materials.append(mats['sandstone'])
    apply_bevel(s_pod, width=0.03)

    # Monumental Iwan Portal Frame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.4 + 1.8))
    s_portal = bpy.context.active_object
    s_portal.scale = (2.4, 1.4, 3.6)
    s_portal.parent = sam_root
    s_portal.data.materials.append(mats['sandstone'])
    apply_bevel(s_portal, width=0.03)

    # Inset Lapis Border
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.92, 0.4 + 1.8))
    s_lapis = bpy.context.active_object
    s_lapis.scale = (2.44, 0.06, 3.64)
    s_lapis.parent = sam_root
    s_lapis.data.materials.append(mats['lapis'])

    # Iwan Vault Arch Recess
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.65, 0.4 + 1.6))
    s_iwan = bpy.context.active_object
    s_iwan.scale = (1.5, 0.65, 2.6)
    s_iwan.parent = sam_root
    s_iwan.data.materials.append(mats['turq_dome'])

    # Deep Portal Entrance Doorway
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.85, 0.4 + 0.75))
    s_door = bpy.context.active_object
    s_door.scale = (0.8, 0.4, 1.5)
    s_door.parent = sam_root
    s_door.data.materials.append(mats['glass'])

    # Side Wings with 2 tiers of Arched Niches
    for side in [-1, 1]:
        wx = side * 1.85
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.2, 0.4 + 1.2))
        s_wing = bpy.context.active_object
        s_wing.scale = (1.3, 1.2, 2.4)
        s_wing.parent = sam_root
        s_wing.data.materials.append(mats['sandstone'])
        apply_bevel(s_wing, width=0.03)

        # Arched Niches
        for tz in [0.4 + 0.7, 0.4 + 1.7]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, -0.82, tz))
            niche = bpy.context.active_object
            niche.scale = (0.55, 0.15, 0.7)
            niche.parent = sam_root
            niche.data.materials.append(mats['turq_dome'])

    # Central Fluted Azure/Turquoise Melon Dome on Cylindrical Drum
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=1.05, depth=0.8, location=(0, 0.2, 0.4 + 3.8))
    s_drum = bpy.context.active_object
    s_drum.parent = sam_root
    s_drum.data.materials.append(mats['lapis'])

    s_dome = create_fluted_dome("Sam_Central_Dome", radius=1.1, height=1.55, ribs=20)
    s_dome.location = (0, 0.2, 0.4 + 4.2)
    s_dome.parent = sam_root
    s_dome.data.materials.append(mats['turq_dome'])

    # Golden Finial Orb and Crescent
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.20, location=(0, 0.2, 0.4 + 5.85))
    s_fin = bpy.context.active_object
    s_fin.parent = sam_root
    s_fin.data.materials.append(mats['gold'])

    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.07, radius2=0.0, depth=0.6, location=(0, 0.2, 0.4 + 6.2))
    s_tip = bpy.context.active_object
    s_tip.parent = sam_root
    s_tip.data.materials.append(mats['gold'])

    # Four Tall Slender Minarets with Balconies & Golden Spires
    min_coords = [(-2.6, -1.3), (2.6, -1.3), (-1.3, -1.0), (1.3, -1.0)]
    for mx, my in min_coords:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.24, depth=4.6, location=(mx, my, 0.4 + 2.3))
        min_shaft = bpy.context.active_object
        min_shaft.parent = sam_root
        min_shaft.data.materials.append(mats['sandstone'])
        apply_bevel(min_shaft, width=0.02)

        # Muqarnas Balcony
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.36, depth=0.28, location=(mx, my, 0.4 + 4.6))
        min_balc = bpy.context.active_object
        min_balc.parent = sam_root
        min_balc.data.materials.append(mats['lapis'])

        # Top Pavilion Drum
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.20, depth=0.5, location=(mx, my, 0.4 + 5.0))
        min_pav = bpy.context.active_object
        min_pav.parent = sam_root
        min_pav.data.materials.append(mats['sandstone'])

        # Conical Tiled Spire
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.22, radius2=0.0, depth=0.85, location=(mx, my, 0.4 + 5.65))
        min_spire = bpy.context.active_object
        min_spire.parent = sam_root
        min_spire.data.materials.append(mats['turq_dome'])

        # Golden Tip
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.09, location=(mx, my, 0.4 + 6.15))
        min_tip = bpy.context.active_object
        min_tip.parent = sam_root
        min_tip.data.materials.append(mats['gold'])

    # 5. BERLIN FAIRYTALE CATHEDRAL PALACE (Circle 1!)
    ber_root = bpy.data.objects.new("Berlin_Castle", None)
    ber_root.location = (4.8, 6.2, 0.4)
    ber_root.parent = root
    bpy.context.scene.collection.objects.link(ber_root)

    # Red Captured Territory Splat
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=4.8, depth=0.04, location=(0, -0.2, 0.02))
    b_terr = bpy.context.active_object
    b_terr.parent = ber_root
    b_terr.data.materials.append(mats['terr_red'])

    # Palace White Foundation Podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.2))
    b_pod = bpy.context.active_object
    b_pod.scale = (5.8, 3.8, 0.4)
    b_pod.parent = ber_root
    b_pod.data.materials.append(mats['marble'])
    apply_bevel(b_pod, width=0.03)

    # Palace Main Body with Classical Colonnade
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.1, 0.4 + 1.1))
    b_body = bpy.context.active_object
    b_body.scale = (5.2, 3.0, 2.2)
    b_body.parent = ber_root
    b_body.data.materials.append(mats['marble'])
    apply_bevel(b_body, width=0.03)

    # Arched Colonnade on Ground Floor
    for col_x in [-2.0, -1.2, 1.2, 2.0]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.12, depth=1.1, location=(col_x, -1.65, 0.4 + 0.55))
        c_col = bpy.context.active_object
        c_col.parent = ber_root
        c_col.data.materials.append(mats['marble'])

    # Red Mansard Roof on Wings
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 1.8, -0.1, 0.4 + 2.7))
        b_roof = bpy.context.active_object
        b_roof.scale = (1.9, 2.8, 1.1)
        b_roof.parent = ber_root
        b_roof.data.materials.append(mats['red_roof'])
        apply_bevel(b_roof, width=0.03)

    # Central Grand Clock Belfry Tower
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.2, 0.4 + 3.0))
    b_tower = bpy.context.active_object
    b_tower.scale = (1.8, 1.8, 2.4)
    b_tower.parent = ber_root
    b_tower.data.materials.append(mats['marble'])
    apply_bevel(b_tower, width=0.03)

    # Gold Clock Face
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.40, depth=0.12, location=(0, -1.12, 0.4 + 2.8))
    b_clock = bpy.context.active_object
    b_clock.rotation_euler = (math.radians(90), 0, 0)
    b_clock.parent = ber_root
    b_clock.data.materials.append(mats['gold'])

    # Grand Baroque Red Bell-Cupola
    b_cupola = create_baroque_dome("Berlin_Cupola", radius=0.95, height=1.45)
    b_cupola.location = (0, -0.2, 0.4 + 4.2)
    b_cupola.parent = ber_root
    b_cupola.data.materials.append(mats['red_roof'])

    # Gold Lantern and Spire
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.32, depth=0.5, location=(0, -0.2, 0.4 + 5.8))
    b_lant = bpy.context.active_object
    b_lant.parent = ber_root
    b_lant.data.materials.append(mats['gold'])

    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.09, radius2=0.0, depth=1.1, location=(0, -0.2, 0.4 + 6.55))
    b_spire = bpy.context.active_object
    b_spire.parent = ber_root
    b_spire.data.materials.append(mats['gold'])

    # 4 Corner Towers with Baroque Red Domes
    corner_berlin = [(-2.5, -1.4), (2.5, -1.4), (-2.5, 1.2), (2.5, 1.2)]
    for cx, cy in corner_berlin:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.55, depth=2.8, location=(cx, cy, 0.4 + 1.4))
        c_tow = bpy.context.active_object
        c_tow.parent = ber_root
        c_tow.data.materials.append(mats['marble'])

        s_cup = create_baroque_dome(f"Corner_Cupola_{cx}_{cy}", radius=0.58, height=0.95)
        s_cup.location = (cx, cy, 0.4 + 2.8)
        s_cup.parent = ber_root
        s_cup.data.materials.append(mats['red_roof'])

        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.05, radius2=0.0, depth=0.6, location=(cx, cy, 0.4 + 3.8))
        s_sp = bpy.context.active_object
        s_sp.parent = ber_root
        s_sp.data.materials.append(mats['gold'])

    # 6. DUBAI LUXURY GOLDEN PALACE (Circle 3!)
    dub_root = bpy.data.objects.new("Dubai_Palace", None)
    dub_root.location = (7.5, -4.8, 0.3)
    dub_root.parent = root
    bpy.context.scene.collection.objects.link(dub_root)

    # Yellow Captured Territory Splat
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=4.6, depth=0.04, location=(0, -0.2, 0.02))
    d_terr = bpy.context.active_object
    d_terr.parent = dub_root
    d_terr.data.materials.append(mats['terr_yellow'])

    # White Marble Podium
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.2))
    d_pod = bpy.context.active_object
    d_pod.scale = (5.6, 4.0, 0.4)
    d_pod.parent = dub_root
    d_pod.data.materials.append(mats['marble'])
    apply_bevel(d_pod, width=0.03)

    # Main Palace Body with Colonnades
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.1, 0.4 + 1.0))
    d_body = bpy.context.active_object
    d_body.scale = (5.0, 3.0, 2.0)
    d_body.parent = dub_root
    d_body.data.materials.append(mats['marble'])
    apply_bevel(d_body, width=0.03)

    # Grand Arched Facade Openings
    for cx in [-1.8, -0.9, 0.9, 1.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, -1.65, 0.4 + 0.8))
        d_arch = bpy.context.active_object
        d_arch.scale = (0.6, 0.2, 1.2)
        d_arch.parent = dub_root
        d_arch.data.materials.append(mats['glass'])

    # Giant Gleaming Golden Onion Dome in Center!
    d_dome = create_fluted_dome("Dubai_Central_Dome", radius=1.35, height=1.9, ribs=16)
    d_dome.location = (0, -0.1, 0.4 + 2.0)
    d_dome.parent = dub_root
    d_dome.data.materials.append(mats['gold'])

    # Golden Spire
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.09, radius2=0.0, depth=0.9, location=(0, -0.1, 0.4 + 4.0))
    d_spire = bpy.context.active_object
    d_spire.parent = dub_root
    d_spire.data.materials.append(mats['gold'])

    # 4 Corner Golden Domes
    for dx, dy in [(-2.3, -1.3), (2.3, -1.3), (-2.3, 1.1), (2.3, 1.1)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.48, depth=2.4, location=(dx, dy, 0.4 + 1.2))
        d_tower = bpy.context.active_object
        d_tower.parent = dub_root
        d_tower.data.materials.append(mats['marble'])

        s_dome = create_fluted_dome(f"Dubai_CornerDome_{dx}_{dy}", radius=0.58, height=0.95, ribs=12)
        s_dome.location = (dx, dy, 0.4 + 2.4)
        s_dome.parent = dub_root
        s_dome.data.materials.append(mats['gold'])

    # 7. TROPICAL BRIDGE SPANNING THE TURQUOISE RIVER
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.2, 1.2, -0.1))
    bridge = bpy.context.active_object
    bridge.scale = (4.0, 1.3, 0.25)
    bridge.rotation_euler = (0, 0, math.radians(-25))
    bridge.parent = root
    bridge.data.materials.append(mats['wood'])
    apply_bevel(bridge, width=0.03)

    # Stone Piers
    for px, py in [(1.0, 0.6), (3.4, 1.8)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.28, depth=0.9, location=(px, py, -0.5))
        pier = bpy.context.active_object
        pier.parent = root
        pier.data.materials.append(mats['sandstone'])

    # 8. SCATTERED BOULDERS & ISLETS IN TURQUOISE WATER (Circle 4!)
    boulder_locs = [
        (-1.2, -3.5, -0.25, 0.70), (-0.4, -4.2, -0.20, 0.90), (0.5, -3.8, -0.28, 0.60),
        (-2.5, -6.5, -0.22, 0.80), (-3.2, -5.8, -0.25, 0.65),
        (3.8, 4.2, -0.25, 0.75), (4.5, 3.6, -0.28, 0.60)
    ]
    for bx, by, bz, bscl in boulder_locs:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=bscl, location=(bx, by, bz))
        bould = bpy.context.active_object
        bould.parent = root
        bould.data.materials.append(mats['rock'])
        for p in bould.data.polygons: p.use_smooth = False

        # White foam ring around boulder
        bpy.ops.mesh.primitive_torus_add(major_radius=bscl * 1.15, minor_radius=0.08, location=(bx, by, -0.38))
        f_ring = bpy.context.active_object
        f_ring.parent = root
        f_ring.data.materials.append(mats['foam'])

    # 9. PINE FORESTS & PALMS
    nature_dir = r"D:\antigravity\blender_assets\kenney_nature\Models\GLTF format"
    pine_path = os.path.join(nature_dir, "tree_pineTallA_detailed.glb")
    palm_path = os.path.join(nature_dir, "tree_palmDetailedTall.glb")

    pine_src = None
    if os.path.exists(pine_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=pine_path)
        pine_src = list(set(bpy.data.objects) - before)[0]
        pine_src.location = (1000, 1000, 1000)

    palm_src = None
    if os.path.exists(palm_path):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=palm_path)
        palm_src = list(set(bpy.data.objects) - before)[0]
        palm_src.location = (1000, 1000, 1000)

    # Spawn pines on mountain shelves & banks
    tree_spots = [
        (-9.2, 5.5, 0.5), (-10.0, 3.8, 0.3), (-8.5, 7.2, 0.4), (-6.0, 7.8, 0.3),
        (-8.2, 2.2, 0.4), (-9.5, 1.5, 0.3),
        (-3.8, 2.5, 0.3), (-4.2, 3.8, 0.4), (-3.5, 5.2, 0.3),
        (2.8, -1.2, 0.3), (3.6, -2.5, 0.3), (4.2, -0.5, 0.4),
        (3.2, 7.5, 0.5), (6.8, 7.8, 0.4), (7.5, 5.5, 0.4), (2.5, 5.2, 0.3)
    ]
    if pine_src:
        for tx, ty, tz in tree_spots:
            clone = pine_src.copy()
            if pine_src.data: clone.data = pine_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (tx, ty, tz)
            scl = random.uniform(1.2, 1.6)
            clone.scale = (scl, scl, scl)
            clone.rotation_euler = (0, 0, random.uniform(0, 2*math.pi))
            clone.parent = root

    # Spawn palms near Dubai
    palm_spots = [
        (5.5, -6.5, 0.3), (6.2, -7.2, 0.3), (9.2, -3.5, 0.3), (9.8, -5.2, 0.3)
    ]
    if palm_src:
        for px, py, pz in palm_spots:
            clone = palm_src.copy()
            if palm_src.data: clone.data = palm_src.data.copy()
            bpy.context.scene.collection.objects.link(clone)
            clone.location = (px, py, pz)
            clone.scale = (1.4, 1.4, 1.4)
            clone.rotation_euler = (0, 0, random.uniform(0, 2*math.pi))
            clone.parent = root

    # 10. GLOSSY CATERPILLAR PLAYER CHARACTER (Smiling red worm with glassy shine)
    cat_head_pos = Vector((3.5, 4.6, 0.7))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=18, radius=0.48, location=cat_head_pos)
    c_head = bpy.context.active_object
    c_head.parent = root
    c_head.data.materials.append(mats['caterpillar'])

    # Big Anime Eyes
    for eye_side in [-0.16, 0.16]:
        eye_pos = cat_head_pos + Vector((eye_side, -0.40, 0.16))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.13, location=eye_pos)
        eye_w = bpy.context.active_object
        eye_w.parent = root
        eye_w.data.materials.append(mats['marble'])

        pupil_pos = eye_pos + Vector((0, -0.06, 0))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.07, location=pupil_pos)
        pupil = bpy.context.active_object
        pupil.parent = root
        pupil.data.materials.append(mats['glass'])

    # Caterpillar Body Trail
    trail_pts = [
        Vector((3.0, 4.4, 0.65)),
        Vector((2.5, 4.1, 0.60)),
        Vector((2.0, 3.8, 0.58)),
        Vector((1.6, 3.4, 0.55)),
        Vector((1.2, 3.0, 0.52))
    ]
    for idx, pt in enumerate(trail_pts):
        r_seg = 0.40 - idx * 0.02
        bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=14, radius=r_seg, location=pt)
        c_seg = bpy.context.active_object
        c_seg.parent = root
        c_seg.data.materials.append(mats['caterpillar'])

    # 11. AAA STUDIO LIGHTING (Warm sun 50 deg + soft sky fill)
    sun = bpy.data.lights.new("Sun_Key", 'SUN')
    sun.energy = 5.6
    sun.color = (1.0, 0.95, 0.86)
    sun.angle = math.radians(5.0)
    sun_obj = bpy.data.objects.new("Sun_Key", sun)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), math.radians(22), math.radians(-35))

    fill = bpy.data.lights.new("Sky_Fill", 'SUN')
    fill.energy = 2.0
    fill.color = (0.55, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Sky_Fill", fill)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(10), math.radians(145))

    # 12. CAMERA SETUP (Isometric diorama angle)
    cam = bpy.data.cameras.new("DioramaCamera")
    cam.lens = 45
    cam_obj = bpy.data.objects.new("DioramaCamera", cam)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (18.5, -24.0, 19.5)
    target = Vector((0.0, 0.5, 0.5))
    cam_obj.rotation_euler = (target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # 13. RENDER SETTINGS (Cycles High Quality 1200x1200)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1200
    out_path = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_final_aaa_diorama.png"
    scene.render.filepath = out_path

    print("STARTING ULTIMATE AAA DIORAMA RENDER...")
    bpy.ops.render.render(write_still=True)
    print("ULTIMATE_AAA_DIORAMA_RENDER_COMPLETE:", out_path)

if __name__ == "__main__":
    render_diorama()
