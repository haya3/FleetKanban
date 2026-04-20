## Summary

<!-- 1–3 bullet points: what changes and why -->

-
-

## Related Issues

<!-- Closes #<issue> / Refs #<issue> -->

## Test plan

<!-- A checklist a reviewer can verify -->

- [ ] `task lint` is green
- [ ] `task test` is green
- [ ] Flutter: `cd ui && flutter analyze` is green
- [ ] (proto changes) ran `task proto:gen:all` and bumped `ProtocolVersion`
- [ ] (sidecar changes) rebuilt `build/bin/fleetkanban-sidecar.exe`
- [ ] Manually verified the scenario on local Windows 11

## Screenshots / Logs

<!-- Screenshots for UI changes; logs for behavior changes -->

## Checklist

- [ ] Left a one-line **why** comment for any non-obvious decision
- [ ] Added an entry under Unreleased in `CHANGELOG.md` for any spec change
- [ ] Reviewed security-affecting changes against the principles in
      [SECURITY.md](../SECURITY.md)
