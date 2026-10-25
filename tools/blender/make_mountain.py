import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, roughness=0.6, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def build_stylized_mountain():
    reset_scene()
    
    # Materials
    mat_rock_dark = create_mat("M_RockDark", (0.28, 0.32, 0.36, 1.0), roughness=0.85)
    mat_rock_light = create_mat("M_RockLight", (0.48, 0.52, 0.55, 1.0), roughness=0.75)
    mat_snow = create_mat("M_Snow", (0.95, 0.97, 1.0, 1.0), roughness=0.4)
    mat_grass = create_mat("M_MountainGrass", (0.25, 0.58, 0.18, 1.0), roughness=0.8)
    mat_pine = create_mat("M_MountainPine", (0.08, 0.35, 0.15, 1.0), roughness=0.7)
    mat_wood = create_mat("M_WoodTrunk", (0.35, 0.22, 0.12, 1.0), roughness=0.9)

    root = bpy.data.objects.new("Mountain_Rocky_AAA", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Main craggy peaks and rock terraces using faceted displaced geometry
    # We construct 3 primary mountain peaks (Central high, West shoulder, East shoulder)
    peaks_data = [
        # (center_x, center_y, base_r, height, num_sides, snow_h)
        (0.0, 0.0, 6.0, 9.5, 9, 7.2),     # Main sharp summit
        (-3.8, 1.2, 4.2, 7.2, 8, 5.6),   # West crag
        (3.5, -0.8, 4.5, 6.8, 8, 5.2),    # East crag
        (-1.5, -3.2, 3.8, 5.0, 7, 0.0),   # South craggy ridge
        (2.2, 3.0, 4.0, 5.5, 7, 4.2),     # North-east ridge
    ]

    for p_idx, (px, py, radius, height, sides, snow_threshold) in enumerate(peaks_data):
        bm = bmesh.new()
        
        # Build stepped craggy cone with 4 elevation tiers
        tiers = [
            (0.0, radius * 1.05, 1.0),
            (height * 0.28, radius * 0.78, 0.95),
            (height * 0.58, radius * 0.50, 0.88),
            (height * 0.82, radius * 0.26, 0.80),
            (height * 1.00, 0.08, 0.40)
        ]
        
        prev_verts = []
        for t_idx, (tz, tr, twist) in enumerate(tiers):
            layer_verts = []
            for s in range(sides):
                angle = (s / sides) * 2.0 * math.pi + (t_idx * 0.22) * twist
                # Add natural rocky jitter
                jitter = 1.0 + 0.18 * math.sin(s * 2.8 + t_idx * 1.5) + 0.12 * math.cos(s * 1.4)
                vx = px + math.cos(angle) * tr * jitter
                vy = py + math.sin(angle) * tr * jitter
                vz = tz + (0.15 * math.sin(s * 3.1) if t_idx > 0 else 0.0)
                v = bm.verts.new((vx, vy, vz))
                layer_verts.append(v)
            
            if prev_verts:
                for s in range(sides):
                    s_next = (s + 1) % sides
                    v1 = prev_verts[s]
                    v2 = prev_verts[s_next]
                    v3 = layer_verts[s_next]
                    v4 = layer_verts[s]
                    bm.faces.new((v1, v2, v3, v4))
            prev_verts = layer_verts
        
        # Cap summit
        summit = bm.verts.new((px, py, height + 0.2))
        for s in range(sides):
            s_next = (s + 1) % sides
            bm.faces.new((prev_verts[s], prev_verts[s_next], summit))
            
        mesh = bpy.data.meshes.new(f"CragMesh_{p_idx}")
        bm.to_mesh(mesh)
        bm.free()
        
        # Faceted shading (flat shaded for crisp stylized low-poly rock faces)
        for poly in mesh.polygons:
            poly.use_smooth = False
            
        obj = bpy.data.objects.new(f"Peak_{p_idx}", mesh)
        obj.data.materials.append(mat_rock_light)
        obj.data.materials.append(mat_snow)
        
        # Assign snow material to faces above threshold
        for poly in obj.data.polygons:
            center_z = sum(obj.data.vertices[v].co.z for v in poly.vertices) / len(poly.vertices)
            if snow_threshold > 0 and center_z >= snow_threshold:
                poly.material_index = 1
                
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = root

    # 2. Add rocky scree terraces and ledges with green grass skirts
    ledge_positions = [
        (-4.2, -1.8, 1.2, 2.2, 1.6),
        (3.8, 1.8, 1.0, 2.5, 1.5),
        (-1.0, 4.0, 1.5, 2.0, 1.8),
        (0.5, -4.5, 0.8, 2.8, 1.4),
        (-3.0, 3.2, 2.2, 1.8, 1.2),
        (4.2, -2.5, 1.4, 2.0, 1.3),
    ]
    for l_idx, (lx, ly, lz, lr, lh) in enumerate(ledge_positions):
        bpy.ops.mesh.primitive_cylinder_add(vertices=7, radius=lr, depth=lh, location=(lx, ly, lz))
        ledge = bpy.context.active_object
        ledge.name = f"Ledge_{l_idx}"
        ledge.parent = root
        ledge.data.materials.append(mat_grass)
        ledge.data.materials.append(mat_rock_dark)
        for poly in ledge.data.polygons:
            poly.use_smooth = False
            if poly.normal.z < 0.3:
                poly.material_index = 1

    # 3. Clustered Stylized Pine Trees on Lower Mountain Slopes
    tree_coords = [
        (-4.8, -2.2, 1.8), (-3.6, -2.8, 1.5), (-5.2, -1.2, 1.2),
        (4.2, 1.2, 1.6), (4.8, 2.2, 1.2), (3.2, 2.6, 2.0),
        (-1.8, 4.2, 1.8), (0.2, 4.8, 1.2), (-0.8, 3.6, 2.4),
        (1.2, -4.8, 1.1), (2.4, -4.2, 1.5), (-2.2, -4.2, 0.9),
    ]
    for t_idx, (tx, ty, tz) in enumerate(tree_coords):
        # Trunk
        bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=0.14, depth=0.9, location=(tx, ty, tz + 0.45))
        trunk = bpy.context.active_object
        trunk.name = f"TreeTrunk_{t_idx}"
        trunk.parent = root
        trunk.data.materials.append(mat_wood)
        
        # 3 layered pine cones
        for c in range(3):
            cz = tz + 0.8 + c * 0.55
            cr = 0.75 - c * 0.18
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=cr, depth=0.8, location=(tx, ty, cz))
            cone = bpy.context.active_object
            cone.name = f"TreeFoliage_{t_idx}_{c}"
            cone.parent = root
            cone.data.materials.append(mat_pine)

    return root

def render_preview(output_path):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    scene.render.filepath = output_path
    
    # Ground plane
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.name = "GroundShadow"
    mat_g = create_mat("M_GroundFloor", (0.32, 0.65, 0.24, 1.0), roughness=0.9)
    ground.data.materials.append(mat_g)
    
    # Lighting setup (Three-point stylized studio sun)
    # 1. Warm Key Sun
    key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
    key_light_data.energy = 4.2
    key_light_data.color = (1.0, 0.96, 0.88)
    key_light = bpy.data.objects.new("KeyLight", key_light_data)
    scene.collection.objects.link(key_light)
    key_light.rotation_euler = (math.radians(48), math.radians(22), math.radians(-38))
    
    # 2. Cool Sky Fill
    fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
    fill_light_data.energy = 1.6
    fill_light_data.color = (0.55, 0.80, 1.0)
    fill_light = bpy.data.objects.new("FillLight", fill_light_data)
    scene.collection.objects.link(fill_light)
    fill_light.rotation_euler = (math.radians(-60), math.radians(10), math.radians(140))
    
    # 3. Camera
    cam_data = bpy.data.cameras.new("RenderCam")
    cam_data.lens = 50
    cam_obj = bpy.data.objects.new("RenderCam", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    
    # Framed 45 deg beauty angle
    cam_obj.location = (14.0, -15.0, 10.5)
    
    # Look at mountain center
    target = Vector((0.0, 0.0, 3.8))
    direction = target - cam_obj.location
    rot_quat = direction.to_track_quat('-Z', 'Y')
    cam_obj.rotation_euler = rot_quat.to_euler()
    
    bpy.ops.render.render(write_still=True)
    print(f"[BLENDER RENDER COMPLETE] {output_path}")

if __name__ == "__main__":
    build_stylized_mountain()
    render_preview(r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_mountain_render.png")
