<#
.SYNOPSIS
    Install standard programs with Chocolatey.
.DESCRIPTION
    Install standard programs with Chocolatey by installing Chocolatey, installing packages (Google Chrome, Firefox, and Adobe Reader), and removing Chocolatey if requested.
.PARAMETER Packages
    Packages to install from Chocolatey.
.PARAMETER RemoveChoco
    Remove Chocolatey after the packages are installed.
.EXAMPLE
    Install-StandardPrograms.ps1

    Installs Chocolatey, Google Chrome, Firefox, and Adobe Reader.
.EXAMPLE
    Install-StandardPrograms.ps1 -RemoveChoco

    Installs Chocolatey, Google Chrome, Firefox, and Adobe Reader. After it's finished, Chocolatey is then removed from the system.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$Packages = @("googlechrome", "firefox", "adobereader"),
    [Parameter(Position = 1)]
    [switch]$RemoveChoco
)

begin {
    Write-Verbose "Checking for internet connection."
    $NumOfAttempts = 1
    while ($NumOfAttempts -le 5) {
        switch (Test-NetConnection -ComputerName "chocolatey.org" | Select-Object -ExpandProperty "PingSucceeded") {
            $true {
                Write-Verbose "Connection succeeded. Continuing script."
                $NumOfAttempts = 6
            }

            { (($PSItem -eq $false) -and ($NumOfAttempts -eq 5)) } {
                $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
                        [System.Net.NetworkInformation.PingException]::new("Connection test failed 5 times."),
                        "PingFailure",
                        [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                        "NetworkConnection"
                    )
                )
            }

            Default {
                Write-Warning "Failed connection test. [$($NumOfAttempts)/5]"
                $NumOfAttempts++
                Start-Sleep -Seconds 5
            }
        }
    }
}

process {
    Write-Verbose "Installing Chocolatey."
    switch (Test-Path -Path "$($env:SystemDrive)\ProgramData\chocolatey\choco.exe") {

        $true {
            Write-Verbose "Chocolatey already found. Skipping install."
        }

        Default {
            Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
    }

    Write-Verbose "Installing packaged from Chocolatey."
    Start-Process -FilePath "choco" -ArgumentList @(
        "install",
        ($Packages -join " "),
        "-y",
        "--limit-output",
        "--no-progress") -NoNewWindow -Wait -ErrorAction Stop

    switch ($RemoveChoco) {
        $true {
            Write-Verbose "Removing Chocolatey."

            $null = Remove-Item -Path "$($env:SystemDrive)\ProgramData\chocolatey" -Recurse -Force
            [System.Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, "Machine")
            [System.Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null, "Machine")
            [System.Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, "User")
            [System.Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null, "User")
        }
    }
}