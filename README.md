<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/{{OPENSSF_PROJECT_ID}}/badge)](https://www.bestpractices.dev/projects/{{OPENSSF_PROJECT_ID}}) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/hyperpolymath/fraying-model-computational-testbed/badge)](https://securityscorecards.dev/viewer/?uri=github.com/hyperpolymath/fraying-model-computational-testbed)

> [!NOTE]
> This repository is a template. Placeholder tokens like `hyperpolymath`,
> `fraying-model-computational-testbed`, and `fraying-model-computational-testbed` are expected before running `just`
> `init`.

# Overview

This template now uses a split maintenance model:

- Authoritative session protocols live centrally in
  `standards/session-management-standards`.

- This repo keeps only thin local integration (Justfile aliases, local
  hooks, coordination bindings, and repo-local checks).

- Runtime session artifacts are generated per working repository in
  `.session/`.

# Session Management Integration

Canonical command model:

- `intake` `repo` `<path>`

- `checkpoint` `change` `<path>`

- `verify` `maintenance` `<path>`

- `verify` `substantial` `<path>`

- `verify` `release` `<path>`

- `close` `planned` `<path>`

- `close` `urgent` `<path>`

- `recover` `repo` `<path>`

- `handover` `full` `<path>`

- `handover` `split` `<path>`

- `handover` `model` `<path>`

- `handover` `human` `<path>`

Local binding files in this template:

- `session/dispatch.sh`

- `session/custom-checks.k9`

- `session/local-hooks.sh`

- `session/README.md`

- `coordination.k9`

Run `just` `session-help` for local aliases.

# ABI/FFI Seam Layout

The template keeps a verified interface seam split:

- ABI (Idris2): `src/interface/Abi/*.idr`

- FFI (Zig): `src/interface/ffi/src/*.zig`

- Generated artifacts: `src/interface/generated/`

# Repository Layout

| Path | Purpose |
|----|----|
| `.machine_readable/` | Machine-readable policy and project metadata. |
| `session/` | Thin local bindings to central session-management standards. |
| `coordination.k9` | Local coordination wiring to canonical session commands. |
| `docs/` | Human-facing technical and governance documentation. |
| `src/interface/` | ABI/FFI/generated seam scaffolding. |
| `verification/` | Proof and verification scaffolding. |

# Quick Start

```bash
just init
just verify
just session-help
```

# Documentation

- <a href="AUDIT.adoc" class="adoc">AUDIT</a> — local audit gate summary

- <a href="EXPLAINME.adoc" class="adoc">EXPLAINME</a> — template
  claim-to-implementation map

- [session/README.md](session/README.md) — session binding usage

- [docs/governance/README.adoc](docs/governance/README.adoc) — governance
  docs index

- <a href="CONTRIBUTING.md" class="md">CONTRIBUTING</a>

- <a href="SECURITY.md" class="md">SECURITY</a>

# License

SPDX-License-Identifier: CC-BY-SA-4.0 See [LICENSE](LICENSE).
