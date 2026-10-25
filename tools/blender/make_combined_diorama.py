import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color, roughness=0.5, metallic=0.0, transmission=0.0, emission=None):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
        try:
            if transmission > 0:
                bsdf.inputs['Transmission Weight'].default_value = transmission
                bsdf.inputs['IOR'].default_value = 1.333
        except:
            pass
        if emission:
            try:
                bsdf.inputs['Emission Color'].default_value = emission
                bsdf.inputs['Emission Strength'].default_value = 1.8
            except:
                pass
    return mat

def build_diorama():
    reset_scene()

    # Materials
    m_grass = create_mat("M_LushGrass", (0.28, 0.65, 0.18, 1.0), roughness=0.8)
    m_sand = create_mat("M_GoldenSand", (0.94, 0.86, 0.55, 1.0), roughness=0.75)
    m_water = create_mat("M_TropicalWater", (0.05, 0.72, 0.88, 0.85), roughness=0.15, transmission=0.7)
    m_rock_dark = create_mat("M_RockDark", (0.32, 0.35, 0.38, 1.0), roughness=0.85)
    m_rock_light = create_mat("M_RockLight", (0.52, 0.54, 0.56, 1.0), roughness=0.75)
    m_snow = create_mat("M_Snow", (0.95, 0.97, 1.0, 1.0), roughness=0.35)
    m_pine = create_mat("M_PineFoliage", (0.08, 0.34, 0.14, 1.0), roughness=0.7)
    m_wood = create_mat("M_WoodTimber", (0.38, 0.22, 0.12, 1.0), roughness=0.85)
    m_gold = create_mat("M_PureGold", (1.0, 0.84, 0.12, 1.0), roughness=0.2, metallic=0.92)
    m_turq = create_mat("M_TurquoiseDome", (0.04, 0.75, 0.88, 1.0), roughness=0.3)
    m_red_roof = create_mat("M_BerlinRedRoof", (0.88, 0.20, 0.18, 1.0), roughness=0.55)
    m_white_marble = create_mat("M_WhiteMarble", (0.95, 0.94, 0.92, 1.0), roughness=0.35)
    m_sandstone = create_mat("M_Sandstone", (0.86, 0.78, 0.65, 1.0), roughness=0.78)

    scene_root = bpy.data.objects.new("Diorama_Root", None)
    bpy.context.scene.collection.objects.link(scene_root)

    # 1. Base Island Terrain with natural shoreline and river
    # Main grass meadow plane
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=16.0, depth=1.2, location=(0, 0, 0.6))
    island = bpy.context.active_object
    island.name = "IslandBase"
    island.data.materials.append(m_grass)
    island.parent = scene_root

    # Beach shoreline skirt
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=17.5, depth=0.6, location=(0, 0, 0.3))
    beach = bpy.context.active_object
    beach.name = "BeachSkirt"
    beach.data.materials.append(m_sand)
    beach.parent = scene_root

    # Tropical Water Plane
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=24.0, depth=0.4, location=(0, 0, 0.2))
    water = bpy.context.active_object
    water.name = "LagoonWater"
    water.data.materials.append(m_water)
    water.parent = scene_root

    # 2. Craggy Layered Mountain behind Samarkand (Positioned at West/Top-West)
    mnt_root = bpy.data.objects.new("Mountain_Rocky_Showcase", None)
    mnt_root.location = (-9.5, 4.5, 1.2)
    mnt_root.scale = (0.9, 0.9, 0.9)
    bpy.context.scene.collection.objects.link(mnt_root)
    mnt_root.parent = scene_root

    peaks = [
        (0.0, 0.0, 4.5, 8.5, 8, 6.4),
        (-2.8, 1.0, 3.2, 6.4, 7, 4.8),
        (2.5, -0.6, 3.4, 5.8, 7, 4.4),
    ]
    for p_idx, (px, py, pr, ph, psides, psnow) in enumerate(peaks):
        bm = bmesh.new()
        tiers = [
            (0.0, pr * 1.05),
            (ph * 0.32, pr * 0.75),
            (ph * 0.62, pr * 0.48),
            (ph * 0.85, pr * 0.24),
            (ph * 1.00, 0.06)
        ]
        prev_verts = []
        for t_idx, (tz, tr) in enumerate(tiers):
            layer_verts = []
            for s in range(psides):
                ang = (s / psides) * 2.0 * math.pi + t_idx * 0.25
                jitter = 1.0 + 0.16 * math.sin(s * 2.8 + t_idx * 1.4)
                vx = px + math.cos(ang) * tr * jitter
                vy = py + math.sin(ang) * tr * jitter
                v = bm.verts.new((vx, vy, tz))
                layer_verts.append(v)
            if prev_verts:
                for s in range(psides):
                    sn = (s + 1) % psides
                    bm.faces.new((prev_verts[s], prev_verts[sn], layer_verts[sn], layer_verts[s]))
            prev_verts = layer_verts
        summit = bm.verts.new((px, py, ph + 0.2))
        for s in range(psides):
            sn = (s + 1) % psides
            bm.faces.new((prev_verts[s], prev_verts[sn], summit))
        mesh = bpy.data.meshes.new(f"PeakMesh_{p_idx}")
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons: poly.use_smooth = False
        p_obj = bpy.data.objects.new(f"MntPeak_{p_idx}", mesh)
        p_obj.data.materials.append(m_rock_light)
        p_obj.data.materials.append(m_snow)
        for poly in p_obj.data.polygons:
            cz = sum(p_obj.data.vertices[v].co.z for v in poly.vertices) / len(poly.vertices)
            if cz >= psnow: poly.material_index = 1
        bpy.context.scene.collection.objects.link(p_obj)
        p_obj.parent = mnt_root

    # 3. Fairytale Berlin Castle (Top-Left)
    berlin_root = bpy.data.objects.new("Castle_Berlin_Showcase", None)
    berlin_root.location = (-4.8, 6.2, 1.2)
    berlin_root.scale = (0.75, 0.75, 0.75)
    berlin_root.rotation_euler = (0, 0, math.radians(25))
    bpy.context.scene.collection.objects.link(berlin_root)
    berlin_root.parent = scene_root

    # Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    b_pl = bpy.context.active_object
    b_pl.scale = (6.5, 5.5, 0.8)
    b_pl.data.materials.append(m_rock_dark)
    b_pl.parent = berlin_root

    # Keep & Roof
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.2))
    b_keep = bpy.context.active_object
    b_keep.scale = (3.8, 3.2, 2.6)
    b_keep.data.materials.append(m_white_marble)
    b_keep.parent = berlin_root

    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=2.8, depth=2.4, location=(0, 0, 4.4))
    b_roof = bpy.context.active_object
    b_roof.rotation_euler = (0, 0, math.radians(45))
    b_roof.data.materials.append(m_red_roof)
    b_roof.parent = berlin_root

    # Central High Spire
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.7, depth=2.8, location=(0, 0, 5.8))
    b_ctow = bpy.context.active_object
    b_ctow.data.materials.append(m_white_marble)
    b_ctow.parent = berlin_root

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.9, depth=3.2, location=(0, 0, 8.4))
    b_cspire = bpy.context.active_object
    b_cspire.data.materials.append(m_red_roof)
    b_cspire.parent = berlin_root

    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.18, location=(0, 0, 10.1))
    b_cfin = bpy.context.active_object
    b_cfin.data.materials.append(m_gold)
    b_cfin.parent = berlin_root

    # 4 Corner Towers
    for cx, cy in [(-2.2, -1.8), (2.2, -1.8), (-2.2, 1.8), (2.2, 1.8)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.7, depth=3.8, location=(cx, cy, 2.6))
        ct = bpy.context.active_object
        ct.data.materials.append(m_white_marble)
        ct.parent = berlin_root

        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.88, depth=2.2, location=(cx, cy, 5.4))
        cr = bpy.context.active_object
        cr.data.materials.append(m_red_roof)
        cr.parent = berlin_root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.14, location=(cx, cy, 6.6))
        cb = bpy.context.active_object
        cb.data.materials.append(m_gold)
        cb.parent = berlin_root

    # 4. Registan Samarkand Palace (Mid-Left, in front of mountain)
    sam_root = bpy.data.objects.new("Castle_Samarkand_Showcase", None)
    sam_root.location = (-7.2, -0.8, 1.2)
    sam_root.scale = (0.75, 0.75, 0.75)
    sam_root.rotation_euler = (0, 0, math.radians(-15))
    bpy.context.scene.collection.objects.link(sam_root)
    sam_root.parent = scene_root

    # Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    s_pl = bpy.context.active_object
    s_pl.scale = (7.0, 5.8, 0.8)
    s_pl.data.materials.append(m_rock_dark)
    s_pl.parent = sam_root

    # Monumental Pishtaq Façade
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.4, 3.4))
    s_pish = bpy.context.active_object
    s_pish.scale = (3.8, 1.4, 4.8)
    s_pish.data.materials.append(m_sandstone)
    s_pish.parent = sam_root

    # Iwan blue arch niche
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.8, 2.8))
    s_arch = bpy.context.active_object
    s_arch.scale = (2.0, 0.8, 3.2)
    s_arch.data.materials.append(m_turq)
    s_arch.parent = sam_root

    # 2 Fluted Turquoise Melon Domes
    for dx in [-1.6, 1.6]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.88, depth=1.2, location=(dx, 0.8, 3.8))
        drum = bpy.context.active_object
        drum.data.materials.append(m_sandstone)
        drum.parent = sam_root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=8, radius=1.05, location=(dx, 0.8, 4.8))
        dome = bpy.context.active_object
        dome.scale = (1.0, 1.0, 1.35)
        dome.data.materials.append(m_turq)
        dome.parent = sam_root

        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.35, depth=0.75, location=(dx, 0.8, 6.2))
        dtip = bpy.context.active_object
        dtip.data.materials.append(m_turq)
        dtip.parent = sam_root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.14, location=(dx, 0.8, 6.7))
        fin = bpy.context.active_object
        fin.data.materials.append(m_gold)
        fin.parent = sam_root

    # Twin Minarets
    for mx in [-2.2, 2.2]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.48, depth=5.0, location=(mx, -1.9, 3.8))
        minar = bpy.context.active_object
        minar.data.materials.append(m_sandstone)
        minar.parent = sam_root

        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.68, depth=0.32, location=(mx, -1.9, 6.4))
        mbal = bpy.context.active_object
        mbal.data.materials.append(m_gold)
        mbal.parent = sam_root

        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.52, depth=1.2, location=(mx, -1.9, 7.5))
        mcap = bpy.context.active_object
        mcap.data.materials.append(m_turq)
        mcap.parent = sam_root

    # 5. Opulent Dubai Palace (Bottom-Right)
    dubai_root = bpy.data.objects.new("Castle_Dubai_Showcase", None)
    dubai_root.location = (6.5, -4.8, 1.2)
    dubai_root.scale = (0.75, 0.75, 0.75)
    dubai_root.rotation_euler = (0, 0, math.radians(-35))
    bpy.context.scene.collection.objects.link(dubai_root)
    dubai_root.parent = scene_root

    # Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
    d_pl = bpy.context.active_object
    d_pl.scale = (7.5, 6.5, 0.8)
    d_pl.data.materials.append(m_white_marble)
    d_pl.parent = dubai_root

    # Tier 1 & 2 body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.2))
    d_b1 = bpy.context.active_object
    d_b1.scale = (5.2, 4.4, 2.2)
    d_b1.data.materials.append(m_white_marble)
    d_b1.parent = dubai_root

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.6))
    d_b2 = bpy.context.active_object
    d_b2.scale = (3.6, 3.0, 1.0)
    d_b2.data.materials.append(m_white_marble)
    d_b2.parent = dubai_root

    # Central Gilded Onion Dome
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=1.2, depth=0.9, location=(0, 0, 4.6))
    d_drum = bpy.context.active_object
    d_drum.data.materials.append(m_white_marble)
    d_drum.parent = dubai_root

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=1.4, location=(0, 0, 5.6))
    d_dome = bpy.context.active_object
    d_dome.scale = (1.0, 1.0, 1.35)
    d_dome.data.materials.append(m_gold)
    d_dome.parent = dubai_root

    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.55, depth=1.1, location=(0, 0, 7.2))
    d_tip = bpy.context.active_object
    d_tip.data.materials.append(m_gold)
    d_tip.parent = dubai_root

    bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.18, location=(0, 0, 8.4))
    d_fin = bpy.context.active_object
    d_fin.data.materials.append(m_gold)
    d_fin.parent = dubai_root

    # 4 Corner Kiosks with Small Gold Domes
    for kx, ky in [(-2.4, -2.0), (2.4, -2.0), (-2.4, 2.0), (2.4, 2.0)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(kx, ky, 2.2))
        kt = bpy.context.active_object
        kt.scale = (1.1, 1.1, 2.8)
        kt.data.materials.append(m_white_marble)
        kt.parent = dubai_root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.62, location=(kx, ky, 4.2))
        kdome = bpy.context.active_object
        kdome.scale = (1.0, 1.0, 1.25)
        kdome.data.materials.append(m_gold)
        kdome.parent = dubai_root

        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.28, depth=0.65, location=(kx, ky, 5.0))
        ktip = bpy.context.active_object
        ktip.data.materials.append(m_gold)
        ktip.parent = dubai_root

    # 6. Arched Wooden Bridge
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.8, 4.2, 1.4))
    bridge = bpy.context.active_object
    bridge.name = "WoodenBridge_Showcase"
    bridge.scale = (1.5, 3.8, 0.3)
    bridge.rotation_euler = (math.radians(12), 0, math.radians(-32))
    bridge.data.materials.append(m_wood)
    bridge.parent = scene_root

    # Bridge Railings
    for r_side in [-0.75, 0.75]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.8 + r_side * 0.8, 4.2, 1.8))
        rail = bpy.context.active_object
        rail.scale = (0.1, 3.8, 0.4)
        rail.rotation_euler = (math.radians(12), 0, math.radians(-32))
        rail.data.materials.append(m_wood)
        rail.parent = scene_root

    # 7. Faceted Coastal Rocks & Boulders in the Turquoise Water (Matching Circle 4)
    water_rocks = [
        (-4.0, -11.0, 0.5, 1.8, 1.1),
        (-2.2, -12.5, 0.4, 2.2, 1.4),
        (-5.5, -9.5, 0.3, 1.4, 0.9),
        (2.0, -13.0, 0.4, 1.9, 1.2),
        (5.0, -11.5, 0.5, 2.4, 1.5),
        (-8.0, -8.0, 0.6, 2.0, 1.3),
        (10.5, -3.0, 0.5, 2.1, 1.2),
        (-11.0, 0.5, 0.6, 2.5, 1.6),
    ]
    for r_idx, (rx, ry, rz, rr, rh) in enumerate(water_rocks):
        bpy.ops.mesh.primitive_cylinder_add(vertices=7, radius=rr, depth=rh, location=(rx, ry, rz))
        rock = bpy.context.active_object
        rock.name = f"WaterRock_{r_idx}"
        rock.rotation_euler = (math.radians(15), math.radians(25), math.radians(r_idx * 40))
        for poly in rock.data.polygons: poly.use_smooth = False
        rock.data.materials.append(m_rock_dark)
        rock.parent = scene_root

    # 8. Clustered Stylized Pine Trees across the meadow
    trees_pos = [
        (-7.5, 3.2, 1.2), (-6.5, 4.5, 1.2), (-8.2, 2.0, 1.2),
        (-3.0, 3.5, 1.2), (-2.0, 2.0, 1.2), (-1.5, 5.5, 1.2),
        (2.5, 2.0, 1.2), (3.8, 0.5, 1.2), (1.5, -1.0, 1.2),
        (4.5, -2.5, 1.2), (3.0, -4.0, 1.2), (5.5, -6.5, 1.2),
        (-2.5, -3.5, 1.2), (-4.5, -5.0, 1.2), (-6.0, -4.0, 1.2),
    ]
    for t_idx, (tx, ty, tz) in enumerate(trees_pos):
        bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=0.15, depth=0.8, location=(tx, ty, tz + 0.4))
        trunk = bpy.context.active_object
        trunk.data.materials.append(m_wood)
        trunk.parent = scene_root

        for c in range(3):
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.85 - c * 0.2, depth=0.9, location=(tx, ty, tz + 0.8 + c * 0.6))
            cone = bpy.context.active_object
            cone.data.materials.append(m_pine)
            cone.parent = scene_root

    return scene_root

def render_diorama(output_path):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 28
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    scene.render.filepath = output_path

    # Lighting setup (Golden warm sun + Caribbean sky fill)
    sun_data = bpy.data.lights.new(name="SunKey", type='SUN')
    sun_data.energy = 5.2
    sun_data.color = (1.0, 0.97, 0.88)
    sun = bpy.data.objects.new("SunKey", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(52), math.radians(22), math.radians(-32))

    fill_data = bpy.data.lights.new(name="SkyFill", type='SUN')
    fill_data.energy = 2.2
    fill_data.color = (0.50, 0.82, 1.0)
    fill = bpy.data.objects.new("SkyFill", fill_data)
    scene.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(-48), math.radians(12), math.radians(145))

    # Camera at framed diorama vista angle
    cam_data = bpy.data.cameras.new("DioramaCam")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new("DioramaCam", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (0.0, -25.0, 20.0)

    target = Vector((0.0, 0.0, 2.0))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    bpy.ops.render.render(write_still=True)
    print(f"[COMBINED DIORAMA RENDER COMPLETE] {output_path}")

if __name__ == "__main__":
    build_diorama()
    render_diorama(r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_diorama_showcase.png")
