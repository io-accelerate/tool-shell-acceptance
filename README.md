# tool-shell-acceptance

A lightweight harness for exercising black-box acceptance scenarios entirely from the command line. The tool runs shell scripts, captures their output, normalizes volatile data, and compares results against committed snapshots so you can verify production-like integrations with confidence.

## Key features

- **Scenario-first shell tests** – write plain `*.sh` scripts that orchestrate calls to your system under test while keeping dependencies explicit and close to the scenarios.
- **Snapshot-driven verification** – expected outputs live in versioned snapshots so that meaningful diffs show up in code review and CI. Update snapshots intentionally with a single flag when behavior changes.
- **Deterministic normalization** – helpers such as [`normalize`](lib/functions.sh) clean timestamps, request IDs, or secrets before comparisons to keep tests stable.
- **Portable harness distribution** – reference a published `functions.sh` bundle or sync the harness from a local checkout. The runner caches downloads automatically and invalidates them when the source changes.
- **Human-friendly logging** – configurable log levels, `log_step`, and `log_cmd` helpers make the test progress readable while still failing fast on errors.

## Installation

1. Create a working directory for your acceptance suite, for example:
   ```bash
   mkdir shell-acceptance
   cd shell-acceptance
   ```
2. Download the latest [`run.sh`](tests/run.sh) from the repository (or from your preferred release location) into that directory and make it executable:
   ```bash
   curl -o run.sh https://raw.githubusercontent.com/<org>/tool-shell-acceptance/main/tests/run.sh
   chmod +x run.sh
   ```
3. Copy [`run.conf.sample`](tests/run.conf.sample) to `run.conf` and edit it to point to the harness distribution you want to use (see below).
4. Start authoring your test scripts (for example `01-hello-world.sh`) next to the runner. Snapshots will be stored under `snapshots/`, and artifacts from the last execution will be stored under `artifacts/`.

> 💡 The first time you run the suite, the harness downloads `functions.sh` into `.cache/`. Subsequent runs reuse the cached file until the configured source changes.

## Configuration

All configuration lives in `run.conf`:

- `distributionUrl`: URL to a downloadable archive or raw file that contains `functions.sh`. When set, `run.sh` downloads the file into `.cache/` and refreshes it automatically when the URL changes.

You must define this property so the runner knows where to fetch the harness. If you are hacking on the harness itself, see [CONTRIBUTING.md](CONTRIBUTING.md) for guidance on using a local checkout during development.

## Usage

### Run all scenarios

```bash
./run.sh
```

### Run a specific scenario

```bash
./run.sh 02-logging.sh
```

### Update snapshots intentionally

When a behavioral change is expected, regenerate the snapshot for the affected test by setting `UPDATE_SNAPSHOTS=1`:

```bash
UPDATE_SNAPSHOTS=1 ./run.sh 03-run-command.sh
```

### Control logging

Set the `LOG_LEVEL` environment variable to `trace`, `debug`, `info`, `warn`, or `error` to tune harness verbosity. For example:

```bash
LOG_LEVEL=debug ./run.sh
```

### Clean cached harness files

The runner automatically refreshes `.cache/` when `distributionUrl` changes. To force a clean slate manually, remove the directory:

```bash
rm -rf .cache/
./run.sh
```

## Project layout

```
shell-acceptance/
├─ .cache/             # cached harness (auto-created by run.sh)
├─ artifacts/          # actual outputs from the last execution (gitignored)
├─ snapshots/          # expected outputs committed to version control
├─ run.sh              # test runner
├─ run.conf            # harness configuration
└─ 01-example.sh       # your scenario scripts (numbered for order)
```

The [`tests/`](tests) directory in this repository contains a fully working example suite, including [`snapshots/`](tests/snapshots) that demonstrate snapshot formats and normalization helpers in action.

## Example scenarios

- [`01-hello-world.sh`](tests/01-hello-world.sh) – ensures the harness itself boots and logs steps correctly.
- [`02-logging.sh`](tests/02-logging.sh) – showcases log level control and multi-step assertions.
- [`03-run-command.sh`](tests/03-run-command.sh) – exercises `run_command` helpers, environment injection, and artifact capture.
- [`04-normalize.sh`](tests/04-normalize.sh) – demonstrates sanitizing volatile values before comparing snapshots.

Run these tests locally with the steps above or in CI to validate that your installation behaves as expected.

For information about developing the harness itself, updating releases, or mirroring a local `lib/` checkout into test runs, refer to [CONTRIBUTING.md](CONTRIBUTING.md).
