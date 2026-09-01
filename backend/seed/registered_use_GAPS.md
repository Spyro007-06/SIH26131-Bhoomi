# registered_use gaps — cotton, soybean, jowar (V3 phase 3, Part 3)

For someone with a KVK or agricultural-university contact, not a developer.
Each entry below is a diagnosable target with **no row in `registered_use.csv`**
yet. That is not a bug: a target with no row gets `NOT_IN_RECORDS` from the
app and the farmer is told to ask an expert, which is the honest, designed
outcome — a partial table with visible gaps is safer than a guessed row. This
file exists so the gaps are visible and closeable, not silent.

For each target: what the target is, what was searched, why it didn't
produce a row, and what would close it.

---

## cotton_leaf_curl_virus

**Not a chemistry gap — there is no fungicide/pesticide "for" a plant virus.**
Cotton Leaf Curl Virus is transmitted by whitefly (*Bemisia tabaci*); nothing
kills the virus once a plant is infected. Management is resistant/tolerant
varieties and controlling the whitefly vector, not spraying the diagnosed
disease. If this table should carry anything for this target, it should be a
**cross-reference to the `cotton_whitefly` row(s)** rather than a fabricated
direct-treatment entry — worth a product decision, not a search.

## soybean_yellow_mosaic_virus

Same reasoning as `cotton_leaf_curl_virus`, exactly: whitefly-transmitted
viral disease, no direct chemical treatment exists, management is vector
control and resistant varieties. Not searched further for the same reason —
searching for "registered fungicide for a virus" would only find
misleading or informal results.

## cotton_bacterial_blight — noted here even though a row loaded

A row *did* load (Carboxin 37.5% + Thiram 37.5% DS, seed treatment) — see
`registered_use.csv`. Recording the search history here anyway because it
surfaces a real finding, not because the target is a gap:

**Streptocycline (streptomycin + copper oxychloride combination) is the
package-of-practices standard for cotton bacterial blight** — ICAR-CICR and
multiple state extension sources recommend Copper oxychloride 50 WP @ 25 g +
Streptocycline @ 1 g per 10 L water as a foliar spray. This was **not**
loaded as a row, and the reason is not a search failure:

CIB&RC approved a recommendation in August 2021 to phase out streptomycin +
tetracycline combination products in agriculture over antimicrobial-
resistance concerns. A draft order prohibited manufacture/import from
2022-02-01 with a complete use ban targeted for 2024-01-01. As of the most
recent reporting found (Centre for Science and Environment's follow-up with
CIB&RC, November 2024), **the order is still not enforced** — CIB&RC's own
account is that alternatives are still being worked out. This is genuinely
unsettled: the product is not cleanly "banned" (the use-ban date has passed
without enforcement) and not cleanly "current" (a phase-out is actively in
motion, initiated specifically over the resistance risk this table's
`restriction_note` column exists to flag). Recording a streptocycline row
right now would say something the regulatory record itself cannot confirm.

**What would close this properly:** confirmation from CIB&RC or DPPQS of
streptocycline's *current* (not 2021-2022 draft) registration status for
cotton bacterial blight specifically, so `source_dated` reflects a real,
current document rather than an in-limbo draft order.

## cotton_fusarium_wilt

Searched: CIB&RC "Major Uses of Pesticides — Fungicides" (DPPQS, as on
30.09.2012, agritech.tnau.ac.in/crop_protection/pdf/6_Major_use_fungicides.pdf
— the same document three other rows in this file cite) has no Cotton +
Fusarium wilt entry; checked every Cotton entry in that document by name
(Leaf spot, Angular leaf spot, Seedling blight, Mites, Root rot/Bacterial
blight). Carbendazim is widely used against Fusarium wilt in general
literature and is CIB&RC-registered for Fusarium wilt on other crops (e.g.
pigeon pea, in the same document), but no cotton-specific entry was found.
Trial/extension literature exists (soil drench recommendations) but does not
meet this table's citation bar.

**What would close this:** a PPQS product label or CIB&RC major-use entry
naming cotton and Fusarium wilt specifically.

## soybean_anthracnose

Searched: the CIB&RC fungicides document above has no Soybean entry beyond
Rust and Collar rot/Charcoal rot/seedling diseases — no anthracnose entry.
Web search surfaces tebuconazole and trifloxystrobin+tebuconazole
(Nativo 75 WG) efficacy trials against *Colletotrichum truncatum*, but these
are trial-literature results, not confirmed CIB&RC registrations naming
soybean anthracnose. Consistent with this table's standing rule: trial data
is not a registration.

**What would close this:** the specific PPQS label or CIB&RC major-use entry
for whichever product is actually registered for soybean anthracnose in
India, if one exists.

## soybean_alternaria_leaf_spot

Same search, same document, same result as `soybean_anthracnose` — no
Soybean entry for Alternaria or leaf spot in the CIB&RC fungicides document.
Often bundled with anthracnose in extension material (both foliar fungal
diseases, similar timing) — closing one may surface the other.

## soybean_bacterial_blight

Not searched as deeply as cotton_bacterial_blight given the timebox, but the
same antibiotic-restriction issue almost certainly applies: bacterial blight
in soybean, like cotton, is conventionally managed with a
streptomycin/copper-based spray, and streptomycin-family products are the
ones in regulatory limbo (see `cotton_bacterial_blight` above). Worth
checking whether a non-antibiotic registered option exists (a copper
formulation alone, without streptocycline) before concluding this is the
same gap.

## jowar_anthracnose

Searched: the CIB&RC fungicides document has exactly one Jowar/Sorghum
disease entry outside smut and downy mildew — Zineb 75% WP for "Red leaf
spot" / "Leaf spot" / "Leaf blight". No anthracnose entry for jowar/sorghum
anywhere in the document (searched every "Anthracnose" occurrence in the
document and every Sorghum/Jowar occurrence; none coincide).

**What would close this:** a PPQS label or CIB&RC major-use entry naming
sorghum/jowar and anthracnose specifically.

## jowar_grain_mold

Searched the same document for "grain mold", "mould", "grain rot" near any
Sorghum/Jowar entry — nothing. Grain mold in sorghum is caused by a complex
of fungi (*Fusarium*, *Curvularia*, *Alternaria* and others acting together
under wet weather at grain maturity), not a single pathogen — that may be
exactly why no single "major use" entry exists for it: a registration is
typically issued against a named pathogen/disease, and a multi-fungus field
complex may not have been registered against as a discrete target the way a
single-pathogen disease is.

**What would close this:** confirmation of whether any product is registered
specifically against sorghum grain mold as such, or whether coverage in
practice comes from an at-flowering fungicide spray registered for a
different named disease that happens to also suppress grain mold.

---

## Summary

| Target | Status |
|---|---|
| cotton_bacterial_blight | Loaded (seed treatment) — streptocycline finding recorded above |
| cotton_leaf_curl_virus | Not a chemistry gap — viral, vector-managed |
| cotton_fusarium_wilt | Gap |
| soybean_yellow_mosaic_virus | Not a chemistry gap — viral, vector-managed |
| soybean_anthracnose | Gap |
| soybean_alternaria_leaf_spot | Gap |
| soybean_bacterial_blight | Gap (antibiotic-restriction issue suspected, not confirmed) |
| jowar_smut | Loaded |
| jowar_downy_mildew | Loaded |
| jowar_anthracnose | Gap |
| jowar_grain_mold | Gap |

3 of 11 diagnosable cotton/soybean/jowar targets loaded. 2 are not chemistry
gaps at all (viral). 6 are genuine open gaps.
