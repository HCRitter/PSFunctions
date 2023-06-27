function Restart-ComputerToFirmWare {
    <#
        .SYNOPSIS
        Restarts the computer and enters the firmware (BIOS) settings on UEFI devices.

        .DESCRIPTION
        The Restart-ComputerToFirmWare function allows you to restart a UEFI-based computer and access the firmware settings. It initiates a restart, enters the firmware settings, and provides the flexibility to specify a timeout period if needed.

        .PARAMETER Timeout
        Specifies the time in seconds to wait before restarting the computer. The parameter accepts an integer value within the range of 0 to 315360000 (approximately 10 years). The default value is 0, indicating an immediate restart.

        .EXAMPLE
        Restart-ComputerToFirmWare -Timeout 60
        Restarts the computer and enters the firmware settings after waiting for 60 seconds.

        .EXAMPLE
        Restart-ComputerToFirmWare
        Restarts the computer and immediately enters the firmware settings.

        .NOTES
        - This function only works on UEFI devices. It checks if Windows is installed on UEFI mode before executing the restart command.
    #>
    [CmdletBinding()]
    param (
        [ValidateRange(0, 315360000)]
        $Timeout = 0
    )
    
    begin {
        #Check if Windows is installed on UEFIMode
        if($env:firmware_type -ne "UEFI"){
            Write-Error "This only works on UEFI Devices"
            return
        }
    }
    
    process {
        shutdown /r /fw /f /t $Timeout
    }
    
    end {
        
    }
}