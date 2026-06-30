"""Unit tests for photoshoot prompt assembly (no Gemini/Supabase)."""

from __future__ import annotations

import unittest

from app.services.photoshoot_prompts import (
    build_identity_only_fallback_prompt_suffix,
    build_kie_photoshoot_frame_prompt,
    build_photoshoot_frame_prompt,
    build_safe_a_only_batch_frame_prompt,
    build_safe_continuation_fallback_prompt_suffix,
    build_safe_frame0_fallback_prompt,
    build_series_anti_duplicate_rules,
    build_series_continuation_frame_composition,
    build_series_continuation_reference_prompt,
    build_universal_photoshoot_diversity_rules,
    resolve_base_prompt,
    resolve_prompt_source,
)
from app.services.photoshoot_style_locks import (
    CUSTOM_PHOTOSHOOT_STYLE_ID,
    PHOTOSHOOT_STYLE_LOCKS,
    build_style_lock_prompt_block,
    get_safe_batch_hard_rule,
    get_style_lock,
)
from app.services.photoshoot_styles import PHOTOSHOOT_STYLES


class PhotoshootContinuationPromptTests(unittest.TestCase):
    style = PHOTOSHOOT_STYLES["studio_portrait"]

    def test_frame_one_continuation_contains_anti_duplicate_rules(self) -> None:
        prompt = build_series_continuation_reference_prompt(
            "identity_anchor",
            frame_index=1,
            client_style_id="studio_portrait",
        )

        self.assertIn("style reference only", prompt.lower())
        self.assertIn("do not recreate image 2", prompt.lower())
        self.assertIn("do not copy the same pose", prompt.lower())
        self.assertIn("clearly different photo", prompt.lower())
        self.assertIn("another shot from the same professional photoshoot", prompt.lower())
        self.assertIn("three different shots", prompt.lower())

    def test_frame_two_continuation_contains_anti_duplicate_rules(self) -> None:
        prompt = build_series_continuation_reference_prompt(
            "identity_anchor",
            frame_index=2,
            client_style_id="studio_portrait",
        )

        self.assertIn("style anchor only", prompt.lower())
        self.assertIn("image 3", prompt.lower())
        self.assertIn("avoid-copy reference only", prompt.lower())
        self.assertIn("do not copy its pose, crop, body angle", prompt.lower())
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

    def test_universal_diversity_rules_differ_by_frame_index(self) -> None:
        frame_zero = build_universal_photoshoot_diversity_rules(0, 3)
        frame_one = build_universal_photoshoot_diversity_rules(1, 3)
        frame_two = build_universal_photoshoot_diversity_rules(2, 3)

        self.assertIn("frame 1 of 3", frame_zero.lower())
        self.assertIn("three-quarter", frame_one.lower())
        self.assertIn("frame 3 of 3", frame_two.lower())
        self.assertIn("must differ from both frame 1 and frame 2", frame_two.lower())
        self.assertNotEqual(frame_zero, frame_one)
        self.assertNotEqual(frame_one, frame_two)

    def test_built_prompts_include_universal_diversity_for_any_style(self) -> None:
        for style_id in PHOTOSHOOT_STYLES:
            style = PHOTOSHOOT_STYLES[style_id]
            for frame_index in range(3):
                prompt = build_kie_photoshoot_frame_prompt(
                    style_id,
                    style,
                    frame_index=frame_index,
                    output_count=3,
                    series_reference_mode="identity_anchor",
                )
                self.assertIn(
                    "Universal photoshoot diversity rules",
                    prompt,
                    f"{style_id} frame {frame_index}",
                )
                self.assertIn(
                    "vertical portrait photo in 3:4 aspect ratio",
                    prompt.lower(),
                    f"{style_id} frame {frame_index}",
                )
                self.assertIn(
                    "Use Image 1 only as the identity reference",
                    prompt,
                    f"{style_id} frame {frame_index}",
                )
                self.assertNotIn(
                    "Image 2: The first generated frame",
                    prompt,
                    f"{style_id} frame {frame_index}",
                )


class SafeFrame0FallbackPromptTests(unittest.TestCase):
    def test_evening_look_safe_frame0_prompt_contains_style_hint(self) -> None:
        prompt = build_safe_frame0_fallback_prompt("evening_look")

        self.assertIn("Create one realistic professional portrait photo", prompt)
        self.assertIn("Return exactly one image.", prompt)
        self.assertIn("Style consistency locks (critical)", prompt)
        self.assertIn("closed elegant blouse or blazer", prompt)

    def test_generic_safe_frame0_prompt_has_no_style_hint(self) -> None:
        prompt = build_safe_frame0_fallback_prompt("studio_portrait")

        self.assertIn("Create one realistic professional portrait photo", prompt)
        self.assertNotIn("Elegant indoor portrait", prompt)


class SafeContinuationFallbackPromptTests(unittest.TestCase):
    def test_safe_continuation_fallback_suffix_contains_ultra_safe_rules(self) -> None:
        suffix = build_safe_continuation_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
        )

        self.assertIn("Safe continuation fallback (frame 2 of 3)", suffix)
        self.assertIn("Keep only the same person", suffix)
        self.assertIn("Change only pose, crop, gaze, and camera distance", suffix)
        self.assertIn("Do not change clothing color dramatically", suffix)
        self.assertIn("Avoid complex scene", suffix)
        self.assertIn("Return exactly one image.", suffix)

    def test_evening_look_safe_continuation_style_hint(self) -> None:
        suffix = build_safe_continuation_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
            client_style_id="evening_look",
        )

        self.assertIn("closed elegant blouse or blazer", suffix)
        self.assertIn("black off-shoulder top", suffix)
        self.assertIn("Style consistency locks (critical)", suffix)
        self.assertIn("glamour", suffix.lower())


class IdentityOnlyFallbackPromptTests(unittest.TestCase):
    def test_identity_only_fallback_suffix_contains_outfit_consistency_rules(self) -> None:
        suffix = build_identity_only_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
        )

        self.assertIn("Fallback generation mode (frame 2 of 3)", suffix)
        self.assertIn("do not switch to a different outfit color or neckline", suffix.lower())
        self.assertIn("do not switch to a different location or background", suffix.lower())
        self.assertIn("another frame from the same photoshoot", suffix.lower())
        self.assertIn("Return exactly one image.", suffix)

    def test_evening_look_identity_only_fallback_style_hint(self) -> None:
        suffix = build_identity_only_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
            client_style_id="evening_look",
        )

        self.assertIn("closed elegant blouse or blazer", suffix)
        self.assertIn("black off-shoulder top", suffix)
        self.assertIn("Style consistency locks (critical)", suffix)
        self.assertIn("glamour", suffix.lower())


class PromptSourceTests(unittest.TestCase):
    custom_style = PHOTOSHOOT_STYLES[CUSTOM_PHOTOSHOOT_STYLE_ID]

    def test_catalog_style_ignores_frontend_description_as_primary_prompt(self) -> None:
        client_description = "Black off-shoulder top in nightclub"
        source = resolve_prompt_source(
            "evening_look",
            PHOTOSHOOT_STYLES["evening_look"],
            user_description=client_description,
        )
        base = resolve_base_prompt(
            "evening_look",
            PHOTOSHOOT_STYLES["evening_look"],
            user_description=client_description,
        )

        self.assertEqual(source, "backend_catalog")
        self.assertNotIn("nightclub", base.lower())
        self.assertNotIn(client_description, base)

    def test_custom_photoshoot_uses_user_description(self) -> None:
        user_text = "Soft pastel portrait in a light studio with cream sweater."
        source = resolve_prompt_source(
            CUSTOM_PHOTOSHOOT_STYLE_ID,
            self.custom_style,
            user_description=user_text,
        )
        base = resolve_base_prompt(
            CUSTOM_PHOTOSHOOT_STYLE_ID,
            self.custom_style,
            user_description=user_text,
        )

        self.assertEqual(source, "custom_user_description")
        self.assertEqual(base, user_text)


class StyleLockPromptTests(unittest.TestCase):
    style = PHOTOSHOOT_STYLES["evening_look"]

    def test_style_locks_in_primary_prompt(self) -> None:
        prompt = build_photoshoot_frame_prompt(
            "evening_look",
            self.style,
            frame_index=0,
            output_count=3,
            series_reference_mode="identity_anchor",
        )

        self.assertIn("Style consistency locks (critical)", prompt)
        self.assertIn("closed elegant blouse or blazer", prompt)

    def test_style_locks_in_identity_only_fallback_suffix(self) -> None:
        suffix = build_identity_only_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
            client_style_id="evening_look",
        )

        self.assertIn("Style consistency locks (critical)", suffix)
        self.assertIn("black off-shoulder top", suffix)

    def test_style_locks_in_safe_continuation_and_frame0_and_batch(self) -> None:
        continuation = build_safe_continuation_fallback_prompt_suffix(
            frame_index=1,
            output_count=3,
            client_style_id="summer_photoshoot",
        )
        frame0 = build_safe_frame0_fallback_prompt("summer_photoshoot")
        batch = build_safe_a_only_batch_frame_prompt(
            "summer_photoshoot",
            frame_index=1,
            output_count=3,
        )

        self.assertIn("Style consistency locks (critical)", continuation)
        self.assertIn("green summer garden", frame0.lower())
        self.assertIn("Safe batch fallback", batch)

    def test_all_catalog_styles_have_locks(self) -> None:
        expected_ids = {
            "studio_portrait",
            "business_portrait",
            "city_portrait",
            "evening_look",
            "tender_photoshoot",
            "summer_photoshoot",
            "winter_photoshoot",
            "home_portrait",
            "expert_photoshoot",
            "business_brand",
            "personal_brand",
            "travel_portrait",
            "cafe_city",
            "park_walk",
            "premium_portrait",
        }
        self.assertEqual(
            set(PHOTOSHOOT_STYLE_LOCKS.keys()) - {CUSTOM_PHOTOSHOOT_STYLE_ID},
            expected_ids,
        )
        for style_id in expected_ids:
            lock = get_style_lock(style_id)
            self.assertTrue(lock.outfit_lock)
            self.assertTrue(lock.location_lock)
            self.assertTrue(lock.lighting_lock)
            self.assertTrue(lock.color_grading_lock)
            self.assertTrue(lock.forbidden_changes)
            block = build_style_lock_prompt_block(style_id)
            self.assertIn("Outfit:", block)
            self.assertIn("Location/background:", block)
            self.assertIn("Lighting:", block)
            self.assertIn("Color grading:", block)
            self.assertIn("Forbidden:", block)

    def test_urban_portrait_alias_uses_city_portrait_lock(self) -> None:
        urban = get_style_lock("urban_portrait")
        city = get_style_lock("city_portrait")
        self.assertEqual(urban, city)

    def test_key_forbidden_rules_for_high_drift_styles(self) -> None:
        summer = get_style_lock("summer_photoshoot").forbidden_changes.lower()
        park = get_style_lock("park_walk").forbidden_changes.lower()
        brand = get_style_lock("business_brand").forbidden_changes.lower()
        evening = get_style_lock("evening_look").forbidden_changes.lower()
        expert = get_style_lock("expert_photoshoot").forbidden_changes.lower()
        business = get_style_lock("business_portrait").forbidden_changes.lower()

        self.assertIn("black clothing", summer)
        self.assertIn("off-shoulder", summer)
        self.assertIn("black clothing", park)
        self.assertIn("off-shoulder", park)
        self.assertIn("off-shoulder", brand)
        self.assertIn("nightlife", evening)
        self.assertIn("glamour", evening)
        self.assertIn("off-shoulder", evening)
        self.assertIn("floral wallpaper", expert)
        self.assertIn("off-shoulder", expert)
        self.assertIn("floral wallpaper", business)
        self.assertIn("off-shoulder", business)

    def test_safe_batch_prompt_includes_style_lock_and_hard_rule_when_present(self) -> None:
        cases = {
            "summer_photoshoot": "Never use black clothing or off-shoulder neckline for summer_photoshoot.",
            "business_brand": "Never use black off-shoulder clothing for business_brand.",
            "park_walk": "Never use black clothing or off-shoulder neckline for park_walk.",
        }
        for style_id, expected_rule in cases.items():
            prompt = build_safe_a_only_batch_frame_prompt(
                style_id,
                frame_index=0,
                output_count=3,
            )
            self.assertIn("Style consistency locks (critical)", prompt)
            self.assertIn(expected_rule, prompt)
            self.assertEqual(get_safe_batch_hard_rule(style_id), expected_rule)

        studio_prompt = build_safe_a_only_batch_frame_prompt(
            "studio_portrait",
            frame_index=0,
            output_count=3,
        )
        self.assertIn("Style consistency locks (critical)", studio_prompt)
        self.assertIsNone(get_safe_batch_hard_rule("studio_portrait"))

    def test_summer_photoshoot_style_lock_forbids_black_and_off_shoulder(self) -> None:
        lock = get_style_lock("summer_photoshoot")
        block = build_style_lock_prompt_block("summer_photoshoot")

        self.assertIn("modest neckline", lock.outfit_lock.lower())
        self.assertIn("black clothing", lock.forbidden_changes.lower())
        self.assertIn("off-shoulder", lock.forbidden_changes.lower())
        self.assertIn("black clothing", block.lower())
        self.assertIn("off-shoulder", block.lower())

    def test_summer_safe_batch_prompt_includes_hard_rule_and_forbidden_changes(self) -> None:
        prompt = build_safe_a_only_batch_frame_prompt(
            "summer_photoshoot",
            frame_index=2,
            output_count=3,
        )

        self.assertIn(
            "Never use black clothing or off-shoulder neckline for summer_photoshoot.",
            prompt,
        )
        self.assertIn("black clothing", prompt.lower())
        self.assertIn("off-shoulder", prompt.lower())
        self.assertIn("modest neckline", prompt.lower())


class PhotoshootPromptPackV1Tests(unittest.TestCase):
    def test_pack_v1_frame_zero_includes_identity_and_opening_frame_language(self) -> None:
        from app.services.photoshoot_prompts import (
            PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS,
            resolve_frame_prompts,
        )
        from app.services.photoshoot_styles import get_photoshoot_style

        for style_id in sorted(PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS):
            style = get_photoshoot_style(style_id)
            prompts = resolve_frame_prompts(style_id, style, output_count=3)
            lower = prompts[0].lower()
            self.assertIn("keep the same identity", lower, style_id)
            self.assertTrue(
                "opening" in lower or "first frame" in lower or "frame 1" in lower,
                style_id,
            )

    def test_pack_v1_continuation_frames_include_independent_diversity_rules(self) -> None:
        from app.services.photoshoot_prompts import (
            PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS,
            resolve_frame_prompts,
        )
        from app.services.photoshoot_styles import get_photoshoot_style

        for style_id in sorted(PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS):
            style = get_photoshoot_style(style_id)
            prompts = resolve_frame_prompts(style_id, style, output_count=3)
            for frame_index, prompt in enumerate(prompts[1:], start=1):
                lower = prompt.lower()
                self.assertIn("keep the same identity", lower, f"{style_id} frame {frame_index}")
                self.assertTrue(
                    any(
                        phrase in lower
                        for phrase in (
                            "clearly differ",
                            "no duplicate",
                            "do not duplicate",
                            "do not repeat",
                        )
                    ),
                    f"{style_id} frame {frame_index}",
                )

    def test_parallel_frames_include_anti_duplicate_instruction(self) -> None:
        import json
        from pathlib import Path

        from app.services.photoshoot_prompts import resolve_frame_prompts
        from app.services.photoshoot_styles import get_photoshoot_style

        catalog_path = (
            Path(__file__).resolve().parent.parent / "app" / "catalog" / "photoshoots.json"
        )
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        needles = (
            "do not duplicate",
            "no duplicate",
            "do not repeat",
        )
        for item in catalog:
            style_id = item["id"]
            style = get_photoshoot_style(style_id)
            prompts = resolve_frame_prompts(style_id, style, output_count=3)
            for frame_index in range(3):
                lower = prompts[frame_index].lower()
                self.assertTrue(
                    any(needle in lower for needle in needles),
                    f"{style_id} frame {frame_index}",
                )


if __name__ == "__main__":
    unittest.main()
