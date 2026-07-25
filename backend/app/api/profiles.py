"""Profile CRUD endpoint。

Profile 是一组有名称的会话（决策 D22）。Endpoint 挂载在 ``/api/profiles`` 下，且都
要求共享 bearer token。删除 profile 会根据 :mod:`app.models` 中 foreign key 声明的
``ondelete`` rule，级联删除其中的会话和消息。
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
    """按最近更新时间优先返回所有 profile。"""
    statement = select(Profile).order_by(Profile.updated_at.desc())
    result = await session.execute(statement)
    return list(result.scalars())


@router.post("", response_model=ProfileRead, status_code=status.HTTP_201_CREATED)
async def create_profile(name: str, session=Depends(get_session)) -> Profile:
    """使用给定名称创建 profile。

    为保持简单，name 会作为 plain request body string 发送；客户端只创建一个命名组，
    因此使用只包含一个字段的 JSON object 没有必要。
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
    """重命名 profile。与 create endpoint 一样使用 plain body string。"""
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
    """删除 profile。数据库的 ``ON DELETE CASCADE`` foreign-key rule 会删除会话和消息。"""
    profile = await session.get(Profile, profile_id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "profile not found")
    await session.delete(profile)
    await session.commit()
