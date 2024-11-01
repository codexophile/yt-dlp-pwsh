function debug-function {
    param (    )

    $dummyFilesList = @(
        'D:\Mega\IDEs\powershell\yt-dlp_functions.ps1',
        'D:\Mega\IDEs\powershell\yt-dlp_guis.ps1',
        'D:\Mega\IDEs\powershell\yt-dlp.ps1',
        'D:\Mega\IDEs\powershell\#lib\functions.ps1'
    )
    
    $VerbosePreference = 'Continue'
    # Show-DownloadCompleteWindow '.\dummy.info.json' $dummyFilesList
    infoJsonOperations '.\dummy.info.json'
    
    exit
}