"""Photoshoot generation job persistence (in-memory MVP; swappable for Redis/DB)."""

from __future__ import annotations

import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Literal
from uuid import uuid4

FrameJobStatus = Literal["queued", "generating", "done", "error"]
PhotoshootJobStatus = Literal["queued", "running", "success", "error"]


@dataclass
class PhotoshootFrameJobState:
    index: int
    status: FrameJobStatus = "queued"


@dataclass
class PhotoshootJobRecord:
    job_id: str
    user_id: str
    style_id: str
    style_title: str
    output_count: int
    status: PhotoshootJobStatus = "queued"
    message: str = ""
    frames: list[PhotoshootFrameJobState] = field(default_factory=list)
    images: list[str] = field(default_factory=list)
    thumbnail_urls: list[str | None] = field(default_factory=list)
    photoshoot_id: str | None = None
    storage_paths: list[str] = field(default_factory=list)
    balance: dict | None = None
    description: str | None = None

    def to_status_payload(self) -> dict:
        return {
            "status": self.status,
            "message": self.message,
            "frames": [
                {"index": frame.index, "status": frame.status}
                for frame in self.frames
            ],
            "images": list(self.images),
            "thumbnail_urls": list(self.thumbnail_urls),
            "photoshoot_id": self.photoshoot_id,
            "style_id": self.style_id,
            "style_title": self.style_title,
            "output_count": self.output_count,
            "balance": self.balance,
            "description": self.description,
        }


@dataclass
class PhotoshootJobStartPayload:
    user_id: str
    user_email: str | None
    style_id: str
    style_title: str
    photo_bytes: bytes
    photo_content_type: str
    user_description: str | None
    output_count: int


class PhotoshootJobStore(ABC):
    @abstractmethod
    def create_job(
        self,
        *,
        user_id: str,
        style_id: str,
        style_title: str,
        output_count: int,
    ) -> PhotoshootJobRecord:
        raise NotImplementedError

    @abstractmethod
    def get_job(self, job_id: str) -> PhotoshootJobRecord | None:
        raise NotImplementedError

    @abstractmethod
    def save_job(self, job: PhotoshootJobRecord) -> None:
        raise NotImplementedError

    @abstractmethod
    def put_start_payload(self, job_id: str, payload: PhotoshootJobStartPayload) -> None:
        raise NotImplementedError

    @abstractmethod
    def get_start_payload(self, job_id: str) -> PhotoshootJobStartPayload | None:
        raise NotImplementedError


class InMemoryPhotoshootJobStore(PhotoshootJobStore):
    def __init__(self) -> None:
        self._jobs: dict[str, PhotoshootJobRecord] = {}
        self._payloads: dict[str, PhotoshootJobStartPayload] = {}
        self._lock = threading.Lock()

    def create_job(
        self,
        *,
        user_id: str,
        style_id: str,
        style_title: str,
        output_count: int,
    ) -> PhotoshootJobRecord:
        job_id = str(uuid4())
        frames = [
            PhotoshootFrameJobState(index=index, status="queued")
            for index in range(output_count)
        ]
        job = PhotoshootJobRecord(
            job_id=job_id,
            user_id=user_id,
            style_id=style_id,
            style_title=style_title,
            output_count=output_count,
            frames=frames,
            message="Photoshoot queued",
        )
        with self._lock:
            self._jobs[job_id] = job
        return job

    def get_job(self, job_id: str) -> PhotoshootJobRecord | None:
        with self._lock:
            job = self._jobs.get(job_id)
            if job is None:
                return None
            return PhotoshootJobRecord(
                job_id=job.job_id,
                user_id=job.user_id,
                style_id=job.style_id,
                style_title=job.style_title,
                output_count=job.output_count,
                status=job.status,
                message=job.message,
                frames=[
                    PhotoshootFrameJobState(index=frame.index, status=frame.status)
                    for frame in job.frames
                ],
                images=list(job.images),
                thumbnail_urls=list(job.thumbnail_urls),
                photoshoot_id=job.photoshoot_id,
                storage_paths=list(job.storage_paths),
                balance=job.balance,
                description=job.description,
            )

    def save_job(self, job: PhotoshootJobRecord) -> None:
        with self._lock:
            self._jobs[job.job_id] = job

    def put_start_payload(self, job_id: str, payload: PhotoshootJobStartPayload) -> None:
        with self._lock:
            self._payloads[job_id] = payload

    def get_start_payload(self, job_id: str) -> PhotoshootJobStartPayload | None:
        with self._lock:
            return self._payloads.get(job_id)


photoshoot_job_store = InMemoryPhotoshootJobStore()
