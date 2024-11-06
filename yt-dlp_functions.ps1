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
        @{ Label = "OUTPUT DIR"; Value = $destination }
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
    
    # Display command parameters with alternating colors
    Write-Host " COMMAND " -BackgroundColor DarkGreen -ForegroundColor White -NoNewline
    Write-Host " " -NoNewline
    
    for ($i = 0; $i -lt $DownloadParameters.Count; $i++) {
        $bgColor = if ($i % 2 -eq 0) { 'DarkBlue' } else { 'DarkMagenta' }
        Write-Host " $($DownloadParameters[$i]) " -ForegroundColor White -BackgroundColor $bgColor -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host
    
    # Draw bottom border
    Write-Host ("─" * ($Host.UI.RawUI.WindowSize.Width)) -ForegroundColor $borderColor
}

function Get-OutputFileNames {
    param( $OptionsObj, $InfoJSON, $OutTemplate )
    
    $OutputFiles = @()
    $outFileName = $InfoJSON | & $ytdlPath '--load-info-json' - -O $OutTemplate

    if ($OptionsObj.CustomRange) {
        foreach ($Item in $Options.Items) {
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
    param( $InfoJson )

    $ExtractorHashTable = @{
        facebook  = "%(uploader_id)s";
        hotstar   = "%(series)s- S%(season_number)sE%(episode_number)s- %(upload_date)s";
        zee5      = "%(series)s- S%(season_number)sE%(episode_number)s- %(upload_date)s";
        instagram = "%(channel)s- %(uploader)s  - %(uploader_id)s";
        tiktok    = "%(uploader)s";
        twitter   = "%(uploader_id)s- %(uploader)s";
        vimeo     = "%(uploader_id)s- %(uploader)s";
        youtube   = "%(uploader_id)s- %(uploader)s";
        XHamster  = "%(uploader_id)s";
        pornhub   = "%(uploader_id)s- %(cast)s";
    }

    $InfoJSONFormatted = $InfoJSON | ConvertFrom-Json
    $Extractor = $InfoJSONFormatted.extractor
    $OutTemplate = "$($ExtractorHashTable[$extractor]) - (%(extractor)s)%(id)s - %(title)s$( $Options.customRange ? ' _%(section_start)s' : '' ) @[o][bQ].%(ext)s"
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
        
        [Parameter(Mandatory)]
        [string[]]$InfoJsonParameters
    )

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