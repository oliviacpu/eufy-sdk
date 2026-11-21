# About this fork

A personal fork of [mega-yfue/eufy-sdk](https://github.com/mega-yfue/eufy-sdk), used by one
[ha-eufy-sdk-bridge](https://github.com/oliviacpu/ha-eufy-sdk-bridge) install behind a HomeBase 3 with a drive
fitted. Its `main` is upstream's newest `beta-*` branch plus the changes listed below. Upstream's README,
`CONTRIBUTING.md`, `AGENTS.md` and `docs/` still apply.

## Rules for changes

- **Nothing is sent upstream.** Changes still stay upstream-shaped: one change and its tests per commit, written to
  upstream's coding standards, so any one of them could be cherry-picked onto an upstream branch later.
- **Upstream behaviour stays the default.** A new option does nothing until it's passed; existing calls behave as
  upstream's do.
- **Work happens on `fork/*` branches**, merged into `main` by pull request in this repository.
- **Tests:** Node 24 (`.nvmrc`), `npm ci`, then `npm run verify`. On macOS `guard:capability-ownership` fails before any
  fork change (it calls GNU `paste`); CI runs on Linux.

## Upstream, releases and installs

- **Upstream sync:** `.github/workflows/fork-sync.yml` runs daily at 08:17 UTC. It merges upstream's newest `beta-*`
  branch into `main` when `main` doesn't have it yet, runs `npm run verify`, pushes, and releases. A merge that
  conflicts, fails verification, or changes upstream's workflow files (which the workflow's token may not push) opens
  or updates one issue labelled `upstream-sync`; nothing is pushed. Merge by hand then: `git fetch upstream`, branch
  from `main`, `git merge upstream/beta-X.Y.Z`, fix, open a pull request here, merge.
- **Release:** `.github/workflows/fork-release.yml`, run by the sync or by hand. It verifies, sets the package version
  to `<upstream beta version>-oliviacpu.<YYYYMMDD>[.N]`, packs it, tags `main` `oliviacpu-YYYY.MM.DD[.N]`, and creates
  a GitHub Release with the `.tgz` attached. Upstream's tags are `v*`, so the two never collide.
- **Install:** the bridge fork depends on a release asset by URL, for example
  `https://github.com/oliviacpu/eufy-sdk/releases/download/oliviacpu-2026.11.21/mega-yfue-eufy-sdk-0.6.0-oliviacpu.20261121.tgz`.
  The package name stays `@mega-yfue/eufy-sdk`, so imports don't change.
- **Upstream's workflows are disabled here** except `ci.yml`: `release.yml` publishes to npm, `docs.yml` deploys pages,
  and `merge-policy.yml` and `pr-template.yml` police upstream's own pull requests. After a manual upstream merge, check
  `gh workflow list --all` for new ones.

## Changes in this fork

Newest first.
