"""Global sliding-window rate limiter for Kie createTask calls."""

from __future__ import annotations

import threading
import time
from collections import deque

from app.config import settings
from app.services.kie_logging import kie_log

_lock = threading.Lock()
_recent_create_task_times: deque[float] = deque()


def acquire_kie_create_task_slot() -> None:
    """Block until a createTask slot is available within the configured window."""
    limit = max(1, int(settings.kie_create_task_rate_limit))
    window_seconds = max(0.1, float(settings.kie_create_task_rate_window_seconds))

    while True:
        with _lock:
            now = time.monotonic()
            while _recent_create_task_times and (
                _recent_create_task_times[0] <= now - window_seconds
            ):
                _recent_create_task_times.popleft()
            if len(_recent_create_task_times) < limit:
                _recent_create_task_times.append(now)
                return
            wait_until = _recent_create_task_times[0] + window_seconds
        sleep_seconds = max(0.01, wait_until - time.monotonic())
        kie_log.info(
            "Kie create_task rate limit wait: sleep_ms=%s window_seconds=%s limit=%s",
            int(sleep_seconds * 1000),
            window_seconds,
            limit,
        )
        time.sleep(sleep_seconds)


def reset_kie_create_task_rate_limiter_for_tests() -> None:
    """Clear recorded createTask timestamps (unit tests only)."""
    with _lock:
        _recent_create_task_times.clear()
