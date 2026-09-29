# Contributing

## Module versions in the README

README snippets use a version range, for example `version = "~> 0.11"`. Do not change them to an exact version, and do not bump them for each release. A range stays correct across releases. An exact version is out of date after the next one.

Change the range only when a snippet needs a newer minor version, for example when it uses a new input.

The files in `examples/` pin one version. If you change it, also check the `aws` provider version in that example's `versions.tf`. It must match what that module version needs.

## Releasing

1. Merge the changes to `main`.
2. Choose the version. New inputs or behaviour: next minor (`0.11.0` → `0.12.0`). Dependency bumps and fixes: next patch (`0.11.0` → `0.11.1`).
3. Tag `main` with a signed, annotated tag and push it:
   ```
   git tag -s v0.12.0 -m "v0.12.0" origin/main
   git push origin v0.12.0
   ```
4. The `Release` workflow creates the GitHub Release with generated notes.
5. The Terraform Registry picks up the new tag by itself. It can take a few minutes.
