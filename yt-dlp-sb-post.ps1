<#
.SYNOPSIS
    Appends a common extension to all yt-dlp .part-FragN files belonging to a download.

.DESCRIPTION
    Given the path of a downloaded file, takes its name without the extension
    ("video_title [id]") and renames every sibling matching
    "<that name>.<anything>.part-Frag<number>" to "<original name><NewExtension>".
    Already-renamed files no longer end in digits, so re-running is safe.

.PARAMETER MediaPath
    Path of the downloaded file, as passed by yt-dlp's --exec.

.PARAMETER NewExtension
    Extension to append, including the leading dot. Defaults to '.frag'.

.PARAMETER FragmentDir
    Folder containing the fragments. Defaults to the downloaded file's folder.

.EXAMPLE
    .\yt-dlp-sb.ps1 'C:\Users\xq151\Downloads\video_title [EzBdx5TKf-0].mhtml'
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, Position = 0)]
  [string]$MediaPath,

  [ValidatePattern('^\.\w+$')]
  [string]$NewExtension = '.frag',

  [string]$FragmentDir
)

$base = [IO.Path]::GetFileNameWithoutExtension($MediaPath)
if (-not $FragmentDir) { $FragmentDir = [IO.Path]::GetDirectoryName($MediaPath) }

# "<base>.<ext>.part-Frag<digits>", with the base regex-escaped so [id] brackets are literal
$pattern = '^' + [regex]::Escape($base) + '\..+\.part-Frag\d+$'

Get-ChildItem -LiteralPath $FragmentDir -File |
  Where-Object { $_.Name -match $pattern } |
    ForEach-Object {
      Rename-Item -LiteralPath $_.FullName -NewName ($_.Name + $NewExtension)
    }