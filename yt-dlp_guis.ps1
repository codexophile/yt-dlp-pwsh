# . c:\mega\IDEs\powershell\functions-forms.ps1
# Add-Type -AssemblyName System.Windows.Forms
# Add-Type -AssemblyName System.Drawing

function Show-WpfFormOnMonitor {
  param (
    [Parameter(Mandatory = $true)]
    [System.Windows.Window]$WpfForm,

    [Parameter(Mandatory = $true)]
    [int]$MonitorIndex
  )

  # Get all screens (monitors)
  $screens = [System.Windows.Forms.Screen]::AllScreens

  # Validate the monitor index
  if ($MonitorIndex -lt 0 -or $MonitorIndex -ge $screens.Count) {
    Write-Error "Invalid monitor index. Available monitors: 0 to $($screens.Count - 1)"
    return
  }

  # Get the target monitor
  $targetScreen = $screens[$MonitorIndex]

  # Get the monitor's working area (excludes taskbar, etc.)
  $screenBounds = $targetScreen.WorkingArea

  # Calculate the center position
  $formWidth = $WpfForm.Width
  $formHeight = $WpfForm.Height
  $left = $screenBounds.X + (($screenBounds.Width - $formWidth) / 2)
  $top = $screenBounds.Y + (($screenBounds.Height - $formHeight) / 2)

  # Set the form's position
  $WpfForm.Left = $left
  $WpfForm.Top = $top

  # Show the form
  $WpfForm.ShowDialog()
}

function Show-DownloadCompleteWindow {
  param($SavedInfoJson, $FilesList, $Destination)
    
  # Load the GUI
  $window = GuiFromXaml -XamlTextOrXamlFile "gui-download-complete.xaml"
    
  # Create a custom object for each file with path and existence status
  foreach ($File in $FilesList) {
    $fullPath = "$Destination\$File"
    # Explicitly check if file exists and set boolean value
    $fileExists = [bool](Test-Path -LiteralPath $fullPath -PathType Leaf)
        
    $fileItem = [PSCustomObject]@{
      FilePath = $fullPath
      Exists   = $fileExists  # This will be a true boolean value
    }
        
    $wpf_FilesList.Items.Add($fileItem)
    Write-Host "$fullPath - Exists: $fileExists"
  }

  # Add event handlers
  $wpf_FilesList.Add_SelectionChanged({
      # param($sender, $e)
      # Your FilesList_SelectionChanged logic here
    })
    
  $wpf_OpenButton.Add_Click({
      . $wpf_FilesList.SelectedItem.FilePath
    })
    
  $wpf_LocateButton.Add_Click({
      & explorer.exe "/select," $wpf_FilesList.SelectedItem.FilePath
    })
    
  $wpf_CloseButton.Add_Click({
      $window.Close()
      # exitAndCloseTerminal
    })

  $wpf_RestartDownloadButton.Add_Click({
      $scriptPath = $MyInvocation.MyCommand.Path
      $scriptArgs = $MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object { "-$_ $_.Value" }

      # Start a new terminal window and run the script with the same parameters
      Start-Process -FilePath "pwsh" -ArgumentList @("-NoExit", "-File", $scriptPath) -WorkingDirectory (Get-Location).Path
  })
    
  # Add Loaded event handler to ensure focus
  $window.Add_Loaded({
      $window.Activate()
      $window.Focus()
    })
    
  $window.add_Closing({
      # exitAndCloseTerminal
    })
    

  $null = Show-WpfFormOnMonitor $window 0
}

function GenerateParameters {

  $destination = $wpf_txtCustomDestination.Text ? $wpf_txtCustomDestination.Text : $destination ? $destination : [Environment]::GetFolderPath("Desktop") 
  $isCookies = $wpf_cbCookies.IsChecked      ? $true : $false
  $Browser = if ($wpf_cbCookies.IsChecked) { $wpf_browserComboBox.SelectedItem } else { $null }
  $BrowserProfile = if ($wpf_cbCookies.IsChecked) { $wpf_profileComboBox.SelectedItem } else { $null }
  $CustomRange = $wpf_CbCustomranges.IsChecked ? $true : $false
  $Items = $wpf_ListBoxRanges.Items
  $CustomName = $wpf_Checkbox_CustomName.IsChecked ? $wpf_Textbox_CustomName.Text : $False
  $720p = $wpf_cb720p.IsChecked ? $true : $false
  $1080p = $wpf_cb1080p.IsChecked ? $true : $false
  $BestAudioOnly = $wpf_cbBestAudio.IsChecked ? $true : $false
  $ImpersonateGeneric = $wpf_cbImpersonateGeneric.IsChecked ? $true : $false
  $CustomFormat = $wpf_cbCustomFormat.IsChecked ? $true : $false
  $SelectedFormatId = if ($CustomFormat -and $wpf_listboxFormats.SelectedItem) { $wpf_listboxFormats.SelectedItem } else { $null }

  Return @{
    Destination        = $destination
    IsCookies          = $isCookies
    Browser            = $Browser
    BrowserProfile     = $BrowserProfile
    CustomRange        = $CustomRange
    Items              = $Items
    CustomName         = $CustomName
    SevenTwenty        = $720p
    TenEighty          = $1080p
    BestAudioOnly      = $BestAudioOnly
    ImpersonateGeneric = $ImpersonateGeneric
    CustomFormat       = $CustomFormat
    SelectedFormatId   = $SelectedFormatId
  }

}

function RefreshAndDisplayDestinations {
  param( $ListBox)
    
  $ListBox.Items.Clear()
  if ( Test-Path W: ) {
    get-childitem -path 'w:\#later' -directory | ForEach-Object { [void] $ListBox.Items.Add( $_.fullname ) } 
  }
  if ( Test-Path X: ) {
    get-childitem -path 'X:\' -directory | ForEach-Object { [void] $ListBox.Items.Add( $_.fullname ) } 
  }
  [void] $ListBox.Items.Add( [Environment]::GetFolderPath("Desktop") )
  [void] $ListBox.Items.Add("$HOME\Downloads")
}

function PopulateFormatsListbox {
  param( $InfoJson )
  
  $wpf_listboxFormats.Items.Clear()
  
  if (-not $InfoJson) {
    return
  }
  
  try {
    $InfoJsonFormatted = $InfoJson | ConvertFrom-Json
    if ($InfoJsonFormatted.formats -and $InfoJsonFormatted.formats.Count -gt 0) {
      foreach ($format in $InfoJsonFormatted.formats) {
        $formatString = if ($format.format_id) {
          "$($format.format_id) - $($format.format_note) ($($format.ext))"
        } else {
          $format.format
        }
        [void] $wpf_listboxFormats.Items.Add($format.format_id)
      }
    }
  }
  catch {
    Write-Warning "Could not populate formats: $_"
  }
}

function Save-YtDlpConfig {
  # Get current configuration from GUI controls
  $config = @{
    Destination        = $wpf_txtCustomDestination.Text
    Cookies            = $wpf_cbCookies.IsChecked
    Browser            = if ($wpf_cbCookies.IsChecked) { $wpf_browserComboBox.SelectedItem } else { $null }
    BrowserProfile     = if ($wpf_cbCookies.IsChecked) { $wpf_profileComboBox.SelectedItem } else { $null }
    BestAudioOnly      = $wpf_cbBestAudio.IsChecked
    ImpersonateGeneric = $wpf_cbImpersonateGeneric.IsChecked
    CustomRanges       = $wpf_CbCustomranges.IsChecked
    CustomNameEnabled  = $wpf_Checkbox_CustomName.IsChecked
    CustomNameText     = if ($wpf_Checkbox_CustomName.IsChecked) { $wpf_Textbox_CustomName.Text } else { "" }
    CustomFormatEnabled = $wpf_cbCustomFormat.IsChecked
    SelectedFormatId   = if ($wpf_cbCustomFormat.IsChecked -and $wpf_listboxFormats.SelectedItem) { $wpf_listboxFormats.SelectedItem } else { $null }
    Resolution720p     = $wpf_cb720p.IsChecked
    Resolution1080p    = $wpf_cb1080p.IsChecked
    TimeRanges         = @()
  }

  # Save time ranges if any exist
  if ($wpf_ListBoxRanges.Items.Count -gt 0) {
    $config.TimeRanges = @($wpf_ListBoxRanges.Items)
  }

  # Save configuration to JSON file
  $configPath = Join-Path $PSScriptRoot "gui-main-window-config.json"
  $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
  Write-Host "Configuration saved successfully" -ForegroundColor Green
}

function Get-YtDlpConfig {
  # Construct path to configuration file
  $configPath = Join-Path $PSScriptRoot "gui-main-window-config.json"

  # Check if configuration file exists
  if (-not (Test-Path $configPath)) {
    Write-Host "No saved configuration found" -ForegroundColor Yellow
    return $false
  }

  try {
    # Load and parse configuration
    $config = Get-Content -Path $configPath | ConvertFrom-Json

    # Apply configuration to GUI controls
    $wpf_txtCustomDestination.Text = $config.Destination
    $wpf_cbCookies.IsChecked = $config.Cookies
    if ($wpf_cbCookies.IsChecked) {
        $wpf_browserComboBox.SelectedItem = $config.Browser
        # Wait for profiles to populate
        Start-Sleep -Milliseconds 100
        $wpf_profileComboBox.SelectedItem = $config.BrowserProfile
    }
    $wpf_cbBestAudio.IsChecked = $config.BestAudioOnly
    $wpf_cbImpersonateGeneric.IsChecked = $config.ImpersonateGeneric
    $wpf_CbCustomranges.IsChecked = $config.CustomRanges
    $wpf_Checkbox_CustomName.IsChecked = $config.CustomNameEnabled
    if ($config.CustomNameEnabled) {
        $wpf_Textbox_CustomName.Text = $config.CustomNameText
    }
    $wpf_cbCustomFormat.IsChecked = $config.CustomFormatEnabled
    $wpf_cb720p.IsChecked = $config.Resolution720p
    $wpf_cb1080p.IsChecked = $config.Resolution1080p

    # Clear and load time ranges
    $wpf_ListBoxRanges.Items.Clear()
    if ($config.TimeRanges) {
      foreach ($range in $config.TimeRanges) {
        $wpf_ListBoxRanges.Items.Add($range)
      }
    }

    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    return $true
  }
  catch {
    Write-Host "Error loading configuration: $_" -ForegroundColor Red
    return $false
  }
}

function Show-MainWindow {
  param( $InfoJson, $ytdlPath)

  $psForm = GuiFromXaml ".\gui-main-window.xaml"

  RefreshAndDisplayDestinations $wpf_destinationsListBox

  if ($destination) {

    if ( -not (Test-Path $destination)) {
      Write-Warning "Invalid path: $destination"
    }
    write-host "Preselecting destination: $destination"
    $wpf_destinationsListBox.SelectedItem = $destination
    # // scroll to the selected list item
    $wpf_destinationsListBox.ScrollIntoView($destination)
    $wpf_txtCustomDestination.Text = $destination
  }
  else {
    $wpf_destinationsListBox.SelectedIndex = 0
  }

  #* Generate parameters/initialize variables on GUI events

  function WheelEventHandler() {
    $this.text = $_.delta -gt 0 ? [int]$this.text + 1 : [int]$this.text - 1
  }

  function ForMinutesAndSeconds() {
    if ( [int]$this.text -lt 0  ) { $this.text = 59 }
    if ( [int]$this.text -gt 59 ) { $this.text = 0 }
  }

  # Add event handlers for browser and profile selection
  $wpf_cbCookies.Add_Click({
    if ($wpf_cbCookies.IsChecked) {
        $wpf_spBrowser.Visibility = 'Visible'
    } else {
        $wpf_spBrowser.Visibility = 'Collapsed'
    }
  })

  $wpf_browserComboBox.Add_SelectionChanged({
    $selectedBrowser = $wpf_browserComboBox.SelectedItem
    $wpf_profileComboBox.Items.Clear()
    if ($selectedBrowser -and $availableBrowsers.ContainsKey($selectedBrowser)) {
        foreach ($BrowserProfile in $availableBrowsers[$selectedBrowser]) {
            $wpf_profileComboBox.Items.Add($BrowserProfile)
        }
        $wpf_profileComboBox.SelectedIndex = 0
    }
  })

  # Populate browser combo box
  $availableBrowsers = Get-BrowserProfiles
  foreach ($browserName in $availableBrowsers.Keys) {
    $wpf_browserComboBox.Items.Add($browserName)
  }
  if ($wpf_browserComboBox.Items.Count -gt 0) {
    $wpf_browserComboBox.SelectedIndex = 0
  }

  # Set up the destinationsListBox item selection event handler
  $wpf_destinationsListBox.Add_SelectionChanged({
      if ($wpf_destinationsListBox.SelectedItem) {
        # When a destination is selected from the list, populate the custom destination textbox
        $wpf_txtCustomDestination.Text = $wpf_destinationsListBox.SelectedItem.ToString()
      }
    })

  # Set up the browse button click event handler
  $wpf_btnBrowse.Add_Click({
      # Create folder browser dialog
      $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
      $folderBrowser.Description = "Select Destination Folder"
    
      # If a path is already entered, start from there
      if ($txtCustomDestination.Text -and (Test-Path $txtCustomDestination.Text)) {
        $folderBrowser.SelectedPath = $txtCustomDestination.Text
      }
    
      # Show dialog and update text if user selects a folder
      if ($folderBrowser.ShowDialog() -eq 'OK') {
        $txtCustomDestination.Text = $folderBrowser.SelectedPath
      }
    })
        
  $wpf_CbCustomranges.add_click( { 
        
      $ControlsToToggle = @(
        $wpf_ListBoxRanges, $wpf_labelStart, $wpf_labelEnd, $wpf_hourStart,
        $wpf_hourEnd, $wpf_minuteStart, $wpf_minuteEnd, $wpf_secondStart,
        $wpf_secondEnd, $wpf_BtnSetToZeroStart, $wpf_BtnSetToZeroEnd,
        $wpf_btn_range_loadFromFile, $wpf_buttonAddRange, $wpf_buttonRemoveRange)
            
      ForEach ($Control in $ControlsToToggle) {
        # $args[0] or $This is the event target
        try {
          $control.IsEnabled = $This.IsChecked
        }
        catch {}
         
      }
            
    } )

  $wpf_secondEnd.add_mouseWheel( { WheelEventHandler; ForMinutesAndSeconds })
  $wpf_secondStart.add_mouseWheel( { WheelEventHandler; ForMinutesAndSeconds })
  $wpf_minuteEnd.add_mouseWheel( { WheelEventHandler; ForMinutesAndSeconds })
  $wpf_minuteStart.add_mouseWheel( { WheelEventHandler; ForMinutesAndSeconds; $wpf_minuteEnd.text = $wpf_minuteStart.text })
  $wpf_hourEnd.add_mouseWheel( { WheelEventHandler })
  $wpf_hourStart.add_mouseWheel( { WheelEventHandler; $wpf_hourEnd.text = $wpf_hourStart.text })

  $wpf_BtnSetToZeroStart.add_click({
      $wpf_hourStart.Text = '00'
      $wpf_minuteStart.Text = '00'
      $wpf_secondStart.Text = '00'
    })

  $wpf_BtnSetToZeroEnd.add_click({
      $wpf_hourEnd.Text = '00'
      $wpf_minuteEnd.Text = '00'
      $wpf_secondEnd.Text = '00'
    })

  $wpf_buttonAddRange.add_click( {
      $ItemString = "$($wpf_hourStart.Text):$($wpf_minuteStart.Text):$($wpf_secondStart.Text)-$($wpf_hourEnd.Text):$($wpf_minuteEnd.Text):$($wpf_secondEnd.Text)"
      $wpf_ListBoxRanges.Items.Add( $ItemString  )
    })
  $wpf_buttonRemoveRange.add_click( { 
      $wpf_ListBoxRanges.Items.Remove( $wpf_ListBoxRanges.SelectedItems[0] ) 
    } )
  $wpf_btn_range_loadFromFile.add_click( {
      $wpf_ListBoxRanges.Items.Clear()
    } )

  $wpf_Checkbox_CustomName.add_click({
      $wpf_Textbox_CustomName.IsEnabled = $This.IsChecked
    })

  $wpf_cbCustomFormat.add_click({
      if ($wpf_cbCustomFormat.IsChecked -and $wpf_listboxFormats.Items.Count -eq 0 -and $InfoJson) {
        # Populate formats from InfoJson if not already populated
        PopulateFormatsListbox $InfoJson
      }
    })

  $wpf_BtnPaste.add_click({
      $clipboardContent = (get-clipboard).Trim()
      if ( $clipboardContent -eq "" ) { return }
      $wpf_Checkbox_CustomName.IsChecked = $true
      $wpf_Textbox_CustomName.Text = (Get-Clipboard).Trim()
    })

  $wpf_btnSaveConfig.add_click({
      Save-YtDlpConfig
    })

  $wpf_btnLoadConfig.add_click({
      Get-YtDlpConfig
    })

  $wpf_proceedButton.add_click({

      Save-YtDlpConfig

      # Custom ranges checked but you forgot to add the ranges to the listbox
      if ( $wpf_CbCustomranges.IsChecked -and $wpf_ListBoxRanges.Items.count -eq 0 ) {
        Write-Host Listbox empty! -ForegroundColor Red
        Return
      }
      $CustomDestination = $wpf_txtCustomDestination.Text
      if ( -not ( Test-Path $CustomDestination ) ) {
        Write-Warning "Invalid path: $CustomDestination"
        return
      }
      
      $psForm.hide()

    })

  $wpf_buttonExit.add_click({
      $wpf_mainWindow.close()
      exitAndCloseTerminal
    })

  $wpf_buttonRefreshDestinations.add_click({
      RefreshAndDisplayDestinations $wpf_destinationsListBox   
    })

  # Add Loaded event handler to ensure focus
  $wpf_mainWindow.Add_Loaded({
      $wpf_mainWindow.Activate()
      $wpf_mainWindow.Focus()
        
      # Optionally, if you want to focus a specific control:
      # $wpf_FilesList.Focus()
    })

  # add gui close event handler
  $psForm.add_Closing({
      # $wpf_mainWindow.close()
      exitAndCloseTerminal
    })
 
  if ($InfoJson) {
    $DisplayTemplate = Get-OutputTemplate($InfoJson)
    $DisplayFileName = $InfoJSON | & $ytdlPath  '--load-info-json' - -O $DisplayTemplate
    $wpf_Textbox_CustomName.Text = $DisplayFileName
    PopulateFormatsListbox $InfoJson
  }        
  if ($GivenName -and $GivenName -ne ':default:') {
    $wpf_Textbox_CustomName.Text = $GivenName
    $wpf_Checkbox_CustomName.IsChecked = $true
  }
  $wpf_txtVideoUrl.Text = $url

  $null = Show-WpfFormOnMonitor $psForm 0
  Return

}

function guiAlreadyExistsPrompt {
    
  $objLabel = addLabel  "An entry for this video id already exists. Continue with download?" 
  $okButton = addButton 'Yes'          -below $objLabel -dialogRes Yes
  $cancelButton = addButton 'No'           -after $okButton -dialogRes No #-EventClick { [Environment]::Exit(0) }
  $EverythingButton = addButton 'Everything' -after $cancelButton -dialogRes Abort
  $continueButton = addButton 'More ...'     -after $EverythingButton -dialogRes Continue
    
  $formAlreadyExistsPrompt = addForm '' -controls $objLabel, $okButton, $cancelButton, $EverythingButton, $continueButton `
    -minSize

  $result = $formAlreadyExistsPrompt.ShowDialog()
    
  return $result
    
}

function AndExit {
  if ( $CheckAndExit.Checked ) { exitAndCloseTerminal }
  return
}

function AfterError {
  param( [string]$prompt )

  Write-Host $args
  $LabelError = addLabel $args
  $ButtonRetry = addButton 'Retry' -below $LabelError        -eventClick { Execute }
  $ButtonRestart = addButton 'Restart' -after $ButtonRetry   -eventClick { ./yt-dlp.ps1; return }
  $ButtonExit = addButton 'Exit'      -after $ButtonRestart -eventClick { exitAndCloseTerminal }
  $FormError = addForm -minSize -controls $LabelError, $ButtonRetry, $ButtonRestart, $ButtonExit
  $FormError.ShowDialog()

}