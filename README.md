# tool-shell-acceptance
Acceptance test tool based on running shell commands




### To build artifacts in Github

Commit all changes then:
```bash
export RELEASE_TAG="v$(cat version.properties | cut -d= -f2)"
git tag -a "${RELEASE_TAG}" -m "${RELEASE_TAG}"
git push --tags
git push
```