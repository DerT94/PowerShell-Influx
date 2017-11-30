﻿Function Send-HostMetrics {
    <#
        .SYNOPSIS
            Sends common ESX Host metrics to Influx.

        .DESCRIPTION
            By default this cmdlet sends metrics for all ESX hosts returned by Get-VMHost.

        .PARAMETER Measure
            The name of the measure to be updated or created.

        .PARAMETER Tags
            An array of host tags to be included. Default: 'Name','Parent','State','PowerState','Version'

        .PARAMETER Hosts
            One or more hosts to be queried.

        .PARAMETER Server
            The URL and port for the Influx REST API. Default: 'http://localhost:8086'

        .PARAMETER Database
            The name of the Influx database to write to. Default: 'vmware'. This must exist in Influx!

        .EXAMPLE
            Send-HostMetrics -Measure 'TestESXHosts' -Tags Name,Parent -Hosts TestHost*
            
            Description
            -----------
            This command will submit the specified tag and common ESX host data to a measure called 'TestESXHosts' for all hosts starting with 'TestHost'
    #>  
    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [String]
        $Measure = 'ESXHost',

        [String[]]
        $Tags = ('Name','Parent','State','PowerState','Version'),

        [String[]]
        $Hosts = '*',

        [Alias('DB')]
        [string]
        $Database ='vmware',
        
        [string]
        $Server = 'http://localhost:8086'
    )

    Write-Verbose 'Getting hosts..'
    $Hosts = Get-VMHost $Hosts

    Write-Verbose 'Getting host statistics..'
    $Stats = $Hosts | Get-Stat -MaxSamples 1 -Common | Where {-not $_.Instance}

    foreach ($Host in $Hosts) {
        
        $TagData = @{}
        ($Host | Select $Tags).PSObject.Properties | ForEach-Object { $TagData.Add($_.Name,$_.Value) }

        $Metrics = @{}
        $Stats | Where-Object { $_.Entity.Name -eq $Host.Name } | ForEach-Object { $Metrics.Add($_.MetricId,$_.Value) }

        Write-Verbose "Sending data for $($Host.Name) to Influx.."
        Write-Verbose $TagData
        Write-Verbose $Metrics

        if ($PSCmdlet.ShouldProcess($Host.name)) {
            Write-Influx -Measure $Measure -Tags $TagData -Metrics $Metrics -Database $Database -Server $Server
        }
    }
}