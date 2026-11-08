[CmdletBinding()]
param(
  [ValidateSet('thumbnails', 'storyboards')]
  [Parameter(Mandatory)][string]$url
)

. ..\#lib\functions.ps1
. ..\#lib\functions-forms.ps1
. .\yt-dlp_functions.ps1

yt-dlp -o 'thumbs/%(title)s [%(id)s].%(ext)s' 'tiktokuser:sujeewa.sampath63' --ffmpeg-location $pro_ffmpeg

yt-dlp --keep-fragments --exec 'powershell -NoProfile -ExecutionPolicy Bypass -File C:\mega\IDEs\powershell\yt-dlp\yt-dlp-sb.ps1' 'https://www.youtube.com/@VeyilonEntertainment/videos' -f 'sb0/sb1/sb2/sb3'