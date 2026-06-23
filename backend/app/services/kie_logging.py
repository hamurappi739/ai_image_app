"""Kie operational logging — routes to uvicorn console (no secrets)."""

from __future__ import annotations

import logging

kie_log = logging.getLogger("uvicorn.error")
