# . D:\Mega\IDEs\powershell\functions-forms.ps1
# Add-Type -AssemblyName System.Windows.Forms
# Add-Type -AssemblyName System.Drawing


function Show-DownloadCompleteWindow {
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
}

function GenerateParameters {

    $destination = $wpf_destinationsListBox.SelectedItem ? $wpf_destinationsListBox.SelectedItem : [Environment]::GetFolderPath("Desktop") 
    $isCookies = $wpf_cbCookies.IsChecked      ? $true : $false
    $CustomRange = $wpf_CbCustomranges.IsChecked ? $true : $false
    $Items = $wpf_ListBoxRanges.Items
    $CustomName = $wpf_Checkbox_CustomName.IsChecked ? $wpf_Textbox_CustomName.Text : $False
    $720p = $wpf_cb720p.IsChecked ? $true : $false
    $1080p = $wpf_cb1080p.IsChecked ? $true : $false

    Return @{
        Destination  = $destination
        IsCookies    = $isCookies
        CustomRange  = $CustomRange
        Items        = $Items
        CustomName   = $CustomName
        SeventTwenty = $720p
        TenEighty    = $1080p
    }

}

function Show-MainWindow {
    param( $InfoJson, $ytdlPath)

    $psForm = GuiFromXaml ".\gui-main-window.xaml"

    # Get-Variable wpf_*

    if ( Test-Path W: ) {
        get-childitem -path 'w:\#later' -directory | ForEach-Object { [void] $wpf_destinationsListBox.Items.Add( $_.fullname ) } 
    }
    [void] $wpf_destinationsListBox.Items.Add( [Environment]::GetFolderPath("Desktop") )
    [void] $wpf_destinationsListBox.Items.Add("$HOME\Downloads")

    # $DownloadParameters = 'man is'

    #* Generate parameters/initialize variables on GUI events

    function WheelEventHandler() {
        $this.text = $_.delta -gt 0 ? [int]$this.text + 1 : [int]$this.text - 1
    }

    function ForMinutesAndSeconds() {
        if ( [int]$this.text -lt 0  ) { $this.text = 59 }
        if ( [int]$this.text -gt 59 ) { $this.text = 0 }
    }
        
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
            foreach ($line in Get-Content .\yt-dlp_cutom_ranges.txt) { $wpf_ListBoxRanges.Items.Add( $line ) }        
        } )

    $wpf_Checkbox_CustomName.add_click({
            $wpf_Textbox_CustomName.IsEnabled = $This.IsChecked
            $wpf_BtnPaste.IsEnabled = $This.IsChecked
        })

    $wpf_BtnPaste.add_click({
            $wpf_Textbox_CustomName.Text = (Get-Clipboard).Trim()
        })

    $wpf_proceedButton.add_click({
            # Custom ranges checked but you forgot to add the ranges to the listbox
            if ( $wpf_CbCustomranges.IsChecked -and $wpf_ListBoxRanges.Items.count -eq 0 ) {
                Write-Host Listbox empty! -ForegroundColor Red
                Return
            }
            
            Set-Content -Path ./yt-dlp_cutom_ranges.txt -Value $wpf_ListBoxRanges.Items
            $psForm.hide()
        })
        
    $DisplayTemplate = Get-OutputTemplate($InfoJson)
    $DisplayFileName = $InfoJSON | & $ytdlPath  '--load-info-json' - -O $DisplayTemplate
    $wpf_Textbox_CustomName.Text = $DisplayFileName
        
    $null = $psForm.ShowDialog()
    # Write-Host $Result
    Return

}

function guiAlreadyExistsPrompt {
    
    $objLabel = addLabel  "An entry for this video id already exists. Continue with download?" 
    $okButton = addButton 'Yes'          -below $objLabel -dialogRes Yes
    $cancelButton = addButton 'No'           -after $okButton -dialogRes No #-EventClick { [Environment]::Exit(0) }
    $ButtonDelEnt = addButton 'Delete Entry' -after $cancelButton -dialogRes Abort
    $continueButton = addButton 'More ...'     -after $ButtonDelEnt -dialogRes Continue
    
    $formAlreadyExistsPrompt = addForm '' -controls $objLabel, $okButton, $cancelButton, $ButtonDelEnt, $continueButton `
        -minSize

    $result = $formAlreadyExistsPrompt.ShowDialog()
    
    return $result
    
}

function AndExit {
    if ( $CheckAndExit.Checked ) { exitAndCloseTerminal }
    return
}

function infoJsonOperations {
    param(
        [Parameter(mandatory = $true)]$pathToJson,
        $pathToVideo )
    
    $jsonOnDisk = Get-Content -Path $pathToJson | ConvertFrom-Json
	
    $HasDesc = [bool]($JsonOnDisk.PSobject.Properties.name -match "description") ? $true : $false
    if ( $HasDesc ) { $VideoDesc = $jsonOnDisk.description }
    
    $explorerPath = 'C:\windows\explorer.exe'
    $PlayerPath = 'D:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe'
	
    $ControlsGB1 = @(
( $buttonOpenVf = addButton 'Open'   15 20                    -eventClick { . $PlayerPath $pathToVideo; AndExit } ),
( $buttonLocateVf = addButton 'Locate'   -after $buttonOpenVf   -eventClick { Start-Process -FilePath $explorerPath -ArgumentList "/select, ""$pathToVideo""" ; AndExit } ),
( $buttonConvert = addButton 'Convert'  -after $buttonLocateVf -eventClick { . 'D:\Mega\IDEs\powershell\ffmpeg-convert.ps1' $pathToVideo -fixAudio } ),
( $buttonFixAudio = addButton 'FixAudio' -after $buttonConvert  -eventClick { } )
( $buttonSource = addButton 'Source' -after $buttonLocateVf -eventClick { Start-Process $jsonOnDisk.webpage_url ; AndExit } ),
( $buttonOp = addButton 'OP'     -below $buttonOpenVf   -eventClick { Start-Process $jsonOnDisk.uploader_url; AndExit } ),
( $ButtonEveryth = addButton 'Evth'   -after $buttonOp -eventClick {
            Start-Process "ES:$($jsonOnDisk.extractor) $($jsonOnDisk.id)" } )
    )
	
    $ControlsGB2 = @(
		( $buttonOpenIjf = addButton 'Open'   5 20                  -eventClick { Invoke-Item $pathToJson; AndExit } ),
		( $buttonLocateIjf = addButton 'Locate' -after $buttonOpenIjf -eventClick { Start-Process -FilePath $explorerPath -ArgumentList "/select, ""$pathToJson"""; AndExit }  )
    )
	
    $Controls = @(
		( $Groupbox1 = addGroupBox 'Video file'      -w 300 -controls $ControlsGB1 ),
		( $Groupbox2 = addGroupBox '.info.json file' -w 100 -controls $ControlsGB2 -after $Groupbox1 ),
		( $CheckAndExit = addCheckBox '... and exit' -below $Groupbox1 ),
		( $labelTitle = addLabel    "Title      :" -below $CheckAndExit ),
		( $TextBoxTitle = addTextBox $($jsonOnDisk.title) 500 50 -ReadOnly -Multiline -Wrap -below $labelTitle )
    )
	
    if ( $HasDesc ) {
        $Controls += ( $labelDes = addLabel "Description:" -below $TextBoxTitle ),
		             ( $TextBoxDes = addTextBox $VideoDesc 500 50 -ReadOnly -Multiline -Wrap -below $labelDes )
        # $TextBoxDes.Height = '50'
        # $TextBoxDes.Width  = '500' 
    }
    
    [System.Windows.Forms.Application]::EnableVisualStyles()

    if ( [System.IO.File]::Exists( $pathToJson ) ) {		
        $PathToCommentsJson = "D:\Mega\IDEs\powershell\yt-dlp archive\($extractor)$($VideoId)_comments.info.json"
        $Controls += ( $buttonComments = addButton 'Comments' -eventClick {
                $commentsJson = Get-Content -Path $PathToCommentsJson ConvertFrom-Json
                Show-JsonTreeView( $commentsJson )
            } )
    }

    if ( -not ( Test-Path -LiteralPath $pathToVideo ) ) {
        $buttonOpenVf.Enabled = $false
        $buttonLocateVf.Enabled = $false
    }
    
    $formInfoJson = addForm '' -minSize -controls $Controls
    $formInfoJson.ShowDialog()

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