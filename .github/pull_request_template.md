## What this changes

<!-- One or two sentences. What moved, and why. -->

## Verification — required

`docs/DESIGN.md` §13:

> A feature is verified when a live HTTP response is pasted showing the expected
> output. Import success, build success, and "I ran it" are not verification.

**Paste the live response that verifies this change:**

```
<!-- curl command and its full output, or the equivalent for your stack -->
```

Before you trust that output, confirm which process answered and when it
started. A stale server from a previous session has previously made working
fixes appear broken for hours.

```bash
# Linux / macOS
lsof -i :8000 && ps -o pid,lstart,cmd -p <pid>
```

```powershell
# Windows
Get-NetTCPConnection -LocalPort 8000 -State Listen | ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, Path, StartTime }
```

<!--
If this PR genuinely has no HTTP surface — a migration, a README, a scaffold
commit — say so here instead, and paste whatever does verify it: the migration
output, the test run, the screenshot.
-->

## Checklist

- [ ] `backend/`: `pytest` passes and `ruff check app tests alembic` is clean
- [ ] No constant redeclared outside `backend/app/config.py` (`docs/DESIGN.md` §6)
- [ ] `backend/app/contracts/` unchanged, or the team agreed to change it
- [ ] I did not edit a module I do not own — see CODEOWNERS
