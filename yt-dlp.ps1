param( [string]$url, [string]$mode, [string]$destination, [Switch]$Debug, [Switch]$SkipPrompt
)

Clear-Host

Set-Location $PSScriptRoot

. ..\#lib\functions.ps1
. ..\#lib\functions-forms.ps1
. .\yt-dlp_functions.ps1
. .\yt-dlp_guis.ps1
. .\yt-dlp-debug.ps1

if ( $Debug ) { debug-function }

If (-Not($url -OR $mode)) {
    Write-Host "Url : $url"
    Write-Host "Mode: $mode"
    Write-Host "Both download mode and url are required" -ForegroundColor Red
    return     
}

$ytdlPath = 'D:\Program Files - Portable\youtube-dl\yt-dlp.exe'

$BaseParameters = @( $url, '--console-title', '--progress', '--no-check-certificates' )
$CurrentProxySettings = Get-Proxy
if ( $currentProxySettings.ProxyEnable -eq '1' ) { $BaseParameters += '--proxy', $currentProxySettings.ProxyServer } 

& $ytdlPath -U

$InfoJsonParameters = @($BaseParameters)
$InfoJsonParameters += '--print', '%()j', '--no-clean-info-json', '--cookies-from-browser', 'vivaldi'
$InfoJson = Get-InfoJson $ytdlPath $InfoJSONParameters 
If (-Not $InfoJson ) { exitAndCloseTerminal }

$host.ui.RawUI.WindowTitle = "yt-dlp.ps1 ""$url"""

$mode = $mode.ToLower()
switch ($mode) {
    
    'list' {
        $InfoJSON | & $ytdlPath $InfoJSONParameters --print formats_table --load-info-json - ;
        Activate
        MessageBox Exit? Done 'Ok' 'Question'
        exitAndCloseTerminal
    }

    'max' {

        Show-MainWindow $InfoJson $ytdlPath
        
        $Options = GenerateParameters
        $destination = $Options.destination
        $DownloadParameters = $BaseParameters
        $DownloadParameters += '-P', $destination
        If ($Options.IsCookies) { $DownloadParameters += '--cookies-from-browser', 'vivaldi' }
        If ($Options.CustomRange) {
            foreach ( $currentItem in $Options.Items ) { $DownloadParameters += '--download-sections', "*$currentItem" } 
        }
        If ($Options.CustomName) {
            $OutTemplate = "$($Options.CustomName) - $( $Options.customRange ? '_%(section_start)s' : '' ) @[o][bQ].%(ext)s"
        }
        Else {
            $OutTemplate = Get-OutputTemplate($InfoJson)
        }

        $DownloadParameters += '-o', $OutTemplate
        $DownloadParameters += '--embed-info-json', '--embed-subs', '--embed-metadata', '--embed-chapters'
        
        if ($Options.BestAudioOnly) { $DownloadParameters += '-f', 'bestaudio' }
        else {
            If ($Options.SeventTwenty) { $DownloadParameters += '-f', 'bestvideo[height<=720]+bestaudio/best[height<=720]' }
            If ($Options.TenEighty) { $DownloadParameters += '-f', 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' }
        }

    }

    'min' {
        $destination = 'W:\#previews'
        $DownloadParameters = $BaseParameters
        $DownloadParameters += '-P', 'W:\#previews', '-S', '+size,+br,+res,+fps'
    }
    
    Default {}
}

$InfoJSONFormatted = $InfoJSON | ConvertFrom-Json
$Extractor = $InfoJSONFormatted.extractor
$VideoId = $InfoJSONFormatted.id

$pathToJson = "D:\Mega\IDEs\powershell\yt-dlp archive\($extractor)$VideoId.info.json"
if ( [System.IO.File]::Exists( $pathToJson )  ) { 

    activate
    Write-Host "An entry for this video id already exists: $VideoId" -ForegroundColor DarkYellow
    $response = guiAlreadyExistsPrompt
    switch ( $response ) {
        Yes { Remove-Item $pathToJson }
        No { exitAndCloseTerminal }
        Abort { Remove-Item $pathToJson }
        Continue { infoJsonOperations -pathToJson $pathToJson; exitAndCloseTerminal }
    }
        
}

$OutputFiles = Get-OutputFileNames $Options $InfoJSON $OutTemplate

Write-Ascii $Extractor; Write-Host
Write-Host
Write-Host "Mode   : $mode"        -ForegroundColor Yellow
Write-Host "URL    : $url"         -ForegroundColor Yellow
Write-Host "Out dir: $destination" -ForegroundColor Yellow
Write-Host "As     : "             -ForegroundColor Yellow 
foreach ($fileName in $OutputFiles) {
    Write-Host $filename -ForegroundColor Yellow
}
Write-Host
Write-Host -NoNewline " $ytdlPath " -BackgroundColor DarkGreen -ForegroundColor White

$index = 0
foreach ( $parameter in $DownloadParameters ) {
    if ( $index % 2 -eq 1 ) {
        Write-Host  " $parameter " -ForegroundColor Yellow -BackgroundColor DarkBlue
    }
    else { Write-Host  " $parameter "  -ForegroundColor White -BackgroundColor DarkBlue }
    $index++
}

Write-Host
Write-Host
& $YtdlPath $DownloadParameters

$JsonPath = "D:\Mega\IDEs\powershell\yt-dlp archive\($extractor)$VideoId.info.json"
#// $InfoJSONFormatted.PSObject.properties.Remove( ' ')
$InfoJSONFormatted | ConvertTo-Json -Depth 100 | Out-File -FilePath $JsonPath

#* After download
foreach ($File in $OutputFiles) {
    Write-Host
    "$destination\$File"
    Test-Path -LiteralPath "$destination\$File"
}

Show-DownloadCompleteWindow $JsonPath $OutputFiles

# exitTerminal $pathToJson $finalFilePath