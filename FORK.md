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

### Indoor Cam S350 (T8416) is mains-powered (2026-11-21)

- **What it changes:** the S350 takes the wired power tier: no live-media battery budget, a persistent P2P session,
  and no battery reads.
- **Cause:** the S350 has no cell but resolves the `battery` capability, and upstream's `MAINS_CAMERA_MODELS` doesn't
  list it, so it was treated as a battery camera.
- **Change:** `T8416` joins `MAINS_CAMERA_MODELS` in `src/model/capabilities/battery.ts`. Test:
  `mains-camera-power.spec.ts`. Replaces a hand-patched `dist/index.js` the bridge install had mounted since
  2026-10-22.

### HomeBase 3 recordings on a fitted drive (2026-11-21)

- **What it adds:** `downloadRecording({ recording, cipherId, storagePath })`. `storagePath` is the `storage_path` the
  station's own `history_record_info` row names. Without it nothing changes.
- **Cause:** upstream builds every HomeBase 3 path on `/zx/emmcdata/`. A HomeBase 3 with a drive fitted stores
  recordings under `/zx/hdd_dataN/` instead, so the station answered -111 (`no-data`) for every one of them.
- **Change:** `homeBase3RecordingPath` takes the storage path only when it is exactly the path built for the
  recording's own name, camera folder and month on `emmcdata` or an `hdd_dataN` volume, so a request still never
  leaves the camera's folder; any other path rejects `invalid-recording` before anything is sent. A HomeBase 2 has one
  volume and does not read it. `src/transport/p2p/recording-download.ts`, `command-router.ts`,
  `src/core/contracts.ts`, `docs/live-media.md`. Tests: `recording-download.spec.ts`,
  `recording-download-router.spec.ts`.
- **Live (T8030 with a 500 GB SSD, 2026-11-21):** asked at `/zx/hdd_data1/CameraNN/<yyyyMM>/<name>/<name>.zxvideo`,
  the station streamed a T8170's 8 s and a T8213's 14 s recordings in full in about 3 s each (111 and 196 frames,
  H.265 and AAC in the clear, finish on channel 255).
