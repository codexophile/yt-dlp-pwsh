Clear-Host
& 'D:\Program Files\youtube-dl\yt-dlp.exe' -U | Tee-Object -Variable test
Write-Host xxx
Write-Host $test