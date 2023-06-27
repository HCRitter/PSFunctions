function Start-MultiJob {
    <#
        .SYNOPSIS
        Start-MultiJob is a function that allows you to run multiple jobs concurrently and display their progress using a spinning cursor. It takes a list of script blocks as input and starts a job for each script block. The function continuously updates the job status and displays the progress on the console using a spinning cursor animation. The status for each line will be overwritten to provide real-time updates.

        .SYNTAX
        Start-MultiJob [-Jobs] <scriptblock[]> [[-SpinningCursor] <string[]>]

        .PARAMETER Jobs
        -Jobs <scriptblock[]>
        Specifies an array of script blocks representing the jobs to be executed concurrently.

        .PARAMETER SpinningCursor
        -SpinningCursor <string[]>
        Specifies an array of characters used for the spinning cursor animation. The default value is a set of characters: "|", "/", "-", and "\".

        .EXAMPLE
        
        PS> Start-MultiJob -Jobs $Jobs

        .NOTES

        The Start-MultiJob function relies on the Start-Job cmdlet to initiate jobs.
        The function continuously updates the job status and displays the progress until all jobs have completed.
        The progress of each job is shown using a spinning cursor animation.
        The status for each line will be overwritten to provide real-time updates.
        The job results are summarized at the end, indicating whether each job completed successfully or failed.
        The function temporarily hides the cursor during job execution and restores it afterwards.
    #>
    [CmdletBinding()]
    param (
        [scriptblock[]]$Jobs,
        [string[]]$SpinningCursor = @("|","/","-","\")
    )
    
    begin {
        function Clear-HostedLine {
            param (
                [int]$Line
            )
            
            $EmptyString = " " * [console]::WindowWidth
            $host.UI.RawUI.CursorPosition = @{ X = 0; Y = $Line }
            Write-Host "$EmptyString"
        }
        function Write-HostedLine {
            param (
                $JobItem,
                [switch]$Clear=$false,
                [switch]$Success =$false,
                [switch]$Failed =$false
            )
            if($Clear){
                Clear-HostedLine -Line $JobItem.Line
            }
            $host.UI.RawUI.CursorPosition = @{ X = 0; Y = $JobItem.Line }
            if($Success){
                Write-Host "[+]$($JobItem.LastDisplayMessage)" -ForegroundColor Green
            }elseif ($Failed) {
                Write-Host "[-]$($JobItem.LastDisplayMessage)" -ForegroundColor Red
            }else {
                Write-Host "[$($SpinningCursor[$JobItem.CursorIconIndex])]$($JobItem.LastDisplayMessage)"
            }

        }
        $CursorPosition = $Host.UI.RawUI.CursorPosition.Y

        $JobList = $Jobs.ForEach({
            [PSCustomObject]@{
                Job = $Job = Start-Job -ScriptBlock $PSItem
                Set = $Job.ID
                Line = $CursorPosition
                LastDisplayMessage = $Null
                CursorIconIndex = 0
            }
            $CursorPosition++
        })
        
        [System.Console]::CursorVisible = $false
        
        
        Start-Sleep -Milliseconds 100
    }
    
    process {
        do {
            foreach($JobItem in $JobList | Where-Object{$PSItem.Job.State -eq "running"}){
                if($null -ne $JobItem.Job.ChildJobs.Information){
                    if($JobItem.LastDisplayMessage -ne $JobItem.Job.ChildJobs.Information[-1]){
                        $JobItem.LastDisplayMessage = $JobItem.Job.ChildJobs.Information[-1]
                        Clear-HostedLine -Line $JobItem.Line
                    }
                    Write-HostedLine -JobItem $JobItem
                    $JobItem.CursorIconIndex++
                    if ($JobItem.CursorIconIndex -eq $SpinningCursor.Count) {
                        $JobItem.CursorIconIndex = 0
                    }
                }
            }
            Start-Sleep -Milliseconds 50
        } until ($JobList.Job.State -notcontains "running")
        
        # Make sure every information stream has been written
        foreach($JobItem in $JobList){
            if ($JobItem.Job.State -eq "completed") {
                Write-HostedLine -Clear -Success -JobItem $JobItem
            } else {
                Write-HostedLine -Clear -Failed -JobItem $JobItem
            }
        }
    }
    
    end {
        $host.UI.RawUI.CursorPosition = @{ X = 0; Y = $CursorPosition }
        [System.Console]::CursorVisible = $true
    }
}