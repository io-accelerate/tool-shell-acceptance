# tool-shell-acceptance
Acceptance test tool based on running shell commands

## Purpose

- Provide confidence that the deployed system works end-to-end.
- Cover integration points and enforcement rules that local emulators or mocks cannot.
- Keep tests **few and scenario-based**: each test validates multiple behaviors at once to reduce maintenance.

## Install 

create a folder, say "shell-acceptance"
provide instructions on how to download run.sh from the Github release
instruct how to create the run.conf file, start with the run.conf.sample

explain that the first run downloads functions.sh


## Structure

```
shell-acceptance/
├─ .cache/functions.sh   # the lib
├─ snapshots/            # expected outputs (checked in)
├─ artifacts/            # actual outputs from last run (ignored)
├─ 00-sanity.sh          # example test: environment sanity check
├─ 10-example.sh         # example test: system call with assertions
├─ run.conf              # test config
└─ run.sh                # test runner
```

## First tests

Show the hello world

## How It Works

- Each test script (`*.sh`) executes a **scenario**: runs one or more commands, captures output, normalizes volatile fields (timestamps, request IDs), and compares against a **snapshot**.
- Snapshots live in `snapshots/` and are versioned.
- Test runs produce artifacts in `artifacts/` for inspection but not version control.

## Running Tests

Run all scenarios in order:

```bash
./run.sh
```

Run a specific test:

```bash
./run.sh 10-example.sh
```

## Snapshots

Snapshots define the **expected outputs**.
- If actual output differs, you’ll see a diff and the test will fail.
- If the change is correct and intentional, you can update the snapshot:

```bash
UPDATE_SNAPSHOTS=1 ./run.sh 10-example.sh
```

This replaces the old snapshot with the new normalized output.

## Guidelines

- **Few, meaningful tests**: each scenario should cover multiple behaviors.
- **Keep inputs explicit**: tokens, payloads, and parameters should live in the test script or `env.sh`.
- **Normalize outputs**: redact timestamps, request IDs, or signatures to make snapshots stable.
- **Never commit secrets**: sanitize snapshots so no sensitive data is stored.


### To build artifacts in Github

Commit all changes then:
```bash
export RELEASE_TAG="v$(cat version.properties | cut -d= -f2)"
git tag -a "${RELEASE_TAG}" -m "${RELEASE_TAG}"
git push --tags
git push
```