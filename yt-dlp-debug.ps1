function debug-function {
    param (    )
    $VerbosePreference = 'Continue'

    #* testing Show-DownloadInfo function

    # Dummy data setup
    $Extractor = @"
 ____                      _                 _ 
|  _ \  _____      ___ __ | | ___   __ _  __| |
| | | |/ _ \ \ /\ / / '_ \| |/ _ \ / _` |/ _` |
| |_| | (_) \ V  V /| | | | | (_) | (_| | (_| |
|____/ \___/ \_/\_/ |_| |_|_|\___/ \__,_|\__,_|
"@

    $mode = "Video + Audio (Best Quality)"
    $url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    $destination = "C:\Users\YourUsername\Downloads\Videos"
    $OutputFiles = @(
        "Never Gonna Give You Up.mp4",
        "Never Gonna Give You Up.srt",
        "Never Gonna Give You Up.thumbnail.jpg"
    )
    $ytdlPath = "yt-dlp.exe"
    $DownloadParameters = @(
        "--format",
        "bestvideo+bestaudio",
        "--merge-output-format",
        "mp4",
        "--write-subs",
        "--write-thumbnail",
        "--output",
        "%(title)s.%(ext)s"
    )

    Show-DownloadInfo
    
    exit
}