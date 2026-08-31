"""Seed: seven farms across four crops, one farmer each, plus an agronomist and
an official.

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
identical to a correct one. The paddy trio has proven itself since Phase 1 and
is untouched by V2:

    A  Gangapur      19.99730 N, 73.74140 E   paddy
    B  Anandvalli    19.99310 N, 73.75530 E   paddy
    C  Ozar          20.09280 N, 73.92860 E   paddy

    A - B    ~1_530 m    INSIDE  SPREAD_RADIUS_M (2000)
    A - C   ~22_300 m    outside
    B - C   ~21_100 m    outside

V2 adds four more farms — one each for cotton, soybean and jowar, plus a
second cotton farm — so F6's fan-out is proven on more than one crop:

    D  Yavatmal      20.38880 N, 78.12040 E   cotton   (Vidarbha cotton belt)
    E  Yavatmal-2     ~1_530 m from D          cotton   (same offset as A-B,
                                                          reused deliberately —
                                                          see below)
    F  Latur         18.40880 N, 76.56040 E   soybean  (Marathwada soybean belt)
    G  Solapur       17.65990 N, 75.90640 E   jowar    (rabi jowar belt)

D and E use the EXACT SAME (Δlat, Δlng) offset that separates A and B
(-0.00420, +0.01390), at a latitude close enough to Nashik's that the measured
distance is expected to land near the same ~1_530 m — reused rather than
recomputed, since the point is a same-crop pair inside the radius, not a novel
distance. The printed table below reports what PostGIS actually measures, not
what the offset was chosen to produce.

F and G are each the only farm of their crop, so — like paddy-C — they prove
the radius query returns nothing for a crop with no neighbour to warn.

Only same-crop, in-radius pairs propagate: A-B (paddy) and D-E (cotton). F6
never has reason to compare a cotton farm against a soybean or paddy one.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import asyncio
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import select, text

from app.config import SPREAD_RADIUS_M
from app.contracts.enums import Crop, Role
from app.core import security
from app.core.models import Farm, User
from app.db import SessionLocal, dispose_engine

FARMERS = [
    ("+919820000001", "Ramesh Pawar"),
    ("+919820000002", "Sunita Deshmukh"),
    ("+919820000003", "Bhaskar Jadhav"),
    ("+919820000004", "Vitthal Rathod"),
    ("+919820000005", "Kavita Shinde"),
    ("+919820000006", "Prakash Deshmane"),
    ("+919820000007", "Manisha Kale"),
]

# --- sowing dates ------------------------------------------------------------
#
# Nullable in the schema, but seeded here because the F5 phenology branch needs
# farms whose days-after-sowing is consistent with their growth_stage.
# days_after_sowing is NEVER stored — it is derived on read, because a stored
# integer is wrong the next morning and nothing refreshes it.
#
# Paddy (Kharif, transplanted). Phase 1 arithmetic, unchanged:
#
#     nursery      0 - 25      tillering   40 - 65
#     vegetative  25 - 40      booting     65 - 85
#
#     A  tillering   -> DAS 52
#     B  tillering   -> DAS 48   (four days off A, on purpose — see Phase 1)
#     C  vegetative  -> DAS 33
#
# Cotton, soybean, jowar (seed/growth_stages.py has the sourced DAS windows
# per stage; picked here to land inside a phenology rule in
# seed/risk_targets.json so the risk job has something real to score):
#
#     D  squaring       35-55 DAS window -> pick 45  -> within
#        cotton_american_bollworm's 35-160 DAS phenology rule
#     E  boll_formation 70-140 DAS window -> pick 75 -> within BOTH
#        cotton_american_bollworm (35-160) and cotton_pink_bollworm (70-140) —
#        deliberately, so the cotton pair demonstrates two different targets
#        firing rather than the same one twice
#     F  flowering      35-55 DAS window (soybean) -> pick 45 -> within
#        soybean_yellow_mosaic_virus's 10-60 DAS phenology rule
#     G  flowering      60-75 DAS window (jowar) -> pick 70 -> within
#        jowar_grain_mold's 60-100 DAS phenology rule
DAYS_AFTER_SOWING = {
    "A Gangapur": 52,
    "B Anandvalli": 48,
    "C Ozar": 33,
    "D Yavatmal": 45,
    "E Yavatmal-2": 75,
    "F Latur": 45,
    "G Solapur": 70,
}


def _sowing_date(label: str) -> date:
    return (datetime.now(UTC) - timedelta(days=DAYS_AFTER_SOWING[label])).date()


# The A-B offset, reused for D-E. See the module docstring.
_NEAR_OFFSET_LAT = -0.00420
_NEAR_OFFSET_LNG = +0.01390

# (label, phone, crop, variety, growth_stage, region, lat, lng)
FARMS = [
    ("A Gangapur", "+919820000001", Crop.PADDY, "Indrayani", "tillering",
     "Nashik", 19.99730, 73.74140),
    ("B Anandvalli", "+919820000002", Crop.PADDY, "Phule Samruddhi", "tillering",
     "Nashik", 19.99310, 73.75530),
    ("C Ozar", "+919820000003", Crop.PADDY, "Indrayani", "vegetative",
     "Nashik", 20.09280, 73.92860),
    ("D Yavatmal", "+919820000004", Crop.COTTON, "Bt cotton (BG-II)", "squaring",
     "Yavatmal", 20.38880, 78.12040),
    ("E Yavatmal-2", "+919820000005", Crop.COTTON, "Bt cotton (BG-II)", "boll_formation",
     "Yavatmal", 20.38880 + _NEAR_OFFSET_LAT, 78.12040 + _NEAR_OFFSET_LNG),
    ("F Latur", "+919820000006", Crop.SOYBEAN, "JS-335", "flowering",
     "Latur", 18.40880, 76.56040),
    ("G Solapur", "+919820000007", Crop.JOWAR, "CSH 16", "flowering",
     "Solapur", 17.65990, 75.90640),
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
        for label, phone, crop, variety, stage, region, lat, lng in FARMS:
            farmer = (
                await session.execute(select(User).where(User.phone == phone))
            ).scalar_one()
            farm = (
                await session.execute(select(Farm).where(Farm.farmer_id == farmer.id))
            ).scalars().first()
            wkt = f"SRID=4326;POINT({lng} {lat})"
            if farm is None:
                farm = Farm(
                    farmer_id=farmer.id, crop=crop, variety=variety,
                    growth_stage=stage, region=region, location=wkt,
                    sowing_date=_sowing_date(label),
                )
                session.add(farm)
            else:
                farm.crop = crop
                farm.variety, farm.growth_stage, farm.region = variety, stage, region
                farm.location = wkt
                farm.sowing_date = _sowing_date(label)
            await session.flush()
            created.append((label, farm))

        await session.commit()

        # Distances measured by PostGIS, not asserted by this file.
        print(f"\nSPREAD_RADIUS_M = {SPREAD_RADIUS_M}\n")
        print(f"{'pair':30s} {'metres':>10s}  within radius  same crop")
        print("-" * 68)
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
                same_crop = "yes" if fa.crop == fb.crop else "no"
                pair = f"{la} - {lb}"
                print(f"{pair:30s} {metres:10.0f}  {inside:13s}  {same_crop}")

        print(f"\n{'farm':16s} {'crop':9s} {'sowing_date':12s} {'DAS':>4s}  growth_stage")
        print("-" * 68)
        for label, farm in created:
            crop_value = farm.crop.value if hasattr(farm.crop, "value") else str(farm.crop)
            print(
                f"{label:16s} {crop_value:9s} {farm.sowing_date!s:12s} "
                f"{DAYS_AFTER_SOWING[label]:4d}  {farm.growth_stage}"
            )

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
