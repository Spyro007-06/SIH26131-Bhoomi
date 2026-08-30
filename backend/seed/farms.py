"""Seed: three Nashik farms, one farmer each, plus an agronomist and an official.

OWNER: Shreekumar. Run from backend/:  python -m seed.farms

Idempotent — re-running matches on phone/email and updates rather than
duplicating.

-----------------------------------------------------------------------------
The geometry is the point of this file.

docs/DESIGN.md §10's F6 fan-out is:

    SELECT id FROM farm
    WHERE crop = :crop AND id != :origin
      AND ST_DWithin(location, :origin_point, :radius);

with :radius = SPREAD_RADIUS_M (2000 m). A seed where every farm is inside the
radius proves nothing, because a broken query that returns everything looks
identical to a correct one. So two farms sit inside it and one sits well
outside, and Phase 4 can assert the third is excluded.

    A  Gangapur      19.99730 N, 73.74140 E
    B  Anandvalli    19.99310 N, 73.75530 E
    C  Ozar          20.09280 N, 73.92860 E

Pairwise great-circle distances (metres), computed by PostGIS at seed time and
printed by this script so the numbers are measured, not asserted:

    A - B    ~1_530 m    INSIDE  SPREAD_RADIUS_M (2000)
    A - C   ~22_300 m    outside
    B - C   ~21_100 m    outside

A and B are both paddy, so a confirmation at A must fan out to exactly B.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import asyncio

from sqlalchemy import select, text

from app.config import SPREAD_RADIUS_M
from app.contracts.enums import Crop, GrowthStage, Role
from app.core import security
from app.core.models import Farm, User
from app.db import SessionLocal, dispose_engine

FARMERS = [
    ("+919820000001", "Ramesh Pawar"),
    ("+919820000002", "Sunita Deshmukh"),
    ("+919820000003", "Bhaskar Jadhav"),
]

# (label, phone, variety, growth_stage, region, lat, lng)
FARMS = [
    ("A Gangapur", "+919820000001", "Indrayani", GrowthStage.TILLERING,
     "Nashik", 19.99730, 73.74140),
    ("B Anandvalli", "+919820000002", "Phule Samruddhi", GrowthStage.TILLERING,
     "Nashik", 19.99310, 73.75530),
    ("C Ozar", "+919820000003", "Indrayani", GrowthStage.VEGETATIVE,
     "Nashik", 20.09280, 73.92860),
]

STAFF = [
    (Role.AGRONOMIST, "agronomist@kvk-nashik.example", "Dr. Meera Kulkarni"),
    (Role.OFFICIAL, "official@agri.maharashtra.example", "S. R. Patil"),
]

STAFF_PASSWORD = "bhoomi-dev-password"


async def _upsert_farmer(session, phone: str, name: str) -> User:
    user = (
        await session.execute(select(User).where(User.phone == phone))
    ).scalar_one_or_none()
    if user is None:
        user = User(role=Role.FARMER, phone=phone, name=name)
        session.add(user)
        await session.flush()
    else:
        user.name = name
    return user


async def _upsert_staff(session, role: Role, email: str, name: str) -> User:
    user = (
        await session.execute(select(User).where(User.email == email))
    ).scalar_one_or_none()
    if user is None:
        user = User(
            role=role,
            email=email,
            name=name,
            password_hash=security.hash_secret(STAFF_PASSWORD),
        )
        session.add(user)
        await session.flush()
    else:
        user.name = name
    return user


async def seed() -> None:
    async with SessionLocal() as session:
        for phone, name in FARMERS:
            await _upsert_farmer(session, phone, name)
        for role, email, name in STAFF:
            await _upsert_staff(session, role, email, name)
        await session.flush()

        created: list[tuple[str, Farm]] = []
        for label, phone, variety, stage, region, lat, lng in FARMS:
            farmer = (
                await session.execute(select(User).where(User.phone == phone))
            ).scalar_one()
            farm = (
                await session.execute(select(Farm).where(Farm.farmer_id == farmer.id))
            ).scalars().first()
            wkt = f"SRID=4326;POINT({lng} {lat})"
            if farm is None:
                farm = Farm(
                    farmer_id=farmer.id, crop=Crop.PADDY, variety=variety,
                    growth_stage=stage, region=region, location=wkt,
                )
                session.add(farm)
            else:
                farm.variety, farm.growth_stage, farm.region = variety, stage, region
                farm.location = wkt
            await session.flush()
            created.append((label, farm))

        await session.commit()

        # Distances measured by PostGIS, not asserted by this file.
        print(f"\nSPREAD_RADIUS_M = {SPREAD_RADIUS_M}\n")
        print(f"{'pair':28s} {'metres':>10s}  within radius")
        print("-" * 55)
        for i in range(len(created)):
            for j in range(i + 1, len(created)):
                (la, fa), (lb, fb) = created[i], created[j]
                metres = await session.scalar(
                    text(
                        "SELECT ST_Distance("
                        "  (SELECT location FROM farm WHERE id = :a),"
                        "  (SELECT location FROM farm WHERE id = :b))"
                    ).bindparams(a=fa.id, b=fb.id)
                )
                inside = "YES" if metres <= SPREAD_RADIUS_M else "no"
                print(f"{la} - {lb:14s} {metres:10.0f}  {inside}")

        print(f"\n{len(created)} farms, {len(FARMERS)} farmers, {len(STAFF)} staff.")
        print(f"Staff sign in with password: {STAFF_PASSWORD}")


async def main() -> None:
    """Dispose inside the same event loop that opened the connections.

    asyncio.run(seed()) followed by asyncio.run(dispose_engine()) closes the
    pool from a second loop, and asyncpg's transport raises "Event loop is
    closed" on the way out — after the work has already committed, so it looks
    like a failure that is not one.
    """
    try:
        await seed()
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
