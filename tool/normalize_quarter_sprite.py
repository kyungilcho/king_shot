from __future__ import annotations

import sys
from pathlib import Path
from PIL import Image


def normalize(path: Path, out_size: int = 512, pad_ratio: float = 0.09) -> None:
    im = Image.open(path).convert('RGBA')
    alpha = im.getchannel('A')
    bbox = alpha.getbbox()
    if bbox is None:
        return

    x0, y0, x1, y1 = bbox
    w = x1 - x0
    h = y1 - y0
    pad_x = max(2, int(w * pad_ratio))
    pad_y = max(2, int(h * pad_ratio))

    crop_box = (
        max(0, x0 - pad_x),
        max(0, y0 - pad_y),
        min(im.width, x1 + pad_x),
        min(im.height, y1 + pad_y),
    )
    cropped = im.crop(crop_box)

    scale = min(out_size / cropped.width, out_size / cropped.height)
    new_w = max(1, int(round(cropped.width * scale)))
    new_h = max(1, int(round(cropped.height * scale)))
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new('RGBA', (out_size, out_size), (0, 0, 0, 0))
    offset = ((out_size - new_w) // 2, (out_size - new_h) // 2)
    canvas.alpha_composite(resized, dest=offset)
    canvas.save(path, format='PNG', compress_level=9)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
      print('Usage: normalize_quarter_sprite.py <png1> [png2 ...]')
      return 1
    for p in argv[1:]:
      normalize(Path(p))
      print(f'normalized: {p}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))
