[CmdletBinding(SupportsShouldProcess)]
param()

begin {
    #Create a temp file to have output from reg redirected to.
    $TmpFile = New-TemporaryFile

    #Get the registry hive and OneDrive start menu shortcut files and store them in variables for later.
    Write-Verbose "Getting default user's registry hive."
    $DefaultProfileHive = Get-Item -Path "$($env:SystemDrive)\Users\Default\NTUSER.DAT"
    Write-Verbose "Getting default user's start shortcut for OneDrive."
    $DefaultProfileOneDriveStart = Get-Item -Path "$($env:SystemDrive)\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
}

process {
    #Load the default profile's registry hive to 'HKLM:\Default'.
    Write-Verbose "Loading default user's registry hive to 'HKLM:\Default'."
    Start-Process -FilePath "reg" -ArgumentList "load HKLM\Default $($DefaultProfileHive.FullName)" -NoNewWindow -Wait -RedirectStandardOutput $TmpFile

    #Remove the OneDriveSetup value if it exists.
    if (Get-ItemProperty -Path "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Run\" -Name "OneDriveSetup" -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess("HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Run\", "Remove OneDriveSetup")) {
            $null = Remove-ItemProperty -Path "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Run\" -Name "OneDriveSetup" -Force
        }
    }

    #Remove the start menu shortcut for OneDrive from the default user's profile.
    if ($PSCmdlet.ShouldProcess($DefaultProfileOneDriveStart, "Remove")) {
        $null = Remove-Item -Path $DefaultProfileOneDriveStart -ErrorAction SilentlyContinue -Force
    }
}

end {
    #Run garbage collection and then unload the default user's registry hive.
    #Garbage collection is required to gracefully unload the hive.
    Write-Verbose "Running garbage collection."
    [System.GC]::Collect()
    Write-Verbose "Unloading default user's registry hive."
    Start-Process -FilePath "reg" -ArgumentList "unload HKLM\Default" -NoNewWindow -Wait -UseNewEnvironment -RedirectStandardOutput $TmpFile

    #Remove the temp file created earlier.
    $null = Remove-Item -Path $TmpFile -Force -WhatIf:$false

    return [pscustomobject]@{
        "OneDriveRunKey"        = "Removed";
        "OneDriveStartShortcut" = "Removed"
    }
}