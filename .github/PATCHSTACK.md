# The patch stack

This is a fork of [r-lib/cpp11](https://github.com/r-lib/cpp11) that carries a
handful of changes upstream does not ship.
It is maintained as a *patch stack*:
one branch per change,
each a single commit on top of upstream,
and one branch that is upstream plus all of them.

## The branches

- **`main`** is a 1:1 mirror of `r-lib/cpp11`'s `main`.
  The [Pull app](https://pull.git.ci/) hard-resets it on every sync
  ([`pull.yml`](pull.yml)),
  so a commit made here is discarded the next time upstream moves.
  Never commit to it.
- **`fork`** is the default branch and the one to install:
  `main` plus every patch, squashed in lexicographic branch order.
  It is rebuilt from scratch on each sync — never commit to it either,
  and never merge into it.
- **`a-fork-infra`**, **`b-*`**, **`f-*`** are the patch branches,
  each based on `main`.
  `a-` is this fork's own infrastructure (it sorts first, so it lands first),
  `b-` is a bug fix, `f-` is a feature.
  A working branch under any other name is left alone.

## CI

A long-lived **draft pull request from `fork` into `main`** runs the checks.
Upstream's `R-CMD-check` triggers on `pull_request` against `main`,
so the stack is checked without this fork editing a workflow file —
which also keeps `.github/workflows/` identical to upstream's
and out of the rename surface.

Do not close that pull request and do not merge it.
Merging would put the stack on `main`,
and the Pull app would discard it on the next mirror.
Pushing `fork` is what re-runs the checks.

## The refresh

[`.claude/skills/refresh-patch-stack/`](/.claude/skills/refresh-patch-stack/SKILL.md)
is a Claude skill that merges the mirrored `main` into every patch branch,
resolves the conflicts, retires patches upstream has superseded,
rebuilds `fork`, and pushes.
A scheduled routine invokes it;
it can also be run by hand.

It is a skill rather than a GitHub Actions workflow for two reasons.
Conflict resolution needs judgement —
upstream reformats and restructures,
and re-applying a patch on the new shape is not a mechanical merge.
And a workflow that rebuilds `fork` would have to push
`.github/workflows/` back to the branch,
which `GITHUB_TOKEN` may not do,
so it would need a personal access token to exist at all.

A patch that cannot be resolved is reported and left alone,
so one stuck patch never blocks the others.
A patch whose change has landed upstream ends up empty;
the branch is deleted and the disposition recorded
in `refs/notes/patchstack`.

## Adding a patch

```bash
git fetch origin
git switch -c f-my-change origin/main
# ... one commit ...
git push -u origin f-my-change
```

The next sync folds it into `fork`.
Keep it to a single commit where you can:
the stack is easier to read,
and the squash into `fork` is what everyone consumes anyway.

Each patch is a candidate for upstream.
Opening a pull request from its branch against `r-lib/cpp11`
costs nothing here — the branch stays exactly where the sync expects it —
and a merged patch cleans itself up on the following run.

## Installing

```r
pak::pak("krlmlr/cpp11")
```

`fork` is the default branch, so this installs the whole stack.
It is also built by
[krlmlr.r-universe.dev](https://krlmlr.r-universe.dev),
which is the faster route:

```r
install.packages("cpp11", repos = c("https://krlmlr.r-universe.dev", getOption("repos")))
```
