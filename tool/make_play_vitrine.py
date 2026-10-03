#!/usr/bin/env python3
"""Compose Play Store phone vitrines from raw screenshots.

Reads play/gorseller/raw/{tr,en,ar}/0*.png and writes marketing frames to
play/gorseller/{tr,en,ar}/0*.png (same size as raw: 1170×2532).

Usage (from yakitla/ or anywhere):
  python3 tool/make_play_vitrine.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

try:
    import arabic_reshaper
    from bidi.algorithm import get_display
except ImportError:  # pragma: no cover
    arabic_reshaper = None
    get_display = None

ROOT = Path(__file__).resolve().parents[1]
GORSELLER = ROOT / "play" / "gorseller"
RAW = GORSELLER / "raw"

W, H = 1170, 2532
ACCENT = (31, 168, 85)  # #1FA855
ACCENT_DARK = (23, 138, 68)
INK = (17, 24, 39)
MUTED = (75, 85, 99)
GOLD = (245, 180, 55)
SOFT = (232, 247, 237)
WHITE = (255, 255, 255)

FONT_LATIN = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_AR = "/System/Library/Fonts/SFArabicRounded.ttf"
FALLBACK = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"

SLIDES = {
    "tr": [
        {
            "file": "01-home.png",
            "title": "Fiyatları anında gör",
            "accent_word": "anında",
            "sub": "Şehrindeki benzin ve motorin fiyatlarını tek ekranda karşılaştır.",
            "chips": ["Güncel fiyatlar", "İl / ilçe", "En uygun"],
        },
        {
            "file": "02-duel.png",
            "title": "Yol maliyetini hesapla",
            "accent_word": "hesapla",
            "sub": "Mesafe ve tüketime göre tahmini yakıt masrafını saniyede gör.",
            "chips": ["Mesafe", "Tüketim", "₺ maliyet"],
        },
        {
            "file": "03-setup.png",
            "title": "Dili sen seç",
            "accent_word": "sen",
            "sub": "Türkçe, İngilizce ve Arapça — uygulamayı kendine göre ayarla.",
            "chips": ["TR", "EN", "AR"],
        },
    ],
    "en": [
        {
            "file": "01-home.png",
            "title": "See fuel prices fast",
            "accent_word": "fast",
            "sub": "Compare gasoline and diesel prices in your city on one screen.",
            "chips": ["Live prices", "City / district", "Best deal"],
        },
        {
            "file": "02-duel.png",
            "title": "Estimate trip cost",
            "accent_word": "cost",
            "sub": "Enter distance and consumption — get a fuel cost estimate in seconds.",
            "chips": ["Distance", "Consumption", "₺ estimate"],
        },
        {
            "file": "03-setup.png",
            "title": "Pick your language",
            "accent_word": "language",
            "sub": "Turkish, English, and Arabic — set the app the way you like.",
            "chips": ["TR", "EN", "AR"],
        },
    ],
    "ar": [
        {
            "file": "01-home.png",
            "title": "أسعار الوقود فورًا",
            "accent_word": "فورًا",
            "sub": "قارن أسعار البنزين والديزل في مدينتك على شاشة واحدة.",
            "chips": ["أسعار حديثة", "مدينة / منطقة", "أفضل سعر"],
        },
        {
            "file": "02-duel.png",
            "title": "احسب تكلفة الرحلة",
            "accent_word": "تكلفة",
            "sub": "أدخل المسافة والاستهلاك واحصل على تقدير تكلفة الوقود فورًا.",
            "chips": ["مسافة", "استهلاك", "تقدير ₺"],
        },
        {
            "file": "03-setup.png",
            "title": "اختر لغتك",
            "accent_word": "لغتك",
            "sub": "التركية والإنجليزية والعربية — خصّص التطبيق كما تريد.",
            "chips": ["TR", "EN", "AR"],
        },
    ],
}


def font(size: int, arabic: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_AR if arabic else FONT_LATIN
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype(FALLBACK, size)


def shape(text: str, arabic: bool) -> str:
    if not arabic or not text:
        return text
    if arabic_reshaper is None or get_display is None:
        return text
    return get_display(arabic_reshaper.reshape(text))


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    cur = words[0]
    for w in words[1:]:
        trial = f"{cur} {w}"
        if draw.textlength(trial, font=fnt) <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def gradient_bg() -> Image.Image:
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        # airy mint sky → brighter field (closer to store-vitrine refs)
        if t < 0.55:
            u = t / 0.55
            r = int(214 + (245 - 214) * u)
            g = int(240 + (252 - 240) * u)
            b = int(220 + (236 - 220) * u)
        else:
            u = (t - 0.55) / 0.45
            r = int(245 + (186 - 245) * u)
            g = int(252 + (228 - 252) * u)
            b = int(236 + (170 - 236) * u)
        for x in range(W):
            wobble = math.sin(x / W * math.pi) * 8
            px[x, y] = (
                max(0, min(255, int(r + wobble))),
                max(0, min(255, int(g + wobble * 0.35))),
                max(0, min(255, int(b - wobble * 0.2))),
            )
    return img


def draw_landscape(base: Image.Image) -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # soft clouds
    for cx, cy, rw, rh, a in [
        (180, 520, 140, 50, 55),
        (420, 480, 180, 55, 40),
        (900, 540, 160, 48, 50),
        (1050, 700, 120, 40, 35),
    ]:
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=(255, 255, 255, a))

    # hills — more saturated like store showcase refs
    hill_y = int(H * 0.74)
    d.polygon(
        [
            (0, H),
            (0, hill_y + 40),
            (200, hill_y - 70),
            (460, hill_y + 40),
            (740, hill_y - 50),
            (980, hill_y + 50),
            (W, hill_y - 10),
            (W, H),
        ],
        fill=(120, 205, 145, 110),
    )
    d.polygon(
        [
            (0, H),
            (0, hill_y + 140),
            (280, hill_y + 70),
            (600, hill_y + 130),
            (900, hill_y + 60),
            (W, hill_y + 110),
            (W, H),
        ],
        fill=(70, 175, 110, 130),
    )

    def station(x: int, y: int, scale: float = 1.0) -> None:
        s = scale
        # canopy roof
        d.polygon(
            [
                (x, y + int(30 * s)),
                (x + int(20 * s), y),
                (x + int(170 * s), y),
                (x + int(190 * s), y + int(30 * s)),
            ],
            fill=(31, 168, 85, 200),
        )
        d.rectangle(
            [x + int(18 * s), y + int(30 * s), x + int(30 * s), y + int(120 * s)],
            fill=(23, 138, 68, 180),
        )
        d.rectangle(
            [x + int(160 * s), y + int(30 * s), x + int(172 * s), y + int(120 * s)],
            fill=(23, 138, 68, 180),
        )
        # pump body
        px0 = x + int(70 * s)
        d.rounded_rectangle(
            [px0, y + int(45 * s), px0 + int(48 * s), y + int(130 * s)],
            radius=8,
            fill=(245, 180, 55, 220),
        )
        d.rounded_rectangle(
            [px0 + int(8 * s), y + int(55 * s), px0 + int(40 * s), y + int(88 * s)],
            radius=6,
            fill=(255, 255, 255, 210),
        )
        # hose hint
        d.arc(
            [px0 + int(40 * s), y + int(70 * s), px0 + int(78 * s), y + int(120 * s)],
            start=270,
            end=90,
            fill=(23, 138, 68, 180),
            width=max(3, int(4 * s)),
        )

    station(40, hill_y + 10, 1.15)
    station(860, hill_y - 10, 1.0)

    def fuel_drop(cx: int, cy: int, r: int, col: tuple[int, int, int, int]) -> None:
        # classic drop: circle + triangle tip pointing down
        d.ellipse([cx - r, cy - r, cx + r, cy + int(r * 0.85)], fill=col)
        d.polygon(
            [
                (cx, cy + r + int(r * 0.85)),
                (cx - int(r * 0.75), cy + int(r * 0.2)),
                (cx + int(r * 0.75), cy + int(r * 0.2)),
            ],
            fill=col,
        )

    fuel_drop(1000, 920, 26, (*GOLD, 170))
    fuel_drop(110, 1180, 22, (*ACCENT, 150))
    fuel_drop(1020, 1550, 18, (*GOLD, 130))
    fuel_drop(70, 1680, 16, (*ACCENT, 120))

    # small location pin
    pin_x, pin_y = 1040, 1280
    d.ellipse([pin_x - 22, pin_y - 22, pin_x + 22, pin_y + 22], fill=(*ACCENT, 160))
    d.ellipse([pin_x - 8, pin_y - 8, pin_x + 8, pin_y + 8], fill=(255, 255, 255, 200))
    d.polygon(
        [(pin_x, pin_y + 48), (pin_x - 16, pin_y + 10), (pin_x + 16, pin_y + 10)],
        fill=(*ACCENT, 160),
    )

    return Image.alpha_composite(base.convert("RGBA"), layer).convert("RGB")


def rounded_phone(shot: Image.Image, phone_w: int = 780) -> Image.Image:
    """Frame screenshot in a dark phone bezel with shadow."""
    # shot is 1170x2532; crop status-bar-ish top slightly? keep full
    aspect = shot.height / shot.width
    screen_w = phone_w - 36
    screen_h = int(screen_w * aspect)
    # limit height so it fits canvas
    max_screen_h = 1480
    if screen_h > max_screen_h:
        screen_h = max_screen_h
        screen_w = int(screen_h / aspect)
        phone_w = screen_w + 36

    bezel = 18
    top_chrome = 42
    bottom_chrome = 28
    phone_h = screen_h + top_chrome + bottom_chrome
    phone = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(phone)

    # body
    d.rounded_rectangle([0, 0, phone_w - 1, phone_h - 1], radius=54, fill=(18, 20, 24, 255))
    # inner screen bg
    d.rounded_rectangle(
        [bezel, top_chrome - 8, phone_w - bezel - 1, phone_h - bottom_chrome],
        radius=40,
        fill=(0, 0, 0, 255),
    )

    # dynamic island
    island_w, island_h = 140, 36
    ix = (phone_w - island_w) // 2
    d.rounded_rectangle([ix, 14, ix + island_w, 14 + island_h], radius=18, fill=(0, 0, 0, 255))

    screen = shot.resize((screen_w, screen_h), Image.Resampling.LANCZOS).convert("RGBA")
    # mask rounded screen
    mask = Image.new("L", (screen_w, screen_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, screen_w - 1, screen_h - 1], radius=34, fill=255)
    sx = (phone_w - screen_w) // 2
    sy = top_chrome
    phone.paste(screen, (sx, sy), mask)

    # soft outer shadow
    shadow = Image.new("RGBA", (phone_w + 80, phone_h + 80), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([30, 40, phone_w + 50, phone_h + 60], radius=60, fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    out = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    out = Image.alpha_composite(out, shadow)
    out.paste(phone, (40, 20), phone)
    return out


def draw_title_block(
    canvas: Image.Image,
    title: str,
    accent_word: str,
    sub: str,
    chips: list[str],
    arabic: bool,
) -> int:
    """Draw title/sub/chips; return y just below the block."""
    d = ImageDraw.Draw(canvas)
    title_f = font(78 if not arabic else 70, arabic=arabic)
    sub_f = font(36 if not arabic else 34, arabic=arabic)
    chip_f = font(28, arabic=arabic)
    brand_f = font(34, arabic=False)

    pad_x = 72
    max_w = W - pad_x * 2
    y = 96

    # brand pill
    brand = "Yakıtla"
    bw = d.textlength(brand, font=brand_f) + 36
    d.rounded_rectangle([pad_x, y, pad_x + bw, y + 48], radius=24, fill=(*ACCENT, 255))
    d.text((pad_x + 18, y + 8), brand, font=brand_f, fill=WHITE)
    y += 78

    t = shape(title, arabic)
    lines = wrap(d, t, title_f, max_w)
    accent = shape(accent_word, arabic)

    for line in lines:
        # draw with accent word in green when present
        if accent and accent in line:
            parts = line.split(accent)
            x = pad_x if not arabic else W - pad_x
            # for simplicity LTR layout for mixed; Arabic lines drawn right-aligned whole
            if arabic:
                tw = d.textlength(line, font=title_f)
                d.text((W - pad_x - tw, y), line, font=title_f, fill=INK)
            else:
                x = pad_x
                for i, part in enumerate(parts):
                    if part:
                        d.text((x, y), part, font=title_f, fill=INK)
                        x += d.textlength(part, font=title_f)
                    if i < len(parts) - 1:
                        d.text((x, y), accent, font=title_f, fill=ACCENT)
                        x += d.textlength(accent, font=title_f)
        else:
            if arabic:
                tw = d.textlength(line, font=title_f)
                d.text((W - pad_x - tw, y), line, font=title_f, fill=INK)
            else:
                d.text((pad_x, y), line, font=title_f, fill=INK)
        y += 88

    y += 8
    sub_t = shape(sub, arabic)
    for line in wrap(d, sub_t, sub_f, max_w):
        if arabic:
            tw = d.textlength(line, font=sub_f)
            d.text((W - pad_x - tw, y), line, font=sub_f, fill=MUTED)
        else:
            d.text((pad_x, y), line, font=sub_f, fill=MUTED)
        y += 48

    y += 28
    x = pad_x
    for chip in chips:
        label = shape(chip, arabic)
        cw = d.textlength(label, font=chip_f) + 40
        if x + cw > W - pad_x:
            x = pad_x
            y += 56
        d.rounded_rectangle([x, y, x + cw, y + 46], radius=23, fill=SOFT)
        d.rounded_rectangle([x, y, x + cw, y + 46], radius=23, outline=ACCENT, width=2)
        tx = x + 20
        if arabic:
            tw = d.textlength(label, font=chip_f)
            tx = x + (cw - tw) / 2
        d.text((tx, y + 8), label, font=chip_f, fill=ACCENT_DARK)
        x += cw + 14

    return y + 70


def compose(lang: str, slide: dict) -> Image.Image:
    arabic = lang == "ar"
    raw_path = RAW / lang / slide["file"]
    if not raw_path.exists():
        raise FileNotFoundError(raw_path)

    canvas_rgba = draw_landscape(gradient_bg()).convert("RGBA")

    y_after = draw_title_block(
        canvas_rgba,
        slide["title"],
        slide.get("accent_word", ""),
        slide["sub"],
        slide.get("chips") or [],
        arabic=arabic,
    )

    shot = Image.open(raw_path).convert("RGBA")
    phone = rounded_phone(shot, phone_w=860)
    px = (W - phone.width) // 2
    py = min(max(y_after - 10, 580), H - phone.height + 80)
    if py + phone.height > H + 40:
        py = H - phone.height + 80
    canvas_rgba.alpha_composite(phone, (px, py))
    return canvas_rgba.convert("RGB")


def main() -> int:
    for lang, slides in SLIDES.items():
        out_dir = GORSELLER / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        for slide in slides:
            img = compose(lang, slide)
            dest = out_dir / slide["file"]
            img.save(dest, "PNG", optimize=True)
            print(f"wrote {dest.relative_to(ROOT)} {img.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
