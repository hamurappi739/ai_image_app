"""Tests for GET /image-proxy gallery image proxy."""

from __future__ import annotations

import unittest
from unittest.mock import patch

import httpx
from fastapi.testclient import TestClient

from app.config import settings
from app.main import app

_ALLOWED_HOST = "cvzzceastvlbcxsckoqd.supabase.co"
_ALLOWED_URL = (
    f"https://{_ALLOWED_HOST}/storage/v1/object/public/"
    "generated-images/generations/user/test.jpg"
)
_IMAGE_BYTES = b"\xff\xd8\xff\xe0fake-jpeg-bytes"


class ImageProxyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.image_proxy_service.httpx.get")
    def test_allowed_supabase_url_returns_image_bytes(
        self,
        mock_get: unittest.mock.MagicMock,
    ) -> None:
        mock_get.return_value = httpx.Response(
            200,
            content=_IMAGE_BYTES,
            headers={"content-type": "image/jpeg"},
            request=httpx.Request("GET", _ALLOWED_URL),
        )

        response = self.client.get("/image-proxy", params={"url": _ALLOWED_URL})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, _IMAGE_BYTES)
        self.assertEqual(response.headers["content-type"], "image/jpeg")
        self.assertIn("max-age=86400", response.headers["cache-control"])
        mock_get.assert_called_once_with(
            _ALLOWED_URL,
            timeout=30.0,
            follow_redirects=True,
        )

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    def test_disallowed_host_returns_400(self) -> None:
        bad_url = (
            "https://evil.example.com/storage/v1/object/public/"
            "generated-images/generations/user/test.jpg"
        )
        response = self.client.get("/image-proxy", params={"url": bad_url})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Invalid image URL")

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    def test_disallowed_path_returns_400(self) -> None:
        bad_url = (
            f"https://{_ALLOWED_HOST}/storage/v1/object/public/"
            "other-bucket/secret/file.jpg"
        )
        response = self.client.get("/image-proxy", params={"url": bad_url})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Invalid image URL")

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    def test_disallowed_scheme_returns_400(self) -> None:
        bad_url = _ALLOWED_URL.replace("https://", "http://")
        response = self.client.get("/image-proxy", params={"url": bad_url})
        self.assertEqual(response.status_code, 400)

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.image_proxy_service.httpx.get")
    def test_upstream_failure_returns_502(
        self,
        mock_get: unittest.mock.MagicMock,
    ) -> None:
        mock_get.return_value = httpx.Response(
            404,
            content=b"not found",
            request=httpx.Request("GET", _ALLOWED_URL),
        )

        response = self.client.get("/image-proxy", params={"url": _ALLOWED_URL})

        self.assertEqual(response.status_code, 502)
        self.assertEqual(response.json()["detail"], "Image unavailable")
        self.assertNotIn(_ALLOWED_URL, response.text)

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.image_proxy_service.httpx.get")
    def test_upstream_non_image_content_type_returns_502(
        self,
        mock_get: unittest.mock.MagicMock,
    ) -> None:
        mock_get.return_value = httpx.Response(
            200,
            content=b"<html></html>",
            headers={"content-type": "text/html"},
            request=httpx.Request("GET", _ALLOWED_URL),
        )

        response = self.client.get("/image-proxy", params={"url": _ALLOWED_URL})

        self.assertEqual(response.status_code, 502)
        self.assertEqual(response.json()["detail"], "Image unavailable")

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.image_proxy_service.httpx.get")
    def test_upstream_http_error_returns_502(
        self,
        mock_get: unittest.mock.MagicMock,
    ) -> None:
        mock_get.side_effect = httpx.ConnectError("connection refused")

        response = self.client.get("/image-proxy", params={"url": _ALLOWED_URL})

        self.assertEqual(response.status_code, 502)
        self.assertEqual(response.json()["detail"], "Image unavailable")


if __name__ == "__main__":
    unittest.main()
