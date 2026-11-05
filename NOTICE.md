# Attribution and provenance

- Original project: https://github.com/Lorie7813/codex-usage-card
- Original license: MIT; original copyright notice is preserved in `LICENSE`.
- Base release: `v0.9.4-beta.1`.
- Base archive: `CodexUsageCard-macOS-0.9.4.zip`.
- Verified upstream archive SHA-256:

  ```text
  e41cbb00fd01b785eb0cac73a946115a35dd2d9a2410c196ec7287ce4b1737f8
  ```

The archive is not redistributed here. The readable quota agent derived from it is included under the same MIT license. This repository adds Windows launch/install/uninstall scripts, logon supervision, independent runtime storage, CLI path discovery, tests and documentation.

Windows adaptation published and maintained by Esha-YS. Not affiliated with or endorsed by OpenAI or the upstream author.

## Scope of attribution

| Part | Attribution |
| --- | --- |
| Quota formatting, CLI app-server reader, renderer injection, ring UI and theme design in `agent.cjs` | Derived from Lorie7813/codex-usage-card v0.9.4 and its contributors; upstream MIT notice preserved |
| Windows CLI path discovery and reconnect path selection | Windows adaptation maintained by Esha-YS |
| Windows installer, launcher, logon supervision, guarded startup and uninstall scripts | Windows adaptation maintained by Esha-YS |
| Windows tests, packaging and repository documentation | Windows adaptation maintained by Esha-YS |

Esha-YS's maintainer credit does not claim original authorship of the upstream quota card, its design or inherited code. This repository distributes a derivative Windows adaptation under the upstream MIT terms.
