#!/usr/bin/env python3
"""
Generate the pose-reference images for Picwoa's "gợi ý dáng" feature.

Reads the pose catalog (Picwoa/Resources/PoseSuggestions.json), asks an OpenAI
image model to draw each dáng once, and writes the result straight into the
asset catalog as <imageName>.imageset so the app picks it up with no extra work.

This runs OFFLINE, ONE TIME — the live app never calls an image model (too slow /
costly for a viewfinder). Re-run it only when you add/edit poses in the JSON.

Usage:
    export OPENAI_API_KEY=sk-...
    python3 scripts/generate_pose_images.py            # generate all (skip existing)
    python3 scripts/generate_pose_images.py --force    # regenerate everything
    python3 scripts/generate_pose_images.py --only any_portrait_classic
    OPENAI_IMAGE_MODEL=dall-e-3 python3 scripts/generate_pose_images.py

Stdlib only — no pip install required.
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Picwoa" / "Resources" / "PoseSuggestions.json"
ASSETS = ROOT / "Picwoa" / "Resources" / "Assets.xcassets"
ENDPOINT = "https://api.openai.com/v1/images/generations"

MODEL = os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1")

# Shared visual style — keep every reference figure consistent so the cards feel like
# one set. Tweak this string to change the look of the whole library at once.
STYLE = (
    "Clean modern pose-reference illustration of ONE single young adult, full figure, "
    "accurate natural human anatomy, soft even lighting, plain light-gray studio "
    "background, minimal flat shading, fashion lookbook reference style. "
    "No text, no watermark, no props unless described, exactly one person, "
    "vertical 9:16 composition, the pose clearly readable."
)

# Light scene hint so the dáng reads as fitting its intended setting,
# while keeping the background plain enough to work as a guide.
SCENE_HINT = {
    "outdoor": "Subtle outdoor daylight feel, airy and bright.",
    "indoor": "Subtle soft indoor light feel, cozy and warm.",
    "any": "Neutral studio feel.",
}


def build_prompt(pose: dict) -> str:
    scenes = pose.get("scenes", ["any"])
    hint = SCENE_HINT.get(scenes[0] if scenes else "any", SCENE_HINT["any"])
    coverage = pose.get("bodyCoverage", "full_body").replace("_", " ")
    return (
        f"{STYLE} {hint} "
        f"Framing: {coverage}. "
        f"The person is demonstrating this exact pose: {pose['description']}"
    )


def image_size() -> str:
    # Portrait. gpt-image-1 uses 1024x1536; dall-e-3 uses 1024x1792.
    return "1024x1792" if MODEL == "dall-e-3" else "1024x1536"


def request_image(prompt: str, api_key: str) -> bytes:
    body = {"model": MODEL, "prompt": prompt, "size": image_size(), "n": 1}
    # dall-e-3 needs an explicit b64 format; gpt-image-1 returns b64 by default
    # and rejects the response_format param.
    if MODEL == "dall-e-3":
        body["response_format"] = "b64_json"
        body["quality"] = "standard"
    else:
        body["quality"] = os.environ.get("OPENAI_IMAGE_QUALITY", "medium")

    req = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            payload = json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"  ✗ API error {e.code}: {detail}")

    b64 = payload["data"][0]["b64_json"]
    return base64.b64decode(b64)


def write_imageset(image_name: str, png: bytes) -> None:
    imageset = ASSETS / f"{image_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    (imageset / f"{image_name}.png").write_bytes(png)
    contents = {
        "images": [{"filename": f"{image_name}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Picwoa pose-reference images.")
    parser.add_argument("--force", action="store_true", help="Regenerate even if the imageset exists.")
    parser.add_argument("--only", help="Generate only this pose id.")
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without calling the API.")
    args = parser.parse_args()

    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key and not args.dry_run:
        print("Set OPENAI_API_KEY (or use --dry-run to preview prompts).", file=sys.stderr)
        return 1

    poses = json.loads(CATALOG.read_text())["poses"]
    if args.only:
        poses = [p for p in poses if p["id"] == args.only]
        if not poses:
            print(f"No pose with id '{args.only}'.", file=sys.stderr)
            return 1

    for pose in poses:
        name = pose["imageName"]
        prompt = build_prompt(pose)
        target = ASSETS / f"{name}.imageset" / f"{name}.png"

        if args.dry_run:
            print(f"\n[{pose['id']}] → {name}.png\n  {prompt}")
            continue
        if target.exists() and not args.force:
            print(f"• {name}: exists, skipping (use --force to regenerate).")
            continue

        print(f"⚙️  {pose['id']} → generating {name}.png …")
        png = request_image(prompt, api_key)
        write_imageset(name, png)
        print(f"  ✓ wrote {target.relative_to(ROOT)}")

    if not args.dry_run:
        print("\nDone. Run `xcodegen generate` if the catalog was just created, then build.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
