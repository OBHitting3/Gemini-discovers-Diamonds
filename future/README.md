# future

Combined monorepo snapshot for OBHitting3 repositories.

## Layout

- `repos/<repository-name>/` contains the tracked files imported from that source repository.
- `manifest.json` records source URLs, default branches, import status, and file counts.
- `validate-manifest.js` checks the manifest and confirms no nested Git metadata was imported.

## Validate

```bash
node future/validate-manifest.js
```

## Imported repositories

| Repository | Default branch | Status | Files |
| --- | --- | --- | --- |
| [OBHitting3/55-_AI_Intergration](https://github.com/OBHitting3/55-_AI_Intergration) | claude/upgrade-ai-bridge-sync-JqMHc | imported-from-github | 94 |
| [OBHitting3/Content_Shield](https://github.com/OBHitting3/Content_Shield) | main | imported-from-github | 84 |
| [OBHitting3/Faceless_Shorts](https://github.com/OBHitting3/Faceless_Shorts) | main | imported-from-github | 37 |
| [OBHitting3/FreeLance](https://github.com/OBHitting3/FreeLance) | none | empty-no-default-branch | 1 |
| [OBHitting3/Gemini-discovers-Diamonds](https://github.com/OBHitting3/Gemini-discovers-Diamonds) | main | imported-from-current-worktree-head | 206 |
| [OBHitting3/Iron-Forge-Studios](https://github.com/OBHitting3/Iron-Forge-Studios) | claude/weekly-activity-summary-nEI31 | imported-from-github | 29 |
| [OBHitting3/joshua7](https://github.com/OBHitting3/joshua7) | main | imported-from-github | 33 |
| [OBHitting3/yt-autopilot](https://github.com/OBHitting3/yt-autopilot) | main | imported-from-github | 5 |
