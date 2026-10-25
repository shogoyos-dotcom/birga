import bpy
import os
import sys

sys.path.append(r"d:\antigravity\blender_assets")

def export_all():
    out_dir = r"d:\antigravity\blender_assets\fbx"
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    # 1. Export Mountain
    from make_mountain import build_stylized_mountain
    build_stylized_mountain()
    mnt_obj = bpy.data.objects.get("Mountain_Rocky_AAA")
    if mnt_obj:
        bpy.ops.object.select_all(action='DESELECT')
        mnt_obj.select_set(True)
        for child in mnt_obj.children_recursive:
            child.select_set(True)
        bpy.context.view_layer.objects.active = mnt_obj
        fbx_path = os.path.join(out_dir, "mountain_rocky.fbx")
        bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_scale_options='FBX_SCALE_ALL', bake_space_transform=True)
        print(f"Exported: {fbx_path}")

    # 2. Export Berlin Castle
    from make_berlin_castle import build_berlin_castle
    build_berlin_castle()
    b_obj = bpy.data.objects.get("Castle_Berlin_AAA")
    if b_obj:
        bpy.ops.object.select_all(action='DESELECT')
        b_obj.select_set(True)
        for child in b_obj.children_recursive:
            child.select_set(True)
        bpy.context.view_layer.objects.active = b_obj
        fbx_path = os.path.join(out_dir, "castle_berlin.fbx")
        bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_scale_options='FBX_SCALE_ALL', bake_space_transform=True)
        print(f"Exported: {fbx_path}")

    # 3. Export Samarkand Castle
    from make_samarkand_castle import build_samarkand_palace
    build_samarkand_palace()
    s_obj = bpy.data.objects.get("Castle_Samarkand_AAA")
    if s_obj:
        bpy.ops.object.select_all(action='DESELECT')
        s_obj.select_set(True)
        for child in s_obj.children_recursive:
            child.select_set(True)
        bpy.context.view_layer.objects.active = s_obj
        fbx_path = os.path.join(out_dir, "castle_samarkand.fbx")
        bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_scale_options='FBX_SCALE_ALL', bake_space_transform=True)
        print(f"Exported: {fbx_path}")

    # 4. Export Dubai Castle
    from make_dubai_castle import build_dubai_palace
    build_dubai_palace()
    d_obj = bpy.data.objects.get("Castle_Dubai_AAA")
    if d_obj:
        bpy.ops.object.select_all(action='DESELECT')
        d_obj.select_set(True)
        for child in d_obj.children_recursive:
            child.select_set(True)
        bpy.context.view_layer.objects.active = d_obj
        fbx_path = os.path.join(out_dir, "castle_dubai.fbx")
        bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_scale_options='FBX_SCALE_ALL', bake_space_transform=True)
        print(f"Exported: {fbx_path}")

    print("[ALL FBX EXPORTS SUCCESSFUL]")

if __name__ == "__main__":
    export_all()
