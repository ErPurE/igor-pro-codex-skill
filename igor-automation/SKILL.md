---
name: igor-automation
description: Automate WaveMetrics Igor Pro on Windows and build Igor Pro scientific data-analysis workflows. Use when the user asks to connect to Igor or Igor Pro, run Igor commands, write .ipf procedures, import MATLAB/CSV/TXT/HDF5 data, analyze waves or matrices, make S21/spectrum/2D-map/fitting/error-bar/color-scale plots, create Nature-style graphs or page layouts, export figures, save PXP experiments, or troubleshoot Igor COM/ZeroMQ automation.
---

# Igor Automation

## Quick Start

Use Windows COM automation first. Igor Pro exposes `IgorPro.Application`; GUI clicking is a fallback only when COM is unavailable.

Run the bundled smoke test when you need to verify the connection, graphing, layout, export, and PXP save loop:

```powershell
$skillRoot = Join-Path $env:USERPROFILE ".codex\skills\igor-automation"
powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\igor_com_smoke.ps1" -OutputDir ".\igor-outputs"
```

The smoke test creates `codex_igor_graph.png`, `codex_igor_layout.png`, and `codex_igor_smoke_test.pxp`.

## Workflow

1. Resolve the user's `.lnk` or executable path if they provide one. Otherwise rely on the registered `IgorPro.Application` COM server. The smoke-test script checks the standard all-users Start Menu shortcut by default and accepts `-ShortcutPath` for site-specific installations.
2. Prefer attaching to an existing COM instance:

```powershell
$app = [Runtime.InteropServices.Marshal]::GetActiveObject("IgorPro.Application")
```

3. If there is no active object, start Igor through COM:

```powershell
$app = New-Object -ComObject IgorPro.Application
$app.Visible = $true
```

4. Send Igor commands with `$app.Execute("...")`. Keep each command small so a COM `E_FAIL` can be traced to the exact Igor command.
5. Export through Igor itself with `SavePICT`, not screenshots. Validate output files by checking size and image dimensions.
6. For page layout work, render and inspect the exported layout image; layout objects can overlap even when commands succeed.

## Scientific Data Analysis Mode

When the user asks for Igor analysis, plotting, figure templates, or `.ipf` code, treat this skill as an "Igor Pro Scientific Data Analysis Skill", not merely a COM automation helper.

- Prefer durable Igor artifacts: a reusable `.ipf` procedure, a saved `.pxp`, and exported preview PNG/PDF when appropriate.
- Keep raw data immutable and put derived waves in a separate data folder, for example `root:raw:<dataset>` and `root:analysis:<dataset>`.
- Preserve units and independent variables with dimension scaling, wave notes, and explicit axis labels. Do not leave frequency, field, delay, or position as anonymous point indices.
- For complex microwave data, keep the complex wave when available, then derive magnitude in dB and phase waves. Do not discard phase unless the user explicitly asks.
- For publication figures, build live Igor graphs and layouts, then export previews. Avoid screenshots and flattened picture-only layouts.
- If a requested API or third-party `.ipf` helper is not locally installed, use it only as a reference pattern and state that it was not executed.

## Reference Stack

Use this reference order when writing or checking Igor procedure code:

- WaveMetrics official docs: command reference for operations, functions, and keywords; programming overview for procedure structure, wave references, data folders, graphing, analysis, HDF5, and Python integration.
- `wshanks/Igor-ProW`: reference examples for loading data, wave manipulation, graph macros, averaging/background removal, fitting, and plotting. Do not assume it is installed.
- `yamad/igorutils`: reference examples for more consistent utility APIs around waves, graph/window helpers, colors, file paths, data folders, and procedure utilities. Do not assume it is installed.
- `AllenInstitute/ZeroMQ-XOP`: use for network or cross-process Igor control through ZeroMQ plus JSON when COM is not enough. Verify the XOP and JSON support are installed before relying on it.

If importing external code into the user's skill or project, record the upstream URL, commit or release, and license. Prefer small local wrappers over wholesale vendoring.

## IPF Procedure Rules

- Start new procedure files with `#pragma rtGlobals=3`; add `#pragma TextEncoding = "UTF-8"` when non-ASCII labels or comments are unavoidable.
- Prefer compiled `Function` code over old-style `Macro` code. Use macros mainly for Igor-created window recreation or very small menu entry points.
- Use ASCII object names for waves, graphs, layouts, and data folders. Put Greek symbols, micro signs, and journal labels in graph labels, not object names.
- Use explicit references: `Wave`, `Wave/C`, `Wave/T`, `NVAR`, `SVAR`, and `DFREF`. Avoid relying on implicit global waves inside reusable functions.
- Validate data before analysis with `WaveExists`, `WaveDims`, `DimSize`, `DimOffset`, `DimDelta`, `DataFolderExists`, and `ParamIsDefault`.
- Use `SetScale/I` or `SetScale/P` on waves and matrices so images and traces carry physical coordinates.
- Wrap data-folder changes. If a function changes `SetDataFolder`, save the old folder and restore it before returning.
- Keep analysis functions side-effect-light: inputs in arguments, outputs named explicitly or returned through a destination data folder.

Minimal `.ipf` skeleton:

```igorpro
#pragma rtGlobals=3
#pragma TextEncoding = "UTF-8"

Function/DF CodexEnsureDataFolder(folderPath)
	String folderPath
	NewDataFolder/O $folderPath
	DFREF dfr = $folderPath
	return dfr
End

Function CodexAssertWave1D(w, waveLabel)
	Wave/Z w
	String waveLabel
	if (!WaveExists(w) || WaveDims(w) != 1)
		Abort "Expected 1D wave: " + waveLabel
	endif
End
```

## Data Import And Interchange

Use a path-first workflow. Create an Igor symbolic path with `NewPath`, then load by file name. Remember that `LoadWave/P=...` expects the symbolic path name, not a raw filesystem path.

Delimited CSV or TXT with column labels:

```igorpro
NewPath/O/Q rawPath, "D:\\data\\run001\\"
LoadWave/J/D/W/A/O/Q/P=rawPath "s21_trace.csv"
Print S_waveNames
```

General numeric text when headers are irregular:

```igorpro
NewPath/O/Q rawPath, "D:\\data\\run001\\"
LoadWave/G/D/O/Q/P=rawPath "spectrum.txt"
Print S_waveNames
```

MATLAB or Python multidimensional data:

- Prefer HDF5 for matrices, maps, complex data, and metadata. MATLAB `-v7.3`, Python `h5py`, and Igor `HDF5OpenFile`/`HDF5LoadData` are the least lossy path.
- Use CSV only for simple 1D traces or small 2D tables where units and metadata can be captured separately.
- Use JSON/YAML sidecars for metadata such as frequency unit, field unit, delay zero, sample name, power, temperature, and calibration state.

HDF5 load pattern:

```igorpro
Variable fileID
HDF5OpenFile/R/Z fileID as "D:\\data\\run001\\s21_map.h5"
if (V_Flag == 0)
	HDF5LoadData/O fileID, "/s21_complex"
	HDF5LoadData/O fileID, "/freq_GHz"
	HDF5LoadData/O fileID, "/field_mT"
	HDF5CloseFile fileID
endif
```

Python/MATLAB handoff rules:

- Python or MATLAB should do raw instrument parsing and write clean HDF5/CSV plus metadata; Igor should make final analysis waves, graphs, layouts, and publication exports.
- For one-off automation from Python, use COM on Windows and send small Igor commands. For remote streaming or language-neutral control, evaluate ZeroMQ-XOP only after installation is confirmed.
- Never paste large numeric arrays into chat or `.ipf`; write them as files and load them into Igor.

### MATLAB `.fig` Bridge

Igor does not directly read MATLAB `.fig` files as editable Igor graphs. Use MATLAB as the extraction bridge, then use Igor for reconstruction and final export.

Validated local workflow for MATLAB `.fig` reconstruction:

- Open `.fig` with MATLAB `openfig(..., "invisible")`, export a MATLAB reference PNG, and traverse figure children.
- Extract axes metadata: limits, font, box/grid state, labels, `CLim`, and colormap.
- Extract object data:
  - `line`: `XData`, `YData`, style, color, marker.
  - `scatter`: `XData`, `YData`, `CData`, `SizeData`, marker, display name.
  - `surface` or image-like objects: `XData`, `YData`, `ZData`, `CData`, `CLim`, `FaceColor`, `EdgeColor`.
- Write data to HDF5 or CSV plus JSON metadata. HDF5 is preferred for matrix/image data and custom colormaps.
- Account for MATLAB-to-Igor HDF5 2D dimension reversal. In the verified path, writing a MATLAB `rows x cols` matrix loaded into Igor as `N=(cols,rows)`. Write custom colormaps transposed so Igor receives a `256 x 3` RGB color-table wave.
- For MATLAB `surface` with `FaceColor="interp"`, create a high-resolution bilinear render wave for visual fidelity, while also preserving the raw `CData` wave.
- Convert MATLAB TeX labels and legend display names before sending them to Igor annotations:
  - If the MATLAB string contains TeX commands, `_`, `^`, or braces, prefer Igor TeX instead of legacy Symbol-font annotation escapes.
  - Wrap the converted expression as `\\$WMTEX$ <tex> \\$/WMTEX$` inside the Igor command string. The doubled backslashes are required when the annotation text is embedded in an Igor command.
  - Preserve MATLAB-visible spaces by converting whitespace runs inside the TeX expression to explicit TeX spaces: `" "` -> `"\ "`. Without this, Igor TeX treats the label like math and drops spaces, for example `\mu_0 h_1 = 300 nT` becomes visually too tight.
  - Normalize MATLAB text-font commands when possible: `\mathrm{abc}` or `\textrm{abc}` -> `\rm abc`.
  - Verified mapping example:

```text
MATLAB raw:  \mu_0 h_1 = 300 nT
Igor text:   \\$WMTEX$ \mu_0\ h_1\ =\ 300\ nT \\$/WMTEX$
Result:      Greek mu, subscript 0/1, and visible spaces survive in an Igor legend.
```

  - Do not use `\F'Symbol'm` as the primary mapping for MATLAB `\mu`; local validation in Igor Pro rendered it as a literal `m` in the legend. Keep Symbol-font mappings only as a fallback for environments where Igor TeX is unavailable.
- In Igor, load HDF5 with `HDF5OpenFile`/`HDF5LoadData`, then reconstruct:
  - image-like figures with `NewImage/F/N=<name>/S=0 <renderWave>` or `Display; AppendImage`, then `ModifyImage ... ctab={lo,hi,<cmapWave>,0}`.
  - line/scatter figures with `Display`, `AppendToGraph`, `ModifyGraph mode/marker/rgb/lSize`, `SetAxis`, and user tick waves when MATLAB tick labels need to be preserved.
- Export previews with `SavePICT/O/E=-5/RES=300/WIN=<graph>`. Use `SavePICT /W=(left,top,right,bottom)` when the output pixel dimensions must match the MATLAB reference PNG; `/W` is in points, so at 300 dpi use `points = pixels * 72 / 300`.
- Save a `.pxp` containing the imported waves and live Igor graph windows. Report residual visual differences honestly, especially Igor TeX italic/roman choices, legend box metrics, and renderer-specific antialiasing.
- For public repositories or shared examples, do not include private `.fig`, exported preview images, `.pxp` files, or extracted data. Use synthetic waves or public datasets for examples.

## Standard Plot And Analysis Templates

Nature-style baseline for publication-oriented plots:

```igorpro
Display/N=PubTrace yWave vs xWave
ModifyGraph/W=PubTrace gFont="Arial",gfSize=8,gmSize=8
ModifyGraph/W=PubTrace mirror=2,standoff=0,tick=2,btLen=3,lSize=1
Label/W=PubTrace left "Signal (a.u.)"
Label/W=PubTrace bottom "Frequency (GHz)"
SetAxis/W=PubTrace/A
```

S21 trace from complex data:

```igorpro
Make/O/D/N=(numpnts(s21_c)) s21_mag_db, s21_phase_rad
s21_mag_db = 20*log(cabs(s21_c[p]))
s21_phase_rad = atan2(imag(s21_c[p]), real(s21_c[p]))
Display/N=S21Trace s21_mag_db vs freq_GHz
ModifyGraph/W=S21Trace mirror=2,standoff=0,gFont="Arial",gfSize=8,gmSize=8
Label/W=S21Trace left "|S21| (dB)"
Label/W=S21Trace bottom "Frequency (GHz)"
```

Spectrum trace:

```igorpro
Display/N=SpectrumGraph spectrum_dBm vs freq_GHz
ModifyGraph/W=SpectrumGraph mirror=2,standoff=0,gFont="Arial",gfSize=8,gmSize=8
Label/W=SpectrumGraph left "Power (dBm)"
Label/W=SpectrumGraph bottom "Frequency (GHz)"
```

2D map with color scale:

```igorpro
SetScale/I x, freq_GHz[0], freq_GHz[numpnts(freq_GHz)-1], "GHz", s21_db_map
SetScale/I y, field_mT[0], field_mT[numpnts(field_mT)-1], "mT", s21_db_map
Display/N=S21Map
AppendImage/W=S21Map s21_db_map
ModifyImage/W=S21Map s21_db_map ctab={*,*,ColdWarm,0}
ModifyGraph/W=S21Map width={Plan,1,bottom,left},mirror=2,standoff=0
ColorScale/C/N=s21Color/F=0/A=RC/E/W=S21Map image=s21_db_map,frame=0.00
Label/W=S21Map bottom "Frequency (GHz)"
Label/W=S21Map left "Field (mT)"
```

Error bars:

```igorpro
Display/N=ErrorBarGraph meanY vs xWave
ErrorBars/T=0/L=1 meanY Y,wave=(semY,semY)
ModifyGraph/W=ErrorBarGraph mode(meanY)=4,marker(meanY)=19,msize(meanY)=2,lSize(meanY)=1
```

Lorentzian fit template:

```igorpro
Function CodexLorentzianBG(w, x) : FitFunc
	Wave w
	Variable x
	return w[0] + w[1]*((0.5*w[3])^2/((x-w[2])^2 + (0.5*w[3])^2))
End

Make/O/D/N=4 coef = {0, -1, 5.0, 0.02} // offset, amplitude, center, FWHM
FuncFit/Q CodexLorentzianBG coef s21_mag_db /X=freq_GHz /D
Duplicate/O W_coef fit_coef
Duplicate/O W_sigma fit_sigma
```

## Experiment-Specific Templates

Use these as naming and analysis patterns for the user's microwave experiments.

S21 versus pump frequency and external field, `S21(omega_p, H_ext)`:

- Store raw complex data as `s21_c_map` when available, with x scaling as `omega_p` or `freq_GHz` and y scaling as `H_ext`.
- Derive `s21_db_map = 20*log(cabs(s21_c_map))` and `s21_phase_map = atan2(imag(s21_c_map), real(s21_c_map))`.
- Plot magnitude and phase as paired image panels with matched axes and separate color scales.
- Extract resonance tracks by fitting each field slice; save `f_res`, `linewidth`, `amp`, `baseline`, and fit residuals.

Two-dimensional magnetic-field imaging:

- Keep raw camera or scan frames separate from normalized maps.
- Create derived waves such as `ampMap`, `phaseMap`, `contrastMap`, `backgroundMap`, and `roiMask`.
- Set x/y spatial scales in micrometers or millimeters before plotting. Avoid unlabeled pixel axes in final figures.
- Use diverging color tables for signed contrast/phase and sequential color tables for amplitude or power.

Pump-probe delay scan:

- Sort by delay, average repeats, and compute SEM before plotting.
- Use waves such as `delay_ns`, `meanAmp`, `semAmp`, `meanPhase`, `semPhase`.
- Plot points with error bars plus a fit curve; include residuals when the fit is used to support a conclusion.
- Candidate models: single exponential, bi-exponential, damped sinusoid, or exponential recovery with offset. State the model in the figure note or caption draft.

## Command Patterns

Create waves and a graph:

```powershell
$app.Execute('Make/O/N=401 codexX, codexSin')
$app.Execute('codexX = p*0.02*pi')
$app.Execute('codexSin = sin(codexX)')
$app.Execute('Display/N=CodexGraph codexSin vs codexX')
$app.Execute('Label left "Signal (a.u.)"')
$app.Execute('Label bottom "Phase x (rad)"')
```

Export a graph:

```powershell
$app.Execute('NewPath/O/Q/C codexOut, "C:\\path\\to\\output\\"')
$app.Execute('SavePICT/O/E=-5/RES=300/WIN=CodexGraph/P=codexOut as "codex_graph.png"')
```

Create a layout with explicit placement:

```powershell
$app.Execute('NewLayout/N=CodexLayout/W=(100,100,760,900)')
$app.Execute('AppendLayoutObject/R=(72,130,540,440) graph CodexGraph')
$app.Execute('SetDrawLayer/W=CodexLayout UserFront')
$app.Execute('DrawText/W=CodexLayout 72,78,"Title"')
```

Save an experiment:

```powershell
$app.Execute('SaveExperiment /P=codexOut as "codex_igor_smoke_test.pxp"')
```

## Pitfalls

- `New-Object -ComObject IgorPro.Application` can create extra Igor processes. Try `GetActiveObject` before starting a new instance.
- COM `E_FAIL` usually means Igor rejected the command syntax or the command ran in the wrong instance. Report the exact failed command.
- Igor command flags are syntax-sensitive. `SaveExperiment /P=codexOut as "file.pxp"` works; `SaveExperiment/O/P=...` may fail.
- Escape Windows paths inside Igor string literals with doubled backslashes and keep a trailing backslash for directory paths.
- Do not kill existing Igor processes unless the user approves or you are cleaning up processes you just created and verified as test-only.
- `LoadWave/P=rawPath` uses an Igor symbolic path created by `NewPath`; passing a raw filesystem path to `/P` is wrong.
- Check `V_Flag`, `S_waveNames`, and generated waves after every load or fit operation. Do not assume an operation succeeded because COM returned.
- If image/map orientation looks wrong, check dimension scaling and image orientation before transposing data. Use `SetScale`, `NewImage`, or explicit axis reversal deliberately.
- For repeated traces or images from the same wave, Igor uses instance names such as `wave#1`; inspect `TraceNameList`, `ImageNameList`, `TraceInfo`, and `ImageInfo`.
- Color scales are attached to image instance names. If the color scale is blank or wrong, verify the image name with `ImageNameList`.
- For missing-wave errors inside functions, add `Wave/Z` plus `WaveExists` checks before analysis.
- If procedure compilation fails, reduce the function to the smallest failing block and test the exact Igor command in the command line before re-running it through COM.
- When using ZeroMQ-XOP, verify Igor Pro version, XOP installation, JSON support, endpoint, and message schema first; do not mix COM and ZeroMQ in the same workflow unless there is a clear reason.
