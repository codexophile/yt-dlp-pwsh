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