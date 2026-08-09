---
name: refresh-patch-stack
description: Refresh this fork's patch stack against upstream r-lib/cpp11 — merge the mirrored `main` into every patch branch, resolve conflicts, retire patches upstream has superseded, and rebuild `fork`. Use when asked to refresh, sync, or update the patch stack, or when a scheduled routine fires for it.
---

# Refresh the patch stack

This fork is a patch stack on top of
[`r-lib/cpp11`](https://github.com/r-lib/cpp11).
This skill brings it up to date with upstream.

Read [`.github/PATCHSTACK.md`](../../../.github/PATCHSTACK.md) first
if you are not already familiar with the branch layout.

## Layout

- `main` is a 1:1 mirror of upstream, hard-reset by the Pull app.
  Never commit to it, and never merge into it.
- `a-*`, `b-*`, `f-*` are the patch branches,
  one logical change each, based on `main`.
- `fork` is the default branch:
  `main` plus every patch, squashed in lexicographic branch order.
  It is rebuilt from scratch here and must never be merged into by hand.
- A long-lived draft pull request from `fork` into `main` provides CI.
  Do not close it;
  pushing `fork` is what re-runs the checks.

## When there is nothing to do

Fetch first, then compare:

```bash
git fetch --prune origin
git fetch --prune upstream    # https://github.com/r-lib/cpp11.git
git rev-parse origin/main upstream/main
```

If `origin/main` has not moved since `patchstack/upstream-base`,
and no patch branch has changed,
stop and report that the stack is current.
Do not rebuild `fork` just to produce a commit.

If `origin/main` still lags `upstream/main`,
the Pull app has not run yet.
Say so and stop:
mirroring is the app's job, not this skill's.

## Refreshing a patch branch

For each `a-*`, `b-*`, `f-*` branch, **merge** `origin/main` into it.
Merge rather than rebase:
the merge commit is where the conflict resolution is recorded,
and it is what the next refresh builds on.

```bash
git checkout -B "$branch" "origin/$branch"
git merge --no-ff origin/main
```

A clean merge that leaves the branch's net effect unchanged
needs no further thought — push it.

### When it conflicts

Resolve toward **the fork's intent on upstream's new shape**.
Upstream reformats (Air for R, clang-format for C++)
and restructures;
re-apply the patch on top of that rather than reverting it.

Never resolve a conflict by taking the fork's whole file back.
That silently drops upstream's work in the same file.

### When a patch has been superseded

Upstream sometimes implements a patch's feature itself,
or fixes the bug it worked around.
Then the resolution **is the removal of the feature**:
take upstream's version of every file the patch touched,
so the branch's tree ends up equal to `origin/main`'s.

Say so explicitly in the merge commit message,
and say *why* — which upstream pull request or issue supersedes it,
and how you established that.
A patch retired without that reasoning
is indistinguishable from one dropped by accident.

Two signals worth checking before concluding a patch still earns its place:

- the upstream pull request that carries it, if there is one,
  may have been closed;
- upstream's `NEWS.md` may cite the issue the patch addresses.

An empty branch is not deleted here.
Leave it;
the next patchstack sync detects it, deletes it,
and records the disposition in `refs/notes/patchstack`.

## Verifying

Before pushing anything, from the rebuilt `fork`:

```bash
air format . && git diff --exit-code
clang-format --dry-run -Werror $(git diff --name-only origin/main -- '*.hpp' '*.cpp')
Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_dir("tests/testthat", reporter = "summary")'
Rscript -e 'devtools::install(quiet = TRUE, upgrade = FALSE)'
Rscript -e 'devtools::clean_dll("./cpp11test"); devtools::test("./cpp11test", reporter = "summary")'
```

The C++ suite takes several minutes and is the one that matters most:
most of the stack is header changes,
and the R suite does not compile them.

Report a failure rather than working around it.
A red suite means the refresh stops and a human looks at it;
it does not mean the offending patch gets dropped.

## Rebuilding `fork`

`fork` is `main` plus each patch's net change,
applied in lexicographic branch order:

```bash
git checkout -B fork origin/main
git diff origin/main "origin/$branch" | git apply --index -   # per branch, in order
git commit -m "<the patch's subject>"
```

Skip a branch whose net change against `origin/main` is empty.

The patches are expected to commute —
each applies to `main` on its own,
and the order changes nothing.
If applying one fails,
two patches have started to overlap:
report that rather than forcing it through,
because the squashed result would then depend on ordering
and stop being reproducible.

## Publishing

Push the patch branches and `fork` together:

```bash
git push --atomic --force-with-lease origin <each changed branch> fork
```

`--atomic` so a stale lease leaves every branch as it was
rather than half a stack.
`--force-with-lease` because `fork` is rebuilt
and a refreshed patch branch may be rewritten.

## Reporting

Say, briefly:

- which upstream commits arrived;
- for each patch: clean, resolved (and how), superseded (and why), or failed;
- the verification results;
- anything a human needs to decide.

If every patch merged cleanly and the suites passed,
that is a short report.
Keep it short.
