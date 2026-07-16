"""Profile CRUD endpoints.

A profile is a named group of conversations (decision D22). Endpoints are
mounted under ``/api/profiles`` and all require the shared bearer token.
Profile deletion cascades to its conversations and their messages through
the ``ondelete`` rules declared on the foreign keys in :mod:`app.models`.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select

from ..auth import verify_token
from ..db import get_session
from ..models import Profile, ProfileRead

router = APIRouter(prefix="/profiles", dependencies=[Depends(verify_token)])


@router.get("", response_model=list[ProfileRead])
async def list_profiles(session=Depends(get_session)) -> list[Profile]:
    """Return every profile ordered by most-recently-updated first."""
    statement = select(Profile).order_by(Profile.updated_at.desc())
    result = await session.execute(statement)
    return list(result.scalars())


@router.post("", response_model=ProfileRead, status_code=status.HTTP_201_CREATED)
async def create_profile(name: str, session=Depends(get_session)) -> Profile:
    """Create a profile with the given name.

    The name is sent as a plain request body string for simplicity; the
    client only ever creates a named group, so a JSON object with a single
    field would be ceremony.
    """
    profile = Profile(name=name.strip())
    session.add(profile)
    await session.commit()
    await session.refresh(profile)
    return profile


@router.patch("/{profile_id}", response_model=ProfileRead)
async def rename_profile(
    profile_id: int, name: str, session=Depends(get_session)
) -> Profile:
    """Rename a profile. Uses a plain body string like the create endpoint."""
    profile = await session.get(Profile, profile_id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "profile not found")
    profile.name = name.strip()
    profile.updated_at = datetime.now(timezone.utc)
    session.add(profile)
    await session.commit()
    await session.refresh(profile)
    return profile


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(profile_id: int, session=Depends(get_session)) -> None:
    """Delete a profile. Conversations and messages are removed by the
    database's ``ON DELETE CASCADE`` foreign-key rules."""
    profile = await session.get(Profile, profile_id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "profile not found")
    await session.delete(profile)
    await session.commit()
