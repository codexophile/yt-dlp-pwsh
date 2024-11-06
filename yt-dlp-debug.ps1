function debug-function {
    param (    )
    $VerbosePreference = 'Continue'

    #* main ui
    
    $AfterListGui = GuiFromXaml(  $AfterListXaml)
    $AfterListGui.ShowDialog()

    
    exit
}