param( [string]$url, [string]$mode, [string]$destination, [Switch]$Debug, [Switch]$SkipPrompt
)

Clear-Host

. .\debug-code.ps1
if ( $Debug ) { debug-function }

If (-Not($url -OR $mode)) {
    Write-Host "Url : $url"
    Write-Host "Mode: $mode"
    Write-Host "Both download mode and url are required" -ForegroundColor Red
    return     
}

Set-Location $PSScriptRoot
. ..\functions.ps1
. ..\functions-forms.ps1
. .\yt-dlp_functions.ps1
. .\yt-dlp_guis.ps1
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

        Show-MainWindow
        
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
        If ($Options.SeventTwenty) { $DownloadParameters += '-f', 'bestvideo[height<=720]+bestaudio/best[height<=720]' }
        If ($Options.TenEighty) { $DownloadParameters += '-f', 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' }


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

$outFileName = $InfoJSON | & $ytdlPath  '--load-info-json' - -O $OutTemplate

Write-Ascii $Extractor; Write-Host
Write-Host
Write-Host "Mode   : $mode"        -ForegroundColor Yellow
Write-Host "URL    : $url"         -ForegroundColor Yellow
Write-Host "Out dir: $destination" -ForegroundColor Yellow
Write-Host "As     : $outFileName" -ForegroundColor Yellow 
Write-Host
Write-Host -NoNewline " $ytdlPath " -BackgroundColor DarkGreen -ForegroundColor White

$index = 0
foreach ( $parameter in $DownloadParameters ) {
    if ( $index % 2 -eq 1 ) {
        Write-Host  " $parameter " -ForegroundColor Yellow
    }
    else { Write-Host  " $parameter " }
    $index++
}

Write-Host
Write-Host
& $YtdlPath $DownloadParameters

$JsonPath = "D:\Mega\IDEs\powershell\yt-dlp archive\($extractor)$VideoId.info.json"
#// $InfoJSONFormatted.PSObject.properties.Remove( ' ')
$InfoJSONFormatted | ConvertTo-Json -Depth 100 | Out-File -FilePath $JsonPath



Return

#* After download
$finalFilePath = "$destination/$outFileName"
Set-Location -LiteralPath $destination
if ( -not ( Test-Path -LiteralPath $outFileName ) ) {
    Write-Host "destination: $(Test-Path -LiteralPath $destination)"
    Write-Host "curdir     : $(Get-Location)"
    Write-Host "fname      : $outFileName"
    Write-Host "file       : $(Test-Path -LiteralPath $outFileName)"
    MessageBox 'Error with file name' "" 'Ok' 'Error'
    exitTerminal $finalFilePath $pathToJson # 🛑
}


exitTerminal $pathToJson $finalFilePath