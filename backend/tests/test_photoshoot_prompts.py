"""Unit tests for photoshoot prompt assembly (no Gemini/Supabase)."""

from __future__ import annotations

import unittest

from app.services.photoshoot_prompts import (
    build_photoshoot_frame_prompt,
    build_series_anti_duplicate_rules,
    build_series_continuation_frame_composition,
    build_series_continuation_reference_prompt,
)
from app.services.photoshoot_styles import PHOTOSHOOT_STYLES


class PhotoshootContinuationPromptTests(unittest.TestCase):
    style = PHOTOSHOOT_STYLES["studio_portrait"]

    def test_frame_one_continuation_contains_anti_duplicate_rules(self) -> None:
        prompt = build_series_continuation_reference_prompt("identity_anchor", frame_index=1)

        self.assertIn("style reference only", prompt.lower())
        self.assertIn("do not recreate image 2", prompt.lower())
        self.assertIn("do not copy the same pose", prompt.lower())
        self.assertIn("clearly different photo", prompt.lower())
        self.assertIn("another shot from the same professional photoshoot", prompt.lower())
        self.assertIn("three different shots", prompt.lower())

    def test_frame_two_continuation_contains_anti_duplicate_rules(self) -> None:
        prompt = build_series_continuation_reference_prompt("identity_anchor", frame_index=2)

        self.assertIn("style anchor only", prompt.lower())
        self.assertIn("do not copy pose, crop, camera angle", prompt.lower())
        self.assertIn("change at least 3 visual elements", prompt.lower())

    def test_frame_one_and_two_have_different_composition_instructions(self) -> None:
        frame_one = build_series_continuation_frame_composition(1)
        frame_two = build_series_continuation_frame_composition(2)

        self.assertIn("three-quarter", frame_one.lower())
        self.assertIn("medium shot", frame_one.lower())
        self.assertIn("waist-up", frame_two.lower())
        self.assertIn("wider portrait", frame_two.lower())
        self.assertNotEqual(frame_one, frame_two)

    def test_built_frame_prompts_include_continuation_for_identity_anchor(self) -> None:
        frame_one_prompt = build_photoshoot_frame_prompt(
            "studio_portrait",
            self.style,
            frame_index=1,
            output_count=3,
            series_reference_mode="identity_anchor",
        )
        frame_two_prompt = build_photoshoot_frame_prompt(
            "studio_portrait",
            self.style,
            frame_index=2,
            output_count=3,
            series_reference_mode="identity_anchor",
        )

        self.assertIn("Anti-duplicate rules", frame_one_prompt)
        self.assertIn("frame 2 of 3", frame_one_prompt.lower())
        self.assertIn("frame 3 of 3", frame_two_prompt.lower())
        self.assertNotEqual(frame_one_prompt, frame_two_prompt)

    def test_legacy_mode_has_no_continuation_block(self) -> None:
        prompt = build_photoshoot_frame_prompt(
            "studio_portrait",
            self.style,
            frame_index=1,
            output_count=3,
            series_reference_mode="legacy",
        )

        self.assertNotIn("Anti-duplicate rules", prompt)
        self.assertNotIn("Reference image roles", prompt)

    def test_anti_duplicate_rules_reference_style_image_label(self) -> None:
        identity_rules = build_series_anti_duplicate_rules(style_image_label="Image 2")
        anchor_rules = build_series_anti_duplicate_rules(style_image_label="Image 1")

        self.assertIn("Image 2 is a style reference only", identity_rules)
        self.assertIn("Image 1 is a style reference only", anchor_rules)


if __name__ == "__main__":
    unittest.main()
