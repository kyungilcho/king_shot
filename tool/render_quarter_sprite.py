import bpy
import math
import os
import sys
from mathutils import Vector


def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []
    if len(argv) < 2:
        raise SystemExit("Usage: blender -b -P render_quarter_sprite.py -- <input.gltf> <output.png> [size]")
    input_path = argv[0]
    output_path = argv[1]
    size = int(argv[2]) if len(argv) >= 3 else 512
    return input_path, output_path, size


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def setup_scene(size):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.compression = 15

    world = bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get('Background')
    if bg:
        bg.inputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
        bg.inputs[1].default_value = 1.0

    key_data = bpy.data.lights.new(name='SunKey', type='SUN')
    key_data.energy = 3.5
    key = bpy.data.objects.new(name='SunKey', object_data=key_data)
    scene.collection.objects.link(key)
    key.location = (6.0, -6.0, 8.0)
    key.rotation_euler = (math.radians(40), 0.0, math.radians(35))

    fill_data = bpy.data.lights.new(name='SunFill', type='SUN')
    fill_data.energy = 1.2
    fill = bpy.data.objects.new(name='SunFill', object_data=fill_data)
    scene.collection.objects.link(fill)
    fill.location = (-5.0, 5.0, 5.0)
    fill.rotation_euler = (math.radians(50), 0.0, math.radians(-140))

    return scene


def import_model(path):
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if not meshes:
        raise RuntimeError(f'No mesh found in {path}')
    return meshes


def compute_world_bounds(meshes):
    points = []
    for obj in meshes:
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    center = (min_v + max_v) * 0.5
    return center, points


def setup_camera(scene, center, points):
    cam_data = bpy.data.cameras.new('Camera')
    cam_data.type = 'ORTHO'
    cam = bpy.data.objects.new('Camera', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    view_dir = Vector((1.0, -1.0, 0.85)).normalized()
    cam.location = center + view_dir * 10.0
    cam.rotation_euler = (center - cam.location).to_track_quat('-Z', 'Y').to_euler()

    inv = cam.matrix_world.inverted()
    cam_points = [inv @ p for p in points]
    half_w = max(abs(p.x) for p in cam_points)
    half_h = max(abs(p.y) for p in cam_points)
    margin = 1.12
    cam_data.ortho_scale = max(half_w, half_h) * 2.0 * margin


def main():
    input_path, output_path, size = parse_args()
    reset_scene()
    scene = setup_scene(size)
    meshes = import_model(input_path)

    center, _ = compute_world_bounds(meshes)
    for obj in meshes:
        obj.location -= center

    center, points = compute_world_bounds(meshes)
    setup_camera(scene, center, points)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)
    print(f'Rendered {input_path} -> {output_path}')


if __name__ == '__main__':
    main()
