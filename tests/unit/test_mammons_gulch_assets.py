import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "assets" / "mammons-gulch" / "asset-manifest.json"
CRITERIA = {
    "referenceFit", "geometryQuality", "materials", "visualCompatibility", "editability",
    "optimization", "technicalCompatibility", "uvQuality", "scaleCorrectness", "licenseAndSafety",
}
REQUIRED = {
    "id", "name", "category", "source", "author", "license", "licenseUrl", "checkedAt",
    "allowedActions", "localPath", "modifications", "status", "scores", "scriptAudit",
}


class AssetManifestTest(unittest.TestCase):
    def test_every_candidate_has_complete_provenance_and_bounded_scores(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(manifest["assets"]), 16)
        for asset in manifest["assets"]:
            self.assertEqual(REQUIRED - asset.keys(), set(), asset["id"])
            self.assertEqual(set(asset["scores"]), CRITERIA, asset["id"])
            self.assertTrue(asset["source"].startswith("https://"), asset["id"])
            self.assertTrue(asset["licenseUrl"].startswith("https://"), asset["id"])
            for criterion, score in asset["scores"].items():
                self.assertTrue(score is None or 0 <= score <= 10, (asset["id"], criterion, score))

    def test_approved_assets_have_local_files_and_passed_security_review(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        for asset in manifest["assets"]:
            if not asset["status"].startswith("approved"):
                continue
            self.assertTrue(asset["localPath"], asset["id"])
            self.assertTrue((ROOT / asset["localPath"]).is_file(), asset["id"])
            self.assertNotEqual(asset["license"].lower(), "unknown", asset["id"])
            self.assertIn(asset["scriptAudit"], {"passed", "not_applicable_external_geometry"}, asset["id"])

    def test_pending_or_rejected_assets_cannot_claim_build_integration(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        for asset in manifest["assets"]:
            if asset["status"] == "approved_for_reuse":
                continue
            self.assertIsNone(asset["localPath"], asset["id"])
            self.assertNotEqual(asset["scriptAudit"], "passed", asset["id"])

    def test_requested_fab_candidates_have_explicit_current_decisions(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        assets = {asset["id"]: asset for asset in manifest["assets"]}
        self.assertEqual(assets["fab-old-mine"]["license"], "Fab Standard License")
        self.assertEqual(assets["fab-old-mine"]["status"], "license_verified__download_and_qa_pending")
        self.assertEqual(assets["fab-wild-west-bank"]["status"], "rejected_price_and_style")
        self.assertNotIn("commit_raw_source", assets["fab-old-mine"]["allowedActions"])

    def test_compound_specs_reference_real_candidate_ids(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        ids = {asset["id"] for asset in manifest["assets"]}
        self.assertEqual(len(ids), len(manifest["assets"]))
        la_plata = (ROOT / "docs" / "map-compounds" / "la-plata-mine.md").read_text(encoding="utf-8")
        self.assertIn("fab-old-mine", la_plata)
        self.assertIn("ph-rock-face-01", la_plata)
        self.assertNotIn("PENDING_ASSET_RESEARCH", la_plata)


if __name__ == "__main__":
    unittest.main()
