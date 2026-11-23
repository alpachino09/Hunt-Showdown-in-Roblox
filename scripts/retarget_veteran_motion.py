"""Sample the CC0 Quaternius motions into the authored Veteran R15 joint space.

Run in factory-startup Blender with --python-exit-code 1 and this script.
Output uses in-place transforms. The Humanoid owns movement.
"""
import json
from math import ceil
from pathlib import Path
from statistics import median

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
MOTIONS = ROOT / "assets" / "animations" / "Locomotion"
REST = json.loads((ROOT / "assets/characters/Veteran/rest-pose.json").read_text())
RATE = 24

# Source forward is Blender -Y, and its .L side points along +X.
TO_ROBLOX = Matrix(((-1,0,0), (0,0,1), (0,1,0)))
BODY = {"LowerTorso": "DEF-hips", "UpperTorso": "DEF-spine.003", "Head": "DEF-head"}
for side, tag in (("Left", ".L"), ("Right", ".R")):
    for part, source in (("UpperArm", "upper_arm"), ("LowerArm", "forearm"), ("Hand", "hand"),
                         ("UpperLeg", "thigh"), ("LowerLeg", "shin"), ("Foot", "foot")):
        BODY[side + part] = "DEF-" + source + tag

CLIPS = {
    "Idle": ("Idle_Loop", True),
    "Walk": ("Walk_Loop", True),
    "Jog": ("Jog_Fwd_Loop", True),
    "Sprint": ("Sprint_Loop", True),
    "CrouchIdle": ("Crouch_Idle_Loop", True),
    "CrouchWalk": ("Crouch_Fwd_Loop", True),
    "Jump": ("Jump_Start", False),
    "Air": ("Jump_Loop", True),
    "Land": ("Jump_Land", False),
}


def set_frame(scene, frame):
    integral = int(frame)
    scene.frame_set(integral, subframe=frame - integral)


def frames():
    bpy.ops.import_scene.gltf(filepath=str(MOTIONS / "Quaternius-Standard-source.glb"))
    source = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
    actions = {action.name: action for action in bpy.data.actions}
    source.animation_data_clear()
    animation = source.animation_data_create()
    scene = bpy.context.scene
    scene_rate = scene.render.fps / scene.render.fps_base
    neutral = actions["Idle_Loop"]
    animation.action = neutral
    animation.action_slot = neutral.slots[0]
    set_frame(scene, neutral.frame_range[0])
    bones = source.pose.bones
    reference = {part: (TO_ROBLOX @ bones[tag].matrix.to_3x3()).to_quaternion()
                 for part, tag in BODY.items()}
    neutral_hip = bones[BODY["LowerTorso"]].head.z
    height_scale = (REST["joints"]["LeftHip"][2][1] - .4) / (neutral_hip - .106)
    next_joints = {
        REST["joints"][name][0]: Vector(REST["joints"][name][2])
        for name in ("LeftElbow", "LeftWrist", "RightElbow", "RightWrist", "LeftKnee",
                     "LeftAnkle", "RightKnee", "RightAnkle")
    }
    directions = {}
    for _, part, start in REST["joints"].values():
        if part in next_joints:
            standard = reference[part] @ Vector((0,1,0))
            directions[part] = standard.rotation_difference((next_joints[part] - Vector(start)).normalized())

    outputs = {}
    for name, (source_name, repeat) in CLIPS.items():
        act = actions[source_name]
        animation.action = act
        animation.action_slot = act.slots[0]
        begin, end = act.frame_range
        duration = (end - begin) / scene_rate
        steps = ceil(duration * RATE)
        track, foot_heads = [], []
        previous_rotations = {}
        for index in range(steps + 1):
            set_frame(scene, begin + (end-begin)*index/steps)
            world = {}
            for part, tag in BODY.items():
                rotation = (TO_ROBLOX @ bones[tag].matrix.to_3x3()).to_quaternion()
                # Convert global rotations to changes around the target's calibrated rest direction.
                delta = rotation @ reference[part].inverted()
                if part in directions:
                    correction = directions[part]
                    delta = correction @ delta @ correction.inverted()
                world[part] = delta.normalized()
            root_y = (bones[BODY["LowerTorso"]].head.z - neutral_hip) * height_scale
            record = [round(max(-1.22, min(.27 if name == "Air" else .52, root_y)), 5)]
            for joint, (parent, child, _) in REST["joints"].items():
                rotation = world[parent].inverted() @ world[child] if parent in world else world[child]
                rotation.normalize()
                if joint in previous_rotations and previous_rotations[joint].dot(rotation) < 0:
                    rotation.negate()
                previous_rotations[joint] = rotation
                record.extend(round(v, 6) for v in (rotation.x, rotation.y, rotation.z, rotation.w))
            track.append(record)
            foot_heads.append([TO_ROBLOX @ bones[BODY[side+"Foot"]].head for side in ("Left","Right")])

        ground = [min(frame[side].y for frame in foot_heads) for side in (0,1)]
        stance_speeds = []
        contacts = []
        for i, sample in enumerate(foot_heads):
            contact = []
            for side in (0,1):
                vertical_gap = sample[side].y - ground[side]
                grounded = max(0, min(1, (.063 - vertical_gap) / .037))
                contact.append(round(grounded,3))
                if grounded > .82 and i > 0:
                    backwards = (sample[side].z-foot_heads[i-1][side].z) * steps/duration
                    if backwards > .045:
                        stance_speeds.append(backwards*height_scale)
            contacts.append(contact)
        pace = median(stance_speeds) if stance_speeds else 0
        if repeat:
            track[-1] = track[0][:]
            contacts[-1] = contacts[0][:]
        outputs[name] = {
            "source": source_name, "duration": round(duration,5), "loop": repeat,
            "pace": round(pace,4), "contact": contacts, "frames": track,
        }
        print(name, source_name, len(track), round(duration,3), round(pace,2))
    return {"joints": list(REST["joints"]), "clips": outputs}


if __name__ == "__main__":
    (MOTIONS / "veteran-motion.json").write_text(json.dumps(frames(), separators=(",",":")) + "\n")
