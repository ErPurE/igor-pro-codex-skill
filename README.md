# Igor Automation Skill

[English](#english) | [中文](#中文)

## English

Codex skill for automating WaveMetrics Igor Pro on Windows and building scientific data-analysis workflows.

The skill focuses on:

- Igor Pro COM automation from PowerShell.
- `.ipf` procedure-writing conventions.
- Wave, matrix, graph, layout, image, color scale, fitting, and error-bar workflows.
- MATLAB/CSV/TXT/HDF5 data import patterns.
- MATLAB `.fig` reconstruction through a MATLAB extraction bridge plus Igor plotting.
- Publication-style figure export with live Igor graphs and saved `.pxp` experiments.

This repository intentionally contains no private lab figures, extracted data, exported images, or Igor experiment files. The bundled smoke test uses synthetic sine/cosine waves.

### Install

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

### Requirements

- Windows.
- Igor Pro with the `IgorPro.Application` COM server registered.
- PowerShell.
- MATLAB only when reconstructing MATLAB `.fig` files.

### Smoke Test

After installing, run:

```powershell
$skillRoot = Join-Path $env:USERPROFILE ".codex\skills\igor-automation"
powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\igor_com_smoke.ps1" -OutputDir ".\igor-outputs"
```

Expected generated files:

- `codex_igor_graph.png`
- `codex_igor_layout.png`
- `codex_igor_smoke_test.pxp`

The smoke test starts or attaches to Igor Pro, generates one graph and one layout from synthetic data, and saves a `.pxp`. It does not use real experimental data.

### Privacy Guard

Before publishing changes, check that no private data was staged:

```powershell
git status --short
git ls-files
```

Do not commit `.fig`, `.mat`, `.pxp`, `.h5`, `.ibw`, `.itx`, exported figures, or lab-specific outputs unless they are public synthetic examples.

### License

MIT. Use, modify, and share freely.

## 中文

这是一个用于自动化 WaveMetrics Igor Pro 的 Codex Skill，面向 Windows 上的科学数据分析、图形重建和论文级作图工作流。

这个 skill 主要覆盖：

- 通过 PowerShell 和 `IgorPro.Application` COM 接口自动控制 Igor Pro。
- 编写 `.ipf` procedure 的基本规范和防错规则。
- wave、matrix、graph、layout、image、color scale、拟合、误差棒等常见 Igor 工作流。
- 从 MATLAB、CSV、TXT、HDF5 导入科学数据的推荐流程。
- 通过 MATLAB 提取 `.fig` 内容，再在 Igor 中重建可编辑图形。
- 使用 live Igor graph 和 `.pxp` experiment 导出适合论文或报告的图。

这个公开仓库不会包含任何私有实验 figure、提取后的数据、导出图片或 Igor experiment 文件。自带的 smoke test 只使用合成的 sine/cosine 数据。

### 安装

把 skill 文件夹复制到你的 Codex skills 目录：

```powershell
$skillHome = Join-Path $env:USERPROFILE ".codex\skills"
New-Item -ItemType Directory -Force -Path $skillHome | Out-Null
Copy-Item -Recurse -Force ".\igor-automation" $skillHome
```

重启 Codex 或重新加载 skills，然后使用：

```text
Use $igor-automation to connect to Igor Pro and export a polished test graph.
```

### 依赖

- Windows。
- 已安装 Igor Pro，并注册了 `IgorPro.Application` COM server。
- PowerShell。
- 只有在重建 MATLAB `.fig` 文件时才需要 MATLAB。

### Smoke Test

安装后运行：

```powershell
$skillRoot = Join-Path $env:USERPROFILE ".codex\skills\igor-automation"
powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\igor_com_smoke.ps1" -OutputDir ".\igor-outputs"
```

预期生成文件：

- `codex_igor_graph.png`
- `codex_igor_layout.png`
- `codex_igor_smoke_test.pxp`

这个测试会启动或连接 Igor Pro，用合成数据生成一张 graph、一页 layout，并保存一个 `.pxp`。它不会使用任何真实实验数据。

### 隐私提醒

发布变更前，检查没有误提交私有数据：

```powershell
git status --short
git ls-files
```

不要提交私有 `.fig`、`.mat`、`.pxp`、`.h5`、`.ibw`、`.itx`、导出图片或实验室专用输出。公开示例应使用合成数据或明确可公开的数据。

### License

MIT License。欢迎自由使用、修改和分享。
