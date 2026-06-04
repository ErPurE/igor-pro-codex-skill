# Igor Automation Skill

Codex skill for automating WaveMetrics Igor Pro on Windows and building scientific data-analysis workflows.

The skill focuses on:

- Igor Pro COM automation from PowerShell.
- `.ipf` procedure-writing conventions.
- Wave, matrix, graph, layout, image, color scale, fitting, and error-bar workflows.
- MATLAB/CSV/TXT/HDF5 data import patterns.
- MATLAB `.fig` reconstruction through a MATLAB extraction bridge plus Igor plotting.
- Publication-style figure export with live Igor graphs and saved `.pxp` experiments.

This repository intentionally contains no private lab figures, extracted data, exported images, or Igor experiment files. The bundled smoke test uses synthetic sine/cosine waves.

## Install

Copy the skill folder into your Codex skills directory:

```powershell
$skillHome = Join-Path $env:USERPROFILE ".codex\skills"
New-Item -ItemType Directory -Force -Path $skillHome | Out-Null
Copy-Item -Recurse -Force ".\igor-automation" $skillHome
```

Restart Codex or reload skills, then use:

```text
Use $igor-automation to connect to Igor Pro and export a polished test graph.
```

## Requirements

- Windows.
- Igor Pro with the `IgorPro.Application` COM server registered.
- PowerShell.
- MATLAB only when reconstructing MATLAB `.fig` files.

## Smoke Test

After installing, run:

```powershell
$skillRoot = Join-Path $env:USERPROFILE ".codex\skills\igor-automation"
powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\igor_com_smoke.ps1" -OutputDir ".\igor-outputs"
```

Expected generated files:

- `codex_igor_graph.png`
- `codex_igor_layout.png`
- `codex_igor_smoke_test.pxp`

## Privacy Guard

Before publishing changes, check that no private data was staged:

```powershell
git status --short
git ls-files
```

Do not commit `.fig`, `.mat`, `.pxp`, `.h5`, `.ibw`, `.itx`, exported figures, or lab-specific outputs unless they are public synthetic examples.

## License

MIT. Use, modify, and share freely.
