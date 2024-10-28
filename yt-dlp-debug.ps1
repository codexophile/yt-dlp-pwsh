function debug-function {
    param (    )
    
    # $psForm = GuiFromXml(".\gui-download-complete.xaml")
    # $psForm = GuiFromXml(".\gui-main-window.xaml")
    # $psForm.ShowDialog()
    Show-MainWindow
    $Options = GenerateParameters
    $InfoJson = Get-Content -Path '.\dummy.info.json'
    $ytdlPath = 'D:\Program Files - Portable\youtube-dl\yt-dlp.exe'
    $OutTemplate = '%(uploader_id)s- %(uploader)s - (%(extractor)s)%(id)s - %(title)s _%(section_start)s @[o][bQ].%(ext)s'
    $outFileName = $InfoJSON | & $ytdlPath  '--load-info-json' - -O $OutTemplate
    $outputFiles = @()
    foreach ($Item in $Options.Items) {
        $Timestamp = ConvertTo-Seconds $Item
        $outputFiles += $outFileName -replace '_NA', "_$Timestamp.0"
    }
    $outputFiles
    exit

    # Load the GUI
    $window = GuiFromXaml -XamlTextOrXamlFile "gui-download-complete.xaml"

    # Add event handlers
    $wpf_FilesList.Add_SelectionChanged({
            param($sender, $e)
            # Your FilesList_SelectionChanged logic here
        })

    $wpf_OpenButton.Add_Click({
            # Open button logic
        })

    $wpf_LocateButton.Add_Click({
            # Locate button logic
        })

    $wpf_CloseButton.Add_Click({
            $window.Close()
        })

    # Show the window
    $window.ShowDialog()
    
    exit
}