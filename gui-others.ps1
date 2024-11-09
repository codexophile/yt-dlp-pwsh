$AfterListXaml = @'
<Window x:Class="MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell WPF GUI" Height="150" Width="300">
    <Grid>
        <Label Content="How would you like to proceed?" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,20,0,0"/>
        <Button Name="btnExit" Content="Exit" HorizontalAlignment="Left" Margin="50,60,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="btnDownload" Content="Download" HorizontalAlignment="Right" Margin="0,60,50,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
'@

$DestinationPromptXaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Title="Download Destination Selector" 
    Height="450" 
    Width="600"
    WindowStartupLocation="CenterScreen"
    Background="#F0F0F0">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="Select Download Destination" 
                      FontSize="24" 
                      FontWeight="SemiBold" 
                      Foreground="#333333"/>
            <TextBlock Text="Choose from available locations below" 
                      FontSize="14" 
                      Foreground="#666666" 
                      Margin="0,5,0,0"/>
        </StackPanel>

        <!-- ListBox with destinations -->
        <Border Grid.Row="1" 
                BorderThickness="1" 
                BorderBrush="#DDDDDD" 
                CornerRadius="4" 
                Background="White">
            <ListBox Name="DestinationsListBox" 
                     Margin="5"
                     BorderThickness="0"
                     SelectionMode="Single"
                     FontSize="14">
                <ListBox.ItemContainerStyle>
                    <Style TargetType="ListBoxItem">
                        <Setter Property="Padding" Value="10,8"/>
                        <Setter Property="Margin" Value="0,2"/>
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#007ACC"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#F5F5F5"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </ListBox.ItemContainerStyle>
            </ListBox>
        </Border>

        <!-- Buttons -->
        <StackPanel Grid.Row="2" 
                    Orientation="Horizontal" 
                    HorizontalAlignment="Right" 
                    Margin="0,15,0,0">
            <Button Name="RefreshButton" 
                    Content="Refresh" 
                    Width="100" 
                    Height="35" 
                    Margin="0,0,10,0">
                <Button.Style>
                    <Style TargetType="Button">
                        <Setter Property="Background" Value="#007ACC"/>
                        <Setter Property="Foreground" Value="White"/>
                        <Setter Property="FontSize" Value="14"/>
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}"
                                            BorderThickness="0"
                                            CornerRadius="4">
                                        <ContentPresenter HorizontalAlignment="Center" 
                                                        VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#005A9E"/>
                                        </Trigger>
                                        <Trigger Property="IsPressed" Value="True">
                                            <Setter Property="Background" Value="#004275"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                    </Style>
                </Button.Style>
            </Button>
            <Button Name="SelectButton" 
                    Content="Select" 
                    Width="100" 
                    Height="35">
                <Button.Style>
                    <Style TargetType="Button">
                        <Setter Property="Background" Value="#007ACC"/>
                        <Setter Property="Foreground" Value="White"/>
                        <Setter Property="FontSize" Value="14"/>
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}"
                                            BorderThickness="0"
                                            CornerRadius="4">
                                        <ContentPresenter HorizontalAlignment="Center" 
                                                        VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#005A9E"/>
                                        </Trigger>
                                        <Trigger Property="IsPressed" Value="True">
                                            <Setter Property="Background" Value="#004275"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                    </Style>
                </Button.Style>
            </Button>
        </StackPanel>
    </Grid>
</Window>
'@

$AfterListXaml | Out-Null
$DestinationPromptXaml | Out-Null