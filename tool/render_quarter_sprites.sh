#!/usr/bin/env bash
set -euo pipefail

ROOT='/Users/jogyeong-il/Documents/New project/Side/new_game'
SCRIPT="$ROOT/tool/render_quarter_sprite.py"
SRC="$ROOT/assets/raw/quaternius/cute_monsters_pack/glTF"
DST="$ROOT/assets/sprites/quarter"

render() {
  local model="$1"
  local out="$2"
  blender -b -P "$SCRIPT" -- "$SRC/$model" "$DST/$out" 512 >/tmp/blender_${out}.log 2>&1
  echo "Rendered $model -> $out"
}

render 'Deer.gltf' 'player.png'
render 'Bee.gltf' 'enemy_grunt.png'
render 'Skull.gltf' 'enemy_brute.png'
render 'Cthulhu.gltf' 'enemy_elite.png'
render 'Demon.gltf' 'enemy_boss.png'

echo 'Done.'
