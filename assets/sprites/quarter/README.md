# Quarter View Sprite Slots (2.5D)

Drop rendered PNG sprites into this folder using the exact names below.

## Required for new pipeline
- `base.png`
- `player.png`
- `enemy_grunt.png`
- `enemy_brute.png`
- `enemy_elite.png`
- `enemy_boss.png`

## Blender export recommendation
- Camera: perspective, around 45deg tilt toward ground.
- Character facing: keep consistent (front-right or front-left).
- Render size:
  - player/enemy: 512x512
  - base/building: 1024x1024
- Background: transparent PNG.
- Pivot guide: feet/base touching bottom 25-30% area of image.

The game loads these sprites optionally. If a file is missing,
it falls back to built-in procedural rendering.
