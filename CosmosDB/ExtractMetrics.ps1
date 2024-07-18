function Get-SystemMetrics {
    try {
        # Hostname
        $deviceName = $env:COMPUTERNAME

        # CPU Usage
        $cpuUsage = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

        # Memory Usage
        $memory = Get-WmiObject Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize -First 1
        $totalMemoryMB = [decimal]$memory.TotalVisibleMemorySize / 1MB
        $freeMemoryMB = [decimal]$memory.FreePhysicalMemory / 1MB
        $memoryUsage = ([decimal]$freeMemoryMB / $totalMemoryMB) * 100

        # Disk Usage (adjust for specific drive)
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3" | Select-Object FreeSpace, Size -First 1
        $totalDiskSpaceGB = [decimal]$disk.Size / 1GB
        $freeDiskSpaceGB = [decimal]$disk.FreeSpace / 1GB
        $diskUsage = ([decimal]$totalDiskSpaceGB - $freeDiskSpaceGB) / $totalDiskSpaceGB * 100

       # Extract OU
       $ou = # While I can't disclose the specific method due to privacy concerns, put you method which typically extracts OU values from devices?

        return [PSCustomObject]@{
            Timestamp = Get-Date
            device = $deviceName
            ou = $ou
            CPUUsage = $cpuUsage
            MemoryUsage = $memoryUsage
            DiskUsage = $diskUsage
            
        }
    } catch [System.Management.ManagementException] {
        Write-Warning "Error getting system metrics: $($_.Exception)"
        return $null
    }
}
