# yt-dlp PowerShell GUI - AI Coding Instructions

## Project Overview

Multi-mode PowerShell wrapper around `yt-dlp` CLI with WPF GUI support. Enables downloading from 100+ video platforms with format selection, custom naming, time-range extraction, and browser cookie authentication.

## Architecture & Key Components

### Main Entry Point: [yt-dlp.ps1](../yt-dlp.ps1)

- **Core responsibility**: Routes between 4 download modes (list, instant, noprompt, interactive)
- **Key parameters**: `$url`, `$mode`, `$destination`, `$InfoJson`, `$GivenName`
- **Mode workflow**:
  - `list`: Fetch formats → display GUI → user selects → restart with 'max' mode
  - `instant`: Use hardcoded paths (X:\#downloads → UserDownloads)
  - `noprompt`: CLI-only with validation, no GUI
  - `interactive`: Full GUI with all options (default)

### Critical Dependencies

1. **External libraries** (loaded via dot-sourcing):
   - `../#lib/functions.ps1` - Base utilities (Get-UniqueId, Get-Proxy, etc.)
   - `../#lib/functions-forms.ps1` - WPF helper functions
2. **yt-dlp binary**: Must exist at `C:\mega\program-files\yt-dlp\yt-dlp.exe`

### Function Modules

**[yt-dlp_functions.ps1](../yt-dlp_functions.ps1)** - Download logic

- `Get-InfoJson`: Fetches format metadata JSON via yt-dlp (handles cookies, impersonation)
- `Get-DownloadParameters`: Assembles yt-dlp CLI args (formats, cookies, output template, section ranges)
- `Get-OutputTemplate`: Platform-specific filename templates (Facebook → `%(uploader_id)s`, YouTube → `%(uploader_id)s-%(uploader)s`, etc.)
- `Get-OutputFileNames`: Predicts output filenames for GUI preview
- `Test-DownloadedInfoJson`: Checks if video already exists in `/archive` or legacy path (prevents re-downloads)

**[yt-dlp_guis.ps1](../yt-dlp_guis.ps1)** - UI and configuration

- `Show-MainWindow`: Loads XAML, binds controls, manages config persistence
- `GenerateParameters`: Collects all checkbox/text/dropdown state into hashtable
- `Save-YtDlpConfig` / `Get-YtDlpConfig`: JSON persistence to `gui-main-window-config.json`
- `Show-DownloadCompleteWindow`: Post-download file listing with explorer integration

**[yt-dlp-debug.ps1](../yt-dlp-debug.ps1)** - Testing stubs

- `debug-mainWindow`, `debug-function`, `debug-downCompleteWindow` - Dummy data mocks

**[gui-others.ps1](../gui-others.ps1)** - UI event handlers and utilities

## Configuration & State Management

### GUI Configuration File

[gui-main-window-config.json](../gui-main-window-config.json) persists:

```json
{
  "Destination": "X:\\tiktok",
  "Cookies": true,
  "Browser": "firefox",
  "BrowserProfile": "3vm341ho.default-release",
  "CustomRanges": false,
  "TimeRanges": [],
  "Resolution720p/1080p": false,
  "BestAudioOnly": false
}
```

### Archive Directory

`/archive/` caches downloaded metadata with naming pattern: `(extractor)VideoId-uid_UniqueId.info.json`

- Purpose: Skip re-fetching metadata for videos already attempted
- Pattern matching: `*($extractor)$VideoId*.info.json`

## Key Patterns & Conventions

### yt-dlp Parameter Construction

Parameters are assembled incrementally into arrays:

```powershell
$DownloadParameters = $BaseParameters  # URL + proxy + console options
$DownloadParameters += '--proxy', $ProxyServer  # Conditionally add if system proxy enabled
$DownloadParameters += '--cookies-from-browser', "firefox:profile-name"  # Auth
$DownloadParameters += '-f', 'bestvideo[height<=1080]+bestaudio/best'  # Format selection
$DownloadParameters += '-o', $OutTemplate  # Output filename with yt-dlp variable syntax
$DownloadParameters += '--embed-info-json', '--embed-subs', '--embed-metadata'  # Metadata embedding
```

### WPF Control Naming Convention

All GUI controls use `$wpf_` prefix + descriptive name:

- `$wpf_cbCookies` → checkbox (cb = checkbox)
- `$wpf_txtCustomDestination` → textbox (txt = textbox)
- `$wpf_ListBoxRanges` → listbox
- `$wpf_browserComboBox` → dropdown (ComboBox)

**Binding mechanism**: `GuiFromXaml()` loads XAML, automatically maps named controls to `$wpf_*` variables (custom function in functions-forms.ps1)

### Unique ID Strategy

Every download gets a `$UniqueId` (via `Get-UniqueId`) appended to filenames:

- Format: `filename_uid_RANDOMID@[o].%(ext)s`
- Purpose: Distinguish partial/retry downloads of same video
- Embedded in archive cache filename too

### Platform-Specific Output Templates

[Get-OutputTemplate](../yt-dlp_functions.ps1#L150) maintains extractor → naming template mapping:

- Facebook: `%(uploader_id)s` (no title)
- Instagram: `%(channel)s-%(uploader)s-%(uploader_id)s`
- TikTok: `%(uploader)s`
- YouTube: `%(uploader_id)s-%(uploader)s`
- PornHub: `%(uploader_id)s-%(cast)s`

Custom ranges (time-based extraction) require special handling: template includes `_%(section_start)s` placeholder

## Development & Debugging

### Running in Debug Mode

```powershell
# Load without downloading
.\yt-dlp.ps1 -url "https://..." -mode "list" -Debug
```

Invokes `debug-mainWindow` function from yt-dlp-debug.ps1 with dummy data

### Testing Individual Functions

Edit [yt-dlp-debug.ps1](../yt-dlp-debug.ps1):

- `debug-function`: Test `Get-InfoJson`
- `debug-function2`: Test `Show-DownloadInfo`
- `debug-downCompleteWindow`: Test post-download UI

### XAML GUI Files

- [gui-main-window.xaml](../gui-main-window.xaml): Main download options window (dark theme, ~500x700px)
- [gui-download-complete.xaml](../gui-download-complete.xaml): Post-download file list
- Styling: `#1E1E1E` dark background, `#FFFFFF` text, hover effects on buttons

## Common Workflows

### Adding New Download Option

1. Add checkbox/control to XAML
2. Add binding in `GenerateParameters` function (yt-dlp_guis.ps1)
3. Add to config JSON schema
4. Update `Save-YtDlpConfig` and `Get-YtDlpConfig` to persist
5. Pass option to `Get-DownloadParameters` to append yt-dlp CLI arg

### Supporting New Video Platform

1. Add extractor name to `$ExtractorHashTable` in `Get-OutputTemplate`
2. Define filename pattern (e.g., `"%(uploader)s"`)
3. Test with `debug-function2` using real yt-dlp JSON

### Handling Download Failures

- Check `$stderr` from `Get-InfoJson` for yt-dlp errors
- Verify `$ytdlPath` points to valid binary
- Inspect `[PSCustomObject]@{ FilePath=$path; Exists=$bool }` in completion window

## Testing & Debugging Utilities

### Proxy Detection

`Get-Proxy()` reads Windows registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`

### Browser Profile Discovery

`Get-BrowserProfiles` function scans:

- Firefox: `%APPDATA%\Mozilla\Firefox\Profiles`
- Chrome: `%LOCALAPPDATA%\Google\Chrome\User Data`
- Edge: `%LOCALAPPDATA%\Microsoft\Edge\User Data`

## File Organization

```
root/
├── yt-dlp.ps1              # Main entry, mode routing
├── yt-dlp_functions.ps1    # Download logic, templates
├── yt-dlp_guis.ps1         # UI loading, config I/O
├── gui-others.ps1          # Event handlers
├── yt-dlp-debug.ps1        # Debug stubs
├── gui-main-window.xaml    # Main download options UI
├── gui-main-window-config.json  # Persisted UI state
├── yt-dlp_cutom_ranges.txt # Time range presets (not used in current version)
├── dummy.info.json         # Test metadata placeholder
├── archive/                # Downloaded .info.json cache
└── .github/copilot-instructions.md  # This file
```

## Important Caveats

- **Hardcoded paths**: yt-dlp binary at `C:\mega\program-files\yt-dlp\yt-dlp.exe`, archive at `./archive`
- **Proxy support**: Uses Windows system proxy settings; yt-dlp args automatically include proxy if enabled
- **Time ranges**: Custom section extraction requires yt-dlp `--download-sections` support (not all platforms/formats)
- **Cookie auth**: Browser profile paths are OS-dependent; hardcoded for Firefox default-release and Chrome/Edge User Data
