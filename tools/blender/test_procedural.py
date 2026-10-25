import bpy

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def test_procedural_shaders():
    reset()

    # 1. Procedural Stylized Roof Tile Material
    mat_roof = bpy.data.materials.new(name="M_StylizedRoofTiles")
    mat_roof.use_nodes = True
    nt = mat_roof.node_tree
    nt.nodes.clear()

    out_node = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    
    # Brick texture configured for red terracotta scalloped shingles
    brick = nt.nodes.new("ShaderNodeTexBrick")
    brick.inputs['Color1'].default_value = (0.92, 0.22, 0.16, 1.0) # warm terracotta
    brick.inputs['Color2'].default_value = (0.78, 0.15, 0.12, 1.0) # deep red
    brick.inputs['Mortar'].default_value = (0.25, 0.08, 0.06, 1.0) # dark mortar
    brick.inputs['Scale'].default_value = 12.0
    brick.inputs['Mortar Size'].default_value = 0.025
    brick.inputs['Bias'].default_value = 0.2

    # Connect to base color and roughness
    nt.links.new(brick.outputs['Color'], bsdf.inputs['Base Color'])
    
    # Subtle bump from mortar
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs['Strength'].default_value = 0.35
    nt.links.new(brick.outputs['Color'], bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    
    nt.links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])

    # 2. Procedural Stylized Stone Brick Material
    mat_stone = bpy.data.materials.new(name="M_StylizedStoneBrick")
    mat_stone.use_nodes = True
    nt2 = mat_stone.node_tree
    nt2.nodes.clear()

    out2 = nt2.nodes.new("ShaderNodeOutputMaterial")
    bsdf2 = nt2.nodes.new("ShaderNodeBsdfPrincipled")
    
    brick2 = nt2.nodes.new("ShaderNodeTexBrick")
    brick2.inputs['Color1'].default_value = (0.92, 0.88, 0.82, 1.0) # cream stone
    brick2.inputs['Color2'].default_value = (0.80, 0.76, 0.70, 1.0) # shaded stone
    brick2.inputs['Mortar'].default_value = (0.45, 0.42, 0.38, 1.0) # grey mortar
    brick2.inputs['Scale'].default_value = 8.0
    brick2.inputs['Mortar Size'].default_value = 0.03

    nt2.links.new(brick2.outputs['Color'], bsdf2.inputs['Base Color'])
    bump2 = nt2.nodes.new("ShaderNodeBump")
    bump2.inputs['Strength'].default_value = 0.4
    nt2.links.new(brick2.outputs['Color'], bump2.inputs['Height'])
    nt2.links.new(bump2.outputs['Normal'], bsdf2.inputs['Normal'])
    nt2.links.new(bsdf2.outputs['BSDF'], out2.inputs['Surface'])

    # Test objects
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=(-1.5, 0, 1.0))
    c1 = bpy.context.active_object
    c1.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=1.5, depth=2.5, location=(1.5, 0, 1.25))
    c2 = bpy.context.active_object
    c2.data.materials.append(mat_roof)

    # Ground
    bpy.ops.mesh.primitive_plane_add(size=15, location=(0, 0, 0))
    g = bpy.context.active_object
    mat_g = bpy.data.materials.new("M_G")
    mat_g.use_nodes = True
    mat_g.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.28, 0.55, 0.20, 1.0)
    g.data.materials.append(mat_g)

    # Render settings
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.filepath = r"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2\blender_procedural_test.png"

    # Lights
    sun = bpy.data.lights.new("Sun", 'SUN')
    sun.energy = 4.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (0.8, 0.2, -0.6)

    cam = bpy.data.cameras.new("Cam")
    cam_obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    cam_obj.location = (0, -6, 3.5)
    cam_obj.rotation_euler = (1.1, 0, 0)

    bpy.ops.render.render(write_still=True)
    print("TEST_COMPLETE")

if __name__ == "__main__":
    test_procedural_shaders()
