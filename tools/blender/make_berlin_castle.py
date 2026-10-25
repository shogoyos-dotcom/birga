import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, roughness=0.6, metallic=0.0, emission=None):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
        if emission:
            # Blender 4.2 Principled BSDF emission inputs
            try:
                bsdf.inputs['Emission Color'].default_value = emission
                bsdf.inputs['Emission Strength'].default_value = 1.8
            except:
                pass
    return mat

def build_berlin_castle():
    reset_scene()
    
    # Stylized Palette
    mat_stone = create_mat("M_BerlinStone", (0.92, 0.88, 0.82, 1.0), roughness=0.75)
    mat_stone_dark = create_mat("M_BerlinStoneTrim", (0.76, 0.72, 0.68, 1.0), roughness=0.8)
    mat_roof_red = create_mat("M_BerlinRoofRed", (0.88, 0.20, 0.18, 1.0), roughness=0.55)
    mat_roof_dark = create_mat("M_BerlinRoofDark", (0.72, 0.14, 0.14, 1.0), roughness=0.6)
    mat_gold = create_mat("M_BerlinGold", (1.0, 0.82, 0.12, 1.0), roughness=0.3, metallic=0.85)
    mat_window = create_mat("M_BerlinWindow", (0.15, 0.25, 0.35, 1.0), roughness=0.2, emission=(1.0, 0.85, 0.45, 1.0))
    mat_wood = create_mat("M_BerlinWood", (0.38, 0.22, 0.12, 1.0), roughness=0.85)
    mat_banner = create_mat("M_BerlinBanner", (0.95, 0.15, 0.22, 1.0), roughness=0.6)

    root = bpy.data.objects.new("Castle_Berlin_AAA", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Main Stone Foundation Plinth (Stepped stone terrace)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    plinth = bpy.context.active_object
    plinth.name = "Plinth"
    plinth.scale = (7.5, 6.5, 0.8)
    plinth.data.materials.append(mat_stone_dark)
    plinth.parent = root

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.9))
    plinth2 = bpy.context.active_object
    plinth2.name = "Plinth_Tier2"
    plinth2.scale = (6.8, 5.8, 0.4)
    plinth2.data.materials.append(mat_stone)
    plinth2.parent = root

    # 2. Main Central Keep / Cathedral Body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.5))
    keep = bpy.context.active_object
    keep.name = "MainKeep"
    keep.scale = (4.2, 3.6, 2.8)
    keep.data.materials.append(mat_stone)
    keep.parent = root

    # 3. High Cathedral Steep Pitch Roof (Prism roof)
    # Model a steep pitched roof with gables
    bm = bmesh.new()
    rw = 2.2
    rl = 1.9
    rh = 2.4
    # 6 vertices for a triangular prism roof
    v1 = bm.verts.new((-rw, -rl, 0))
    v2 = bm.verts.new((rw, -rl, 0))
    v3 = bm.verts.new((rw, rl, 0))
    v4 = bm.verts.new((-rw, rl, 0))
    v5 = bm.verts.new((0, -rl, rh))
    v6 = bm.verts.new((0, rl, rh))
    # Gable ends and sloping roof faces
    bm.faces.new((v1, v2, v5)) # front gable
    bm.faces.new((v4, v6, v3)) # back gable
    bm.faces.new((v1, v5, v6, v4)) # left slope
    bm.faces.new((v2, v3, v6, v5)) # right slope
    bm.faces.new((v1, v4, v3, v2)) # bottom
    roof_mesh = bpy.data.meshes.new("MainRoofMesh")
    bm.to_mesh(roof_mesh)
    bm.free()
    main_roof = bpy.data.objects.new("MainRoof", roof_mesh)
    main_roof.location = (0, 0, 3.9)
    main_roof.data.materials.append(mat_roof_red)
    bpy.context.scene.collection.objects.link(main_roof)
    main_roof.parent = root

    # 4. Central Tower & Spire
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.9, depth=3.2, location=(0, 0, 5.2))
    cent_tower = bpy.context.active_object
    cent_tower.name = "CentralTower"
    cent_tower.data.materials.append(mat_stone)
    cent_tower.parent = root

    # Central Steep Spire
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.1, depth=3.6, location=(0, 0, 8.4))
    cent_spire = bpy.context.active_object
    cent_spire.name = "CentralSpire"
    cent_spire.data.materials.append(mat_roof_dark)
    cent_spire.parent = root

    # Spire Gold Finial and Cross
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.22, location=(0, 0, 10.3))
    finial = bpy.context.active_object
    finial.name = "SpireFinial"
    finial.data.materials.append(mat_gold)
    finial.parent = root

    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=0.8, location=(0, 0, 10.7))
    spire_rod = bpy.context.active_object
    spire_rod.data.materials.append(mat_gold)
    spire_rod.parent = root

    # 5. 4 Corner Towers with Conical Red Roofs and Gold Orbs
    corners = [
        (-2.6, -2.2, 0),
        (2.6, -2.2, 0),
        (-2.6, 2.2, 0),
        (2.6, 2.2, 0)
    ]
    for c_idx, (cx, cy, cz) in enumerate(corners):
        # Tower base
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.85, depth=4.2, location=(cx, cy, 2.8))
        tower = bpy.context.active_object
        tower.name = f"CornerTower_{c_idx}"
        tower.data.materials.append(mat_stone)
        tower.parent = root

        # Corbel cornice rim
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=1.02, depth=0.25, location=(cx, cy, 4.95))
        cornice = bpy.context.active_object
        cornice.data.materials.append(mat_stone_dark)
        cornice.parent = root

        # Conical Red Roof
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=1.08, depth=2.4, location=(cx, cy, 6.2))
        troof = bpy.context.active_object
        troof.name = f"TowerRoof_{c_idx}"
        troof.data.materials.append(mat_roof_red)
        troof.parent = root

        # Gold ball finial
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.18, location=(cx, cy, 7.5))
        tball = bpy.context.active_object
        tball.data.materials.append(mat_gold)
        tball.parent = root

        # Swallowtail flag
        bpy.ops.mesh.primitive_cylinder_add(vertices=4, radius=0.04, depth=1.1, location=(cx, cy, 8.0))
        flagpole = bpy.context.active_object
        flagpole.data.materials.append(mat_gold)
        flagpole.parent = root

        # Flag cloth
        bpy.ops.mesh.primitive_plane_add(size=0.6, location=(cx + 0.35, cy, 8.35))
        flag = bpy.context.active_object
        flag.rotation_euler = (math.radians(90), 0, 0)
        flag.scale = (1.2, 0.6, 1.0)
        flag.data.materials.append(mat_banner)
        flag.parent = root

    # 6. Front Entrance Gatehouse with Arched Portal and Wooden Gate
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.6, 1.8))
    gate = bpy.context.active_object
    gate.scale = (2.2, 1.4, 2.0)
    gate.data.materials.append(mat_stone)
    gate.parent = root

    # Arched portal recess
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.65, depth=0.6, location=(0, -3.2, 1.4))
    portal = bpy.context.active_object
    portal.rotation_euler = (math.radians(90), 0, 0)
    portal.data.materials.append(mat_wood)
    portal.parent = root

    # Gatehouse battlements
    for bx in [-0.8, -0.3, 0.3, 0.8]:
        bpy.ops.mesh.primitive_cube_add(size=0.3, location=(bx, -3.25, 2.9))
        merlon = bpy.context.active_object
        merlon.data.materials.append(mat_stone_dark)
        merlon.parent = root

    # Entrance staircase
    for st in range(3):
        sz = 0.2 + st * 0.18
        sy = -3.5 - st * 0.35
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, sy, sz))
        step = bpy.context.active_object
        step.scale = (1.8 - st * 0.2, 0.38, 0.18)
        step.data.materials.append(mat_stone_dark)
        step.parent = root

    # 7. Gothic Arched Windows with Warm Interior Glow
    win_coords = [
        # Front windows
        (-1.2, -1.82, 3.2), (1.2, -1.82, 3.2),
        (-1.2, -1.82, 2.2), (1.2, -1.82, 2.2),
        (0.0, -1.82, 3.6),
        # Side windows
        (-2.12, 0.0, 3.0), (2.12, 0.0, 3.0),
        (-2.12, -0.8, 3.0), (2.12, -0.8, 3.0),
        (-2.12, 0.8, 3.0), (2.12, 0.8, 3.0),
    ]
    for w_idx, (wx, wy, wz) in enumerate(win_coords):
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.22, depth=0.15, location=(wx, wy, wz))
        win = bpy.context.active_object
        win.rotation_euler = (math.radians(90) if abs(wy) > 1.0 else 0, math.radians(90) if abs(wy) <= 1.0 else 0, 0)
        win.scale = (1.0, 1.8, 1.0)
        win.data.materials.append(mat_window)
        win.parent = root

    # 8. Flying Buttresses on flanks
    for side in [-1, 1]:
        for bz in [-0.8, 0.8]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 2.3, bz, 1.6))
            buttr = bpy.context.active_object
            buttr.scale = (0.45, 0.45, 2.0)
            buttr.data.materials.append(mat_stone_dark)
            buttr.parent = root

            # Sloping arch support
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 2.15, bz, 2.7))
            arch = bpy.context.active_object
            arch.rotation_euler = (0, side * math.radians(35), 0)
            arch.scale = (0.28, 0.35, 1.1)
            arch.data.materials.append(mat_stone)
            arch.parent = root

    return root

def render_preview(output_path):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    scene.render.filepath = output_path
    
    # Floor
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    floor = bpy.context.active_object
    mat_floor = create_mat("M_StudioFloor", (0.35, 0.70, 0.28, 1.0), roughness=0.85)
    floor.data.materials.append(mat_floor)
    
    # Three-point studio lighting
    key_light_data = bpy.data.lights.new(name="SunKey", type='SUN')
    key_light_data.energy = 4.5
    key_light_data.color = (1.0, 0.97, 0.90)
    key_light = bpy.data.objects.new("SunKey", key_light_data)
    scene.collection.objects.link(key_light)
    key_light.rotation_euler = (math.radians(52), math.radians(18), math.radians(-35))
    
    fill_light_data = bpy.data.lights.new(name="SkyFill", type='SUN')
    fill_light_data.energy = 1.8
    fill_light_data.color = (0.60, 0.82, 1.0)
    fill_light = bpy.data.objects.new("SkyFill", fill_light_data)
    scene.collection.objects.link(fill_light)
    fill_light.rotation_euler = (math.radians(-55), math.radians(12), math.radians(145))
    
    # Camera
    cam_data = bpy.data.cameras.new("BerlinCam")
    cam_data.lens = 52
    cam_obj = bpy.data.objects.new("BerlinCam", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (11.5, -13.5, 9.2)
    
    target = Vector((0.0, 0.0, 4.2))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    
    bpy.ops.render.render(write_still=True)
    print(f"[BERLIN RENDER COMPLETE] {output_path}")

if __name__ == "__main__":
    build_berlin_castle()
    render_preview(r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_berlin_castle_render.png")
