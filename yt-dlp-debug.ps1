function debug-function {
    param (    )
    
    # $psForm = GuiFromXml(".\gui-download-complete.xaml")
    # $psForm = GuiFromXml(".\gui-main-window.xaml")
    # $psForm.ShowDialog()
    Show-MainWindow
    $Options = GenerateParameters
    foreach ($Item in $Options.Items) {
        ConvertTo-Seconds $Item
    }

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