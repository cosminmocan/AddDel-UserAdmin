function Get-DestFolder{
    if((Test-Path C:\sysstuff) -eq $false){
        New-Item -Path "c:\" -Name "ict" -ItemType "directory"
        $folder=get-item C:\sysstuff
        $folder.attributes="Hidden"
        Write-Debug "Folder created and hidden" 
    }

    if((Test-Path C:\sysstuff) -eq $true){
        Write-Debug "Folder already exists" 
    }
}

Get-DestFolder
$user_SID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User | Select-Object -Property "Value"
$user_SID.Value |Out-File "C:\sysstuff\$($env:USERNAME).sid"