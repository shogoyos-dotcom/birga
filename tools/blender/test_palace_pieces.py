import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, rough=0.5, metal=0.0, spec=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metal
    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = spec
    return mat

def create_colonnade(num_columns=5, spacing=1.2, height=2.5, radius=0.18, arch_height=0.8):
    """Creates a classical arched colonnade arcade with pillars, arches and cornice."""
    bm = bmesh.new()
    
    total_len = (num_columns - 1) * spacing
    start_x = -total_len / 2.0
    
    # Columns
    for i in range(num_columns):
        cx = start_x + i * spacing
        # Base plinth
        bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((cx, 0, 0.15))) @ Matrix.Diagonal(Vector((radius*2.6, radius*2.6, 0.3, 1.0))))
        # Column shaft (cylinder)
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=16, radius1=radius, radius2=radius*0.9, depth=height-0.6, matrix=Matrix.Translation(Vector((cx, 0, 0.3 + (height-0.6)/2.0))))
        # Capital
        bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((cx, 0, height - 0.15))) @ Matrix.Diagonal(Vector((radius*2.8, radius*2.8, 0.3, 1.0))))
    
    # Arches between columns
    for i in range(num_columns - 1):
        c1 = start_x + i * spacing
        c2 = start_x + (i + 1) * spacing
        mid_x = (c1 + c2) / 2.0
        span = spacing - radius * 2.0
        r_arch = span / 2.0
        
        # Arch barrel/voussoir
        arch_segs = 12
        for s in range(arch_segs):
            a1 = math.pi * s / arch_segs
            a2 = math.pi * (s + 1) / arch_segs
            
            x1 = mid_x - r_arch * math.cos(a1)
            z1 = height + r_arch * math.sin(a1)
            x2 = mid_x - r_arch * math.cos(a2)
            z2 = height + r_arch * math.sin(a2)
            
            seg_center = Vector(((x1+x2)/2.0, 0, (z1+z2)/2.0))
            seg_len = math.sqrt((x2-x1)**2 + (z2-z1)**2)
            ang = math.atan2(z2-z1, x2-x1)
            rot = Matrix.Rotation(ang, 4, 'Y')
            mat = Matrix.Translation(seg_center) @ rot @ Matrix.Diagonal(Vector((seg_len*1.05, radius*2.4, 0.22, 1.0)))
            bmesh.ops.create_cube(bm, size=1.0, matrix=mat)
            
        # Spandrel infill
        spandrel_h = r_arch + 0.35
        bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((mid_x, 0, height + spandrel_h/2.0))) @ Matrix.Diagonal(Vector((spacing, radius*2.2, spandrel_h, 1.0))))
    
    # Cornice lintel on top
    cornice_z = height + (spacing - radius*2.0)/2.0 + 0.4
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((0, 0, cornice_z))) @ Matrix.Diagonal(Vector((total_len + spacing*0.8, radius*3.0, 0.35, 1.0))))
    
    # Balustrade on top of cornice
    balustrade_z = cornice_z + 0.35
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((0, 0, balustrade_z + 0.2))) @ Matrix.Diagonal(Vector((total_len + spacing*0.7, radius*1.5, 0.4, 1.0))))

    mesh = bpy.data.meshes.new("ColonnadeArcade")
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new("ColonnadeArcade", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def create_fluted_dome_citadel(radius=2.0, drum_height=2.2, dome_height=2.6, ribs=24):
    """Creates a grand Samarkand / Tashkent style rotunda with arched drum and fluted ribbed turquoise melon dome."""
    bm = bmesh.new()
    
    # 1. Circular drum with arched windows
    num_sides = ribs
    for i in range(num_sides):
        ang1 = 2 * math.pi * i / num_sides
        ang2 = 2 * math.pi * (i + 1) / num_sides
        mid_ang = (ang1 + ang2) / 2.0
        
        x1, y1 = radius * math.cos(ang1), radius * math.sin(ang1)
        mid_x, mid_y = radius * math.cos(mid_ang), radius * math.sin(mid_ang)
        
        # Column / pilaster at each facet joint
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=8, radius1=0.15, radius2=0.12, depth=drum_height, matrix=Matrix.Translation(Vector((x1, y1, drum_height/2.0))))
        
        # Window or niche
        if i % 2 == 0:
            bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((mid_x*0.96, mid_y*0.96, drum_height*0.25))) @ Matrix.Rotation(mid_ang + math.pi/2, 4, 'Z') @ Matrix.Diagonal(Vector((radius*0.25, 0.15, drum_height*0.4, 1.0))))
            bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((mid_x*0.92, mid_y*0.92, drum_height*0.65))) @ Matrix.Rotation(mid_ang + math.pi/2, 4, 'Z') @ Matrix.Diagonal(Vector((radius*0.22, 0.1, drum_height*0.5, 1.0))))
        else:
            bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(Vector((mid_x*0.95, mid_y*0.95, drum_height*0.5))) @ Matrix.Rotation(mid_ang + math.pi/2, 4, 'Z') @ Matrix.Diagonal(Vector((radius*0.26, 0.12, drum_height*0.9, 1.0))))

    # Cornice ring on drum top
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=ribs, radius1=radius*1.15, radius2=radius*1.12, depth=0.35, matrix=Matrix.Translation(Vector((0, 0, drum_height + 0.17))))
    
    mesh = bpy.data.meshes.new("RotundaDrum")
    bm.to_mesh(mesh)
    bm.free()
    drum_obj = bpy.data.objects.new("RotundaDrum", mesh)
    bpy.context.scene.collection.objects.link(drum_obj)
    
    # 2. Melon dome mesh
    d_bm = bmesh.new()
    rings = 24
    z_start = drum_height + 0.35
    
    verts = []
    for r in range(rings + 1):
        t = r / float(rings)
        if t < 0.2:
            r_scale = 1.0 + 0.25 * math.sin(t / 0.2 * math.pi * 0.5)
        elif t < 0.8:
            nt = (t - 0.2) / 0.6
            r_scale = 1.25 * math.cos(nt * math.pi * 0.45)
        else:
            nt = (t - 0.8) / 0.2
            r_scale = 1.25 * math.cos(0.45 * math.pi) * (1.0 - nt)**1.3
            
        cur_z = z_start + dome_height * (math.sin(t * math.pi * 0.5) ** 0.85)
        
        ring_verts = []
        for s in range(ribs):
            angle = 2.0 * math.pi * s / float(ribs)
            flute = 1.0 + 0.08 * math.cos(angle * ribs * 0.5)
            eff_r = radius * r_scale * flute
            vx = eff_r * math.cos(angle)
            vy = eff_r * math.sin(angle)
            v = d_bm.verts.new(Vector((vx, vy, cur_z)))
            ring_verts.append(v)
        verts.append(ring_verts)
        
    for r in range(rings):
        for s in range(ribs):
            s_next = (s + 1) % ribs
            v1 = verts[r][s]
            v2 = verts[r][s_next]
            v3 = verts[r+1][s_next]
            v4 = verts[r+1][s]
            d_bm.faces.new([v1, v2, v3, v4])
            
    top_v = d_bm.verts.new(Vector((0, 0, z_start + dome_height + 0.2)))
    for s in range(ribs):
        s_next = (s + 1) % ribs
        d_bm.faces.new([verts[rings][s], verts[rings][s_next], top_v])
        
    d_mesh = bpy.data.meshes.new("FlutedMelonDome")
    d_bm.to_mesh(d_mesh)
    d_bm.free()
    for p in d_mesh.polygons: p.use_smooth = True
    
    dome_obj = bpy.data.objects.new("FlutedMelonDome", d_mesh)
    bpy.context.scene.collection.objects.link(dome_obj)
    
    # 3. Gold Spire Finial
    f_bm = bmesh.new()
    fz = z_start + dome_height + 0.2
    bmesh.ops.create_uvsphere(f_bm, u_segments=16, v_segments=12, radius=0.25, matrix=Matrix.Translation(Vector((0, 0, fz + 0.25))))
    bmesh.ops.create_cone(f_bm, cap_ends=True, cap_tris=False, segments=16, radius1=0.2, radius2=0.08, depth=0.3, matrix=Matrix.Translation(Vector((0, 0, fz + 0.55))))
    bmesh.ops.create_uvsphere(f_bm, u_segments=16, v_segments=12, radius=0.18, matrix=Matrix.Translation(Vector((0, 0, fz + 0.85))))
    bmesh.ops.create_cone(f_bm, cap_ends=True, cap_tris=False, segments=12, radius1=0.08, radius2=0.0, depth=0.8, matrix=Matrix.Translation(Vector((0, 0, fz + 1.35))))
    bmesh.ops.create_cone(f_bm, cap_ends=True, cap_tris=False, segments=16, radius1=0.18, radius2=0.14, depth=0.1, matrix=Matrix.Translation(Vector((0, 0, fz + 1.8))))
    
    f_mesh = bpy.data.meshes.new("GoldFinial")
    f_bm.to_mesh(f_mesh)
    f_bm.free()
    finial_obj = bpy.data.objects.new("GoldFinial", f_mesh)
    bpy.context.scene.collection.objects.link(finial_obj)
    
    return drum_obj, dome_obj, finial_obj

def run():
    reset_scene()
    
    m_stone = create_mat("M_Sandstone", (0.88, 0.82, 0.72, 1.0), rough=0.55)
    m_dome = create_mat("M_TurquoiseDome", (0.05, 0.72, 0.82, 1.0), rough=0.18, spec=0.9)
    m_gold = create_mat("M_PalaceGold", (1.0, 0.80, 0.22, 1.0), rough=0.22, metal=0.95)
    
    col_obj = create_colonnade(num_columns=6, spacing=1.1, height=2.4)
    col_obj.location = (0, -3.5, 0)
    col_obj.data.materials.append(m_stone)
    
    drum, dome, finial = create_fluted_dome_citadel(radius=2.0, drum_height=2.2, dome_height=2.6, ribs=24)
    drum.location = (0, 1.0, 0)
    dome.location = (0, 1.0, 0)
    finial.location = (0, 1.0, 0)
    
    drum.data.materials.append(m_stone)
    dome.data.materials.append(m_dome)
    finial.data.materials.append(m_gold)
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.2))
    ground = bpy.context.active_object
    ground.scale = (12, 10, 0.4)
    ground.data.materials.append(m_stone)
    
    cam_data = bpy.data.cameras.new("TestCam")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new("TestCam", cam_data)
    cam_obj.location = (8.5, -10.5, 7.5)
    cam_obj.rotation_euler = (math.radians(60), 0, math.radians(40))
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    sun_data = bpy.data.lights.new("Sun", type='SUN')
    sun_data.energy = 4.5
    sun_data.color = (1.0, 0.96, 0.88)
    sun_data.angle = 0.08
    sun_obj = bpy.data.objects.new("Sun", sun_data)
    sun_obj.rotation_euler = (math.radians(48), math.radians(18), math.radians(-35))
    bpy.context.scene.collection.objects.link(sun_obj)
    
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.55, 0.72, 0.95, 1.0)
    bg.inputs['Strength'].default_value = 0.8
    bpy.context.scene.world = world
    
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 48
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.filepath = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\test_palace_pieces.png"
    
    bpy.ops.render.render(write_still=True)
    print("Render complete: test_palace_pieces.png")

run()
