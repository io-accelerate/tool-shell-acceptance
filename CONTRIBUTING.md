## Contributing

Thank you for helping improve the shell acceptance harness! This document covers maintainer-focused workflows that go beyond the day-to-day usage described in [`README.md`](README.md).

### Use a local `lib/` checkout

When iterating on changes to the harness itself, point the example runner at a local copy of [`lib/`](lib) so that each invocation mirrors your latest edits into the cache:

1. Clone this repository and make your changes under `lib/`.
2. In the directory where you run `tests/run.sh`, set `localLib` in `run.conf` to the absolute path of your checkout:
   ```ini
   localLib=/path/to/tool-shell-acceptance/lib
   ```
3. Invoke `./run.sh` as usual. The runner will `rsync` your local library into `.cache/` before each execution. If `distributionUrl` is also set, `localLib` takes precedence.

### Cut a new release

To publish an updated harness bundle for downstream suites:

1. Update `version.properties` with the new semantic version.
2. Commit all relevant changes.
3. Tag the release and push both the tag and branch:
   ```bash
   export RELEASE_TAG="v$(cut -d= -f2 version.properties)"
   git tag -a "${RELEASE_TAG}" -m "${RELEASE_TAG}"
   git push --tags
   git push
   ```

The automation that consumes tags can then package and distribute the refreshed `functions.sh` bundle.
