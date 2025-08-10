function Test-DownloadedInfoJson {
  param( $extractor, $VideoId)

  $CurrentPath = "archive"
  $LegacyPath = "c:\mega\IDEs\powershell\yt-dlp archive"
  $SearchPattern = "*($extractor)$VideoId*.info.json"
    
  # Search in current path
  $currentPathResult = Get-ChildItem -Path $CurrentPath -Filter $SearchPattern -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($currentPathResult) {
    return $currentPathResult.FullName
  }
    
  # Search in legacy path
  $legacyPathResult = Get-ChildItem -Path $LegacyPath -Filter $SearchPattern -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($legacyPathResult) {
    return $legacyPathResult.FullName
  }
    
  return $false
}

function Get-SecondaryBaseParameters {

  $Options = GenerateParameters
  if ($Options.IsCookies) { $OutputParameters += '--cookies-from-browser', 'vivaldi' }
  If ($Options.ImpersonateGeneric) { $OutputParameters += '--extractor-args', "generic:impersonate" }
  return $OutputParameters
  
}
function Get-DownloadParameters {
  param( $InfoJson, $UniqueId )

  $Options = GenerateParameters
  $destination = $Options.destination
  $DownloadParameters = $BaseParameters
  $DownloadParameters += '-P', $destination
    
  If ($Options.IsCookies) { $DownloadParameters += '--cookies-from-browser', 'vivaldi' }
  If ($Options.CustomRange) {
    foreach ( $currentItem in $Options.Items ) { $DownloadParameters += '--download-sections', "*$currentItem" } 
  }
  If ($Options.CustomName) {
    $OutTemplate = "$($Options.CustomName) - $( $Options.customRange ? '_%(section_start)s' : '' ) uid_$UniqueId  @[o].%(ext)s"
  }
  Else {
    $OutTemplate = Get-OutputTemplate $InfoJson $UniqueId
  }
  If ($Options.ImpersonateGeneric) { $DownloadParameters += '--extractor-args', "generic:impersonate" }

  $DownloadParameters += '-o', $OutTemplate
  $DownloadParameters += '--embed-info-json', '--embed-subs', '--embed-metadata', '--embed-chapters'
  # $DownloadParameters += '--write-auto-subs'
        
  if ($Options.BestAudioOnly) { $DownloadParameters += '-f', 'bestaudio' }
  else {
    If ($Options.SevenTwenty) { $DownloadParameters += '-f', 'bestvideo[height<=720]+bestaudio/best[height<=720]' }
    If ($Options.TenEighty) { $DownloadParameters += '-f', 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' }
  }

  return $DownloadParameters

}

function Show-DownloadInfo {
  $borderColor = 'DarkCyan'
  $headerColor = 'Cyan'
  $textColor = 'Yellow'
    
  # Draw top border
  Write-Host ("─" * ($Host.UI.RawUI.WindowSize.Width)) -ForegroundColor $borderColor
    
  # Show ASCII art with padding
  Write-Ascii $Extractor
  Write-Host
    
  # Create info block with consistent formatting
  $infoBlock = @(
    @{ Label = "MODE"; Value = $mode }
    @{ Label = "URL"; Value = $url }
    @{ Label = "OUTPUT DIR"; Value = $Options.Destination }
  )
    
  # Display info block with proper alignment
  $labelWidth = ($infoBlock | ForEach-Object { $_.Label.Length } | Measure-Object -Maximum).Maximum + 2
  foreach ($item in $infoBlock) {
    $label = $item.Label.PadRight($labelWidth)
    Write-Host " ┃ " -ForegroundColor $borderColor -NoNewline
    Write-Host $label -ForegroundColor $headerColor -NoNewline
    Write-Host " │ " -ForegroundColor $borderColor -NoNewline
    Write-Host $item.Value -ForegroundColor $textColor
  }
    
  # Display output files
  Write-Host " ┃ " -ForegroundColor $borderColor -NoNewline
  Write-Host "FILES".PadRight($labelWidth) -ForegroundColor $headerColor -NoNewline
  Write-Host " │ " -ForegroundColor $borderColor
  foreach ($fileName in $OutputFiles) {
    Write-Host " ┃ " -ForegroundColor $borderColor -NoNewline
    Write-Host "".PadRight($labelWidth) -NoNewline
    Write-Host " │ " -ForegroundColor $borderColor -NoNewline
    Write-Host $fileName -ForegroundColor $textColor
  }
    
  # Draw separator
  Write-Host ("─" * ($Host.UI.RawUI.WindowSize.Width)) -ForegroundColor $borderColor
    
  # Display command parameters in a vertical, color-coded list
  Write-Host " COMMAND " -BackgroundColor DarkGreen -ForegroundColor White
    
  foreach ($i in 0..($DownloadParameters.Count - 1)) {
    $bgColor = if ($i % 2 -eq 0) { 'DarkBlue' } else { 'DarkMagenta' }
    Write-Host (" {0,2}. " -f ($i + 1)) -ForegroundColor White -BackgroundColor Gray -NoNewline
    Write-Host " $($DownloadParameters[$i]) " -ForegroundColor White -BackgroundColor $bgColor
  }
    
  # Draw bottom border
  Write-Host ("─" * ($Host.UI.RawUI.WindowSize.Width)) -ForegroundColor $borderColor
}

function Get-OutputFileNames {
  param( $OptionsObj, $InfoJSON, $OutTemplate )

  if ( $OptionsObj.CustomName ) {
    $OutTemplate = "$($OptionsObj.CustomName) - $( $OptionsObj.customRange ? '_%(section_start)s' : '' ) @[o].%(ext)s"
  }
    
  $OutputFiles = @()
  $outFileName = $InfoJSON | & $ytdlPath '--load-info-json' - -O $OutTemplate

  if ($OptionsObj.CustomRange) {
    foreach ($Item in $OptionsObj.Items) {
      $Timestamp = ConvertTo-Seconds $Item
      # Apply the replacements to the filename and add to the output list
      $modifiedFileName = $outFileName -replace ':', '：' -replace '_NA', "_$Timestamp.0"
      $OutputFiles += $modifiedFileName
    }
  }
  else {
    $OutputFiles += $outFileName
  }

  return $OutputFiles
}

function Get-OutputTemplate {
  param( $InfoJson, $UniqueId )

  $ExtractorHashTable = @{
    facebook  = "%(uploader_id)s";
    hotstar   = "%(series)s- S%(season_number)sE%(episode_number)s- %(upload_date)s";
    zee5      = "%(series)s- S%(season_number)sE%(episode_number)s- %(upload_date)s";
    instagram = "%(channel)s- %(uploader)s - %(uploader_id)s";
    tiktok    = "%(uploader)s";
    twitter   = "%(uploader_id)s- %(uploader)s";
    vimeo     = "%(uploader_id)s- %(uploader)s";
    youtube   = "%(uploader_id)s- %(uploader)s";
    XHamster  = "%(uploader_id)s";
    pornhub   = "%(uploader_id)s- %(cast)s";
  }

  $InfoJSONFormatted = $InfoJSON | ConvertFrom-Json
  $Extractor = $InfoJSONFormatted.extractor
    
  # Build the template conditionally based on extractor
  $TitlePart = if ($Extractor -ne "facebook") { " - %(title)s" } else { "" }
  $OutTemplate = "$($ExtractorHashTable[$extractor]) - (%(extractor)s)%(id)s$TitlePart$( $Options.customRange ? ' _%(section_start)s' : '' ) uid_$UniqueId @[o].%(ext)s"
    
  Return $OutTemplate
}

Function Get-Proxy() {
  Return ( Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" )
}

function Get-InfoJson {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$YtdlPath,
    $SecondaryBaseParameters
  )

  $InfoJsonParameters = @($BaseParameters)
  $InfoJsonParameters += $SecondaryBaseParameters
  $InfoJsonParameters += '--print', '%()j', '--no-clean-info-json'

  Write-Host "Getting .info.json ..."
  $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

  try {
    $result = & $YtdlPath $InfoJsonParameters 2>&1
    $stdout = $result | Where-Object { $_ -is [string] }
    $stderr = $result | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }

    $stopWatch.Stop()
    Write-Host "Elapsed: $($stopWatch.Elapsed)" -ForegroundColor Cyan

    if ($stdout) {
      try {
        $null = $stdout | ConvertFrom-Json
        # Write-Host $stdout
        return $stdout
      }
      catch {
        Write-Warning "Failed to parse JSON: $_"
        Write-Host $stdout
        return $null
      }
    }
        
    if ($stderr) {
      Write-Warning "Error occurred: $stderr"
      $MsgboxResult = [System.Windows.MessageBox]::Show("$stderr`n`nRetry?", 'Yt-ldp Error', 4, 32)
      If ( $MsgboxResult -eq 'Yes') { Return Get-InfoJson $YtdlPath $InfoJsonParameters }
      Else { Return $null }
    }

    if (-not $stdout -and -not $stderr) {
      Write-Warning "No output or error received."
    }
  }
  catch {
    Write-Error "An unexpected error occurred: $_"
  }

  return $null
}

function exitTerminal {
  param ( $pathToJson, $finalFilePath )
  $response = infoJsonOperations $pathToJson $finalFilePath
  if ( $response -eq 'Cancel' ) { exit }
}

function exitAndCloseTerminal { 
  if ( $Debug ) {
    exit
  } 
  else {
    [Environment]::Exit(0)
  }
}