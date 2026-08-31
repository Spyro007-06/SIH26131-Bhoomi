# seed/corpus/

**Phase 4 status:** `distinguishing_cues.json` has its first real entry (`blast`
/ `brown_spot`) and `documents.json` (new, this phase -- no loader script exists
for either file yet, that's the next owner's job) has three sourced chunks for
`blast`. Everything else named below is still `[]` / unauthored: the other
paddy targets (`bacterial_leaf_blight`, `yellow_stem_borer`,
`brown_planthopper`) have no cue and no corpus content yet, and cotton /
soybean / jowar cannot be authored at all against the current schema --
`CorpusDoc.crop` and `DistinguishingCue.answer_yes_implies` are native Postgres
enums bound to the frozen `Crop` / `TargetLabel` (paddy, 5 labels), same wall
Phase 3 hit on `registered_use.csv`.

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
| `target` | One of the five `target_label` values, `docs/API_CONTRACT.md` §1 |
| `crop` | `paddy` in v2 |
| `content` | The text that gets embedded and quoted |
| `embedding` | `vector(1024)`, BGE-m3. Generated at load time, not authored |

Retrieval filters by `crop` and `target`, so a chunk with either missing is
invisible to the pipeline.

**Do not strip non-ASCII when preparing content.** `docs/DESIGN.md` §8: a
normalisation step that drops Devanagari produces a zero vector, a degenerate
similarity score that sails past the relevance threshold, and confident
fabricated advice. This has bitten this codebase before.

### `documents.json` (Phase 4, new)

Pre-load staging for `CorpusDoc`, same idea as `distinguishing_cues.json`: a
JSON array of objects using the field names in the table above minus
`embedding` (generated at load time, not authored). No loader script exists
yet -- whoever writes `scripts/load_corpus.py` should follow
`scripts/load_registered_use.py`'s validate-and-refuse shape: a row missing
`source` or `reviewed_on` is not auditable and does not belong in a table an
advisory gets composed and cited from.

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
`blast`/`brown_spot` entry's `doc_id` is `null` in the JSON (no row exists to
point at yet, since there's no loader) but is authored from `documents.json`'s
"Rice Blast (Magnaporthe oryzae) -- Symptoms and Identification" entry --
whoever writes the loader should set `doc_id` to that row's id once both files
are loaded, in id-assignment order (`documents.json` first).

## Format

`distinguishing_cues.json` is a JSON array of objects using the field names
above.
