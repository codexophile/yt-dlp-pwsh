param( 
  [string]$url, [string]$mode, [string]$destination, 
  [Switch]$Debug, [Switch]$SkipPrompt, $InfoJson,
  [Switch]$Verbose = $false, [String]$GivenName
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

$ytdlPath = 'B:\Program Files - Portable\youtube-dl\yt-dlp.exe'

$BaseParameters = @( $url, '--console-title', '--progress', '--no-check-certificates' )
$CurrentProxySettings = Get-Proxy
if ( $currentProxySettings.ProxyEnable -eq '1' ) { $BaseParameters += '--proxy', $currentProxySettings.ProxyServer } 

if ( $Debug ) {
  debug-mainWindow
  return
}

$host.ui.RawUI.WindowTitle = "yt-dlp.ps1 ""$url"""

$UniqueId = Get-UniqueId

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

  'instant' {
    $DefaultPath = "W:\#downloads"
    $AlternativePath = [Environment]::GetFolderPath("UserDownloads")
    if (Test-Path $DefaultPath) {
      $destination = $DefaultPath
    }
    else {
      $destination = $AlternativePath
    }
    & $ytdlPath $url -P $destination
    Exit
  }

  'noprompt' {

    if (-not $destination) {
      Write-Error "A destination must be given with 'NoPrompt' mode!"
      Exit
    }

    if ( -not (Test-Path $destination)) {
      Write-Error "Invalid path: $destination"
      $newParams = $PSBoundParameters
      $newParams['mode'] = 'quick'  
      & $PSCommandPath @newParams
      exit $LASTEXITCODE
    }
    
    $SecondaryBaseParameters = Get-SecondaryBaseParameters
    $InfoJson = Get-InfoJson $ytdlPath $SecondaryBaseParameters

  }

  'quick' {
    Show-MainWindow -ytdlPath $ytdlPath
    $SecondaryBaseParameters = Get-SecondaryBaseParameters
    $InfoJson = Get-InfoJson $ytdlPath $SecondaryBaseParameters
  }

  'max' {
    $InfoJSON = Get-InfoJson $ytdlPath
    Show-MainWindow -ytdlPath $ytdlPath $InfoJson
  }

  'min' {
    $destination = 'W:\#previews'
    $DownloadParameters = $BaseParameters
    $DownloadParameters += '-P', 'W:\#previews', '-S', '+size,+br,+res,+fps'
  }

  'check' {
    $InfoJson = Get-InfoJson $ytdlPath
    $InfoJSONFormatted = $InfoJSON | ConvertFrom-Json
    $extractor = $InfoJSONFormatted.extractor
    $videoId = $InfoJSONFormatted.id
    Write-Host $VideoId
    Pause
    Exit
  }
    
  Default {}
}

$DownloadParameters = Get-DownloadParameters $InfoJSON $UniqueId
$InfoJSONFormatted = $InfoJSON | ConvertFrom-Json
$Extractor = $InfoJSONFormatted.extractor
$VideoId = $InfoJSONFormatted.id

$pathToJson = Test-DownloadedInfoJson $Extractor $VideoId
if ( $pathToJson ) {
   
  activate
  Write-Host "An entry for this video id already exists: $VideoId" -ForegroundColor DarkYellow
  $response = guiAlreadyExistsPrompt
  switch ( $response ) {
    Yes { Remove-Item $pathToJson }
    No { exitAndCloseTerminal }
    Abort { Start-Process "ES:$videoId"; exitAndCloseTerminal }
    Continue { infoJsonOperations -pathToJson $pathToJson; exitAndCloseTerminal }
  }
        
}

$Options = generateParameters
$OutTemplate = Get-OutputTemplate $InfoJSON $UniqueId
$OutputFiles = Get-OutputFileNames $Options $InfoJSON $OutTemplate

Show-DownloadInfo 

Write-Host
Write-Host
# if ($Debug) { Pause }
& $ytdlPath -U                    # perform an update before the execution
& $YtdlPath $DownloadParameters   # 🔥 

if ($Extractor -eq 'generic') { $VideoId = '' }

$JsonPath = "archive\($extractor)$VideoId-uid_$UniqueId.info.json"
#// $InfoJSONFormatted.PSObject.properties.Remove( ' ')
$InfoJSONFormatted | ConvertTo-Json -Depth 100 | Out-File -FilePath $JsonPath

#* After download
Write-Ascii 'Completion!'
$Destination = $Options.destination
Show-DownloadCompleteWindow $JsonPath $OutputFiles $Destination