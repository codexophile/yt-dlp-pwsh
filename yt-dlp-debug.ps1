function debug-function {
    param (    )
    $VerbosePreference = 'Continue'

    #* main ui
    
    Show-MainWindow( '.\dummy.info.json', 'D:\Program Files - Portable\youtube-dl\yt-dlp.exe' )
    
    return
    
    #* download complete ui
    $dummyFilesList = @(
        'D:\Mega\IDEs\powershell\yt-dlp_functions.ps1',
        'D:\Mega\IDEs\powershell\yt-dlp_guis.ps1',
        'D:\Mega\IDEs\powershell\yt-dlp.ps1',
        'D:\Mega\IDEs\powershell\#lib\functions.ps1'
    )
    
    Show-DownloadCompleteWindow '.\dummy.info.json' $dummyFilesList
    
    exit
}