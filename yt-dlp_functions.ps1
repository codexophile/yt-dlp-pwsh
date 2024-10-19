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
    # activate
    #// if( Test-Path variable:$psform ) { $psform.hide() }
    $response = infoJsonOperations $pathToJson $finalFilePath
    if ( $response -eq 'Cancel' ) { exit }
}

function exitAndCloseTerminal { 
    if ( $Debug ) {
        # $psform.hide()
        exit 
    } 
    [Environment]::Exit(0)
}