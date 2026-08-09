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
  [`patchstack-sync.yml`](workflows/patchstack-sync.yml) picks up
  `b-*` and `f-*` by glob,
  so a working branch under any other name is left alone.

## The sync

[`patchstack-sync.yml`](workflows/patchstack-sync.yml) runs
[krlmlr/patchstack](https://github.com/krlmlr/patchstack) nightly,
and on demand from the Actions tab.
Each run replays every patch branch onto the current `main`,
squashes them into a fresh `fork` in branch order,
and pushes the lot atomically.

A patch that no longer applies is left at its old commit
and dropped from that run's `fork`,
so one broken patch never blocks the others —
resolve it by rebasing that branch onto `main` by hand and pushing it.
A patch whose change has landed upstream replays to nothing;
its branch is deleted and the disposition recorded in `refs/notes/patchstack`.

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
