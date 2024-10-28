function debug-function {
    param (    )
    
    # $psForm = GuiFromXml(".\gui-download-complete.xaml")
    $psForm = GuiFromXml(".\gui-main-window.xaml")
    $psForm.ShowDialog()
    
    exit
}