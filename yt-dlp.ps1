param( 
    [string]$url, [string]$mode, [string]$destination, 
    [Switch]$Debug, [Switch]$SkipPrompt, $InfoJson,
    [Switch]$Verbose = $false
)

if ( $Verbose) {
    $VerbosePreference = 'Continue'
}
Clear-Host
Set-Location $PSScriptRoot

. ..\#lib\functions.ps1
. ..\#lib\functions-forms.ps1
. .\yt-dlp_functions.ps1
. .\yt-dlp_guis.ps1
. .\yt-dlp-debug.ps1
. .\gui-others.ps1

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

# if ( $Debug ) { debug-function }

$host.ui.RawUI.WindowTitle = "yt-dlp.ps1 ""$url"""

$mode = $mode.ToLower()
switch ($mode) {
    
    'list' {
        $InfoJson = Get-InfoJson $ytdlPath
        $InfoJSON | & $ytdlPath $InfoJSONParameters --print formats_table --load-info-json - ;
        $AfterListGui = GuiFromXaml($AfterListXaml)
        $AfterListGui.add_Loaded({
                Activate
                $AfterListGui.Activate()
                $AfterListGui.Focus()
            })
        $wpf_btnExit.add_click({
                $AfterListGui.close()
                exitAndCloseTerminal
            })
        $wpf_btnDownload.add_click({
                $AfterListGui.close()
                . $PSCommandPath -url $url -mode 'max' -infoJson $InfoJson
            })
        $AfterListGui.ShowDialog()
        Exit
    }

    'quick' {
        Show-MainWindow -ytdlPath $ytdlPath
        $InfoJson = Get-InfoJson $ytdlPath
        $downloadParameters = HandleModeMax $InfoJson
    }

    'max' {
        $InfoJSON = Get-InfoJson $ytdlPath
        Show-MainWindow -ytdlPath $ytdlPath $InfoJson
        $DownloadParameters = HandleModeMax $InfoJSON $ytdlPath
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
$Options = generateParameters

Show-DownloadInfo 

Write-Host
Write-Host
if ($Debug) { Pause }
& $ytdlPath -U                    # perform an update before the execution
& $YtdlPath $DownloadParameters   # 🔥 

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