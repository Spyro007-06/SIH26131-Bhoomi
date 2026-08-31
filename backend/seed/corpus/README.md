# seed/corpus/

**Status, after the corpus ingestion loader.** `scripts/load_corpus.py` exists
and reads `manifest.json` + markdown documents in this directory into
`CorpusDoc` -- see that script's own docstring for the manifest schema and the
validation rules (target must be an exact `target_label` member, source must
be a real citation, `source_dated` is required). Run
`python scripts/corpus_coverage.py` at any time for a live table of which of
the 26 frozen targets have a corpus chunk and which have a cue.

`documents.json` (Phase 4's three `paddy_blast` chunks) is **not** read by
that loader -- it predates the manifest+markdown shape and is not migrated to
it. It still has no loader of its own. Either convert its three entries into
one markdown document plus a manifest row (the cleanest fix, since it makes
paddy_blast go through the same path as everything else), or write a small
second loader for the old shape. Until one of those happens, `paddy_blast` has
zero rows in `CorpusDoc` despite `documents.json` existing, and
`scripts/corpus_coverage.py` will correctly report it as `has_corpus: NO`.

`distinguishing_cues.json` has one entry (`paddy_blast` / `paddy_brown_spot`)
with `doc_id: null`, authored against a `documents.json` row that was never
loaded. **`CorpusDoc.id` is not stable across corpus reloads** -- the loader's
idempotency is delete-then-reinsert per (doc_id, target), not a per-chunk
upsert (see migration `0009_corpus_doc_id_authoritative`), so every run
assigns fresh UUIDs. A cue's `doc_id` pointing at a specific chunk will go
stale the next time that chunk's document is reloaded. Re-point it after each
reload, or treat `doc_id` as advisory-only until something more stable is
needed.

Everything else named below is still `[]` / unauthored: the other paddy
targets (`paddy_bacterial_leaf_blight`, `paddy_yellow_stem_borer`,
`paddy_brown_planthopper`) have no cue and no corpus content, and of the 21
cotton/soybean/jowar targets the manifest is meant to cover, none has landed
in the working tree as of this loader -- see the loader's own docstring for
confirmation this was checked, not assumed.

**These files were hard blockers with no owner.** `docs/DESIGN.md`
§14 flags them and `docs/PRD.md` §10 repeats it:

> Two blocking inputs have no owner in the current split — the corpus cues and
> the registered-use table. Both are writing work rather than code, which is
> exactly why they get assumed away. Assign at hour 0.

They are empty on purpose. An empty file with the right header nags harder than
a line in a planning doc.

## What is blocked

| File | Blocks | Without it |
|---|---|---|
| corpus documents | F7 advisory, F5 inspection tasks | Every query takes the no-retrieval path. Honest, but the advisory feature does not demo. |
| `distinguishing_cues.json` | F4 the Doubt Doctor | Every ambiguous pair falls through to escalation. The clarify branch never fires. |

Neither absence produces a wrong answer — the system degrades to escalation,
which is the designed behaviour. It degrades to *no feature*, though.

## CorpusDoc

`docs/DESIGN.md` §5. One row per retrievable chunk.

| Field | Notes |
|---|---|
| `title` | Rendered in citations, so write it as the reader should see it |
| `source` | The publication. ICAR PoP, CIB&RC, Maharashtra package of practices |
| `reviewed_on` | Date the source was last checked. Appears in the citation |
| `target` | A `target_label` value -- crop-namespaced as of v3 (`paddy_blast`, not `blast`), `docs/API_CONTRACT.md` §1 |
| `crop` | One of the four crops as of v3: `paddy`, `cotton`, `soybean`, `jowar` |
| `content` | The text that gets embedded and quoted |
| `doc_id` | Migration `0009`. Stable slug for the SOURCE DOCUMENT, distinct from `id` (one chunk). Comes from the manifest, not authored per-chunk |
| `authoritative` | Migration `0009`. `false` on a chunk sourced from a Chemical Management section. Excluded by `app/core/services/corpus.py`'s `authoritative_chunks()`, which is the only read path allowed to feed a chemical rung -- `docs/DESIGN.md` §8 (v3) |
| `embedding` | `vector(1024)`, BGE-m3. **Loaded NULL** by `scripts/load_corpus.py` as of this loader -- no embedding-generation path exists anywhere in this codebase yet (searched; `app.voice.embedding_text.to_embedding_text()` normalises query text, it does not produce a vector). NULL is an honest "not indexed yet"; do not fill it with a different, unvetted model |

Retrieval filters by `crop` and `target`, so a chunk with either missing is
invisible to the pipeline.

**Do not strip non-ASCII when preparing content.** `docs/DESIGN.md` §8: a
normalisation step that drops Devanagari produces a zero vector, a degenerate
similarity score that sails past the relevance threshold, and confident
fabricated advice. This has bitten this codebase before.

### `manifest.json` + markdown documents (the live loader's input)

Not present in the working tree as of this loader -- see
`scripts/load_corpus.py`'s own docstring for the exact schema it reads and
why the 15 delivered documents were not here to check against when it was
written. Once they land: `python scripts/load_corpus.py`, then check
`NAME_MAPPING_NEEDED.md` (generated alongside a run with target-name
mismatches) before assuming a clean load.

### `documents.json` (Phase 4, legacy, not read by the loader)

Pre-manifest staging for `CorpusDoc`: a JSON array of objects using the field
names in the table above minus `doc_id`, `authoritative` and `embedding`. See
the status note at the top of this file -- it needs converting to the
manifest+markdown shape or its own small loader before its three chunks reach
`CorpusDoc`.

## DistinguishingCue

`docs/DESIGN.md` §5 and §7. One row per pair of labels the classifier confuses.

| Field | Notes |
|---|---|
| `cue_text` | The observable sign, in clinical terms |
| `question_text` | The question as the farmer hears it |
| `discriminates` | `[label_a, label_b]` — the pair this cue separates |
| `answer_yes_implies` | Which of the two a "yes" selects |
| `doc_id` | The CorpusDoc this was authored from |

Design rules that constrain how these are written, from `docs/DESIGN.md` §7:

- **Cues are retrieved, not generated.** The question text is authored here,
  alongside the corpus. An LLM composing a differential diagnostic question at
  runtime is exactly the fabrication risk the product exists to avoid.
- **The system asks one question.** Not a decision tree. If one cue does not
  settle it, a human should look. So each cue has to be worth the single
  question it gets.
- `question_text` asks the farmer to do something physical and observable —
  "flip the leaf over, do you see fuzzy grey growth?" — not to self-diagnose.
  `docs/PRD.md` §6 step 4 is the worked example.
- A pair with no cue falls through to escalation. That is correct behaviour, not
  a gap to paper over with a lower-quality cue.

The highest-value pair to author first is `blast` / `brown_spot`: it is the
ambiguous pair in the demo scenario, `docs/PRD.md` §6. Done, Phase 4: the
`paddy_blast`/`paddy_brown_spot` entry's `doc_id` is `null` in the JSON (no row
exists to point at yet, since there's no loader) but is authored from
`documents.json`'s "Rice Blast (Magnaporthe oryzae) -- Symptoms and
Identification" entry -- whoever writes the loader should set `doc_id` to that
row's id once both files are loaded, in id-assignment order (`documents.json`
first).

## Format

`distinguishing_cues.json` is a JSON array of objects using the field names
above.
