Function Ping-BySourceIP {
<#
    .SYNOPSIS
        Pings a destination using a source IP address
    .DESCRIPTION
        Sends ICMP echo requests from a specific local network adapter using the built-in 
        ping.exe utility. Specify a source IP address and optionally the destination host, 
        byte size or count. The -Quiet and -Detailed parameters can be used to parse the 
        text with regular expressions to return either a boolean value or a results object.
    .PARAMETER Source
        An IP address of a local network adapter. This parameter is required.
    .PARAMETER Destination
        An IP address or hostname to send packets to. If -ForceIPv6 is used this
        parameter is required, else the default value is "internetbeacon.msedge.net".
    .PARAMETER Count
        Number of packets to send, in the range 1 - 4294967295. The default value is 2.
    .PARAMETER Size
        Byte size of packets to send, in the range 0 - 65500. The default value is 32.
    .PARAMETER NoFrag
        Specifies that packets should not be fragmented whilst en route. When using -Quiet 
        or -Detailed a packet that requires fragmentation will be evaluated as a failed 
        response. This parameter cannot be used with the -ForceIPv6 option.
    .PARAMETER ResolveIP
        When specified with an IP address for the -Destination parameter attempts to 
        perform a reverse DNS lookup to retrieve the destination hostname.
    .PARAMETER ForceIPv6
        Forces the command to use IPv6 - By default ping is forced to use IPv4. If
        specified the -Destination parameter is required.
    .PARAMETER Quiet
        Return a boolean value - True if any pings succeed, else False.
    .PARAMETER Detailed
        Return an object of the result, counts, latency and text.
    .INPUTS
        System.String
        You can pipe a string that represents a source IP address to this function.
    .OUTPUTS
        System.String, System.Boolean or System.Management.Automation.PSCustomObject
        By default this function will generate 1 or more strings from ping.exe.
        You can specify Quiet to generate a Boolean or Detailed to generate a PSCustomObject.
    .NOTES
        Release Date: 2018-03-25
        Author: Francis Hagyard
    .EXAMPLE
        Ping-BySourceIP -Source 192.168.0.13

        Pinging ds-c-0003.c-msedge.net [13.107.4.52] from 192.168.0.13 with 32 bytes of data:
        Reply from 13.107.4.52: bytes=32 time=13ms TTL=120
        Reply from 13.107.4.52: bytes=32 time=14ms TTL=120
  
        Ping statistics for 13.107.4.52:
            Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
        Approximate round trip times in milli-seconds:
            Minimum = 13ms, Maximum = 14ms, Average = 13ms

        Ping using a specific source IP address and return normal output.
    .EXAMPLE
        "192.168.0.13" | Ping-BySourceIP -Quiet

        True

        In this example, the source IP address is piped to the function and the -Quiet parameter
        is used to return a boolean value.
    .EXAMPLE
        Ping-BySourceIP -Source 192.168.0.13 -Destination www.google.com -Count 4 -Size 64 -NoFrag -Detailed

        Result      : True
        Sent        : 4
        Received    : 4
        Percent     : 100
        Size        : 64
        NoFrag      : True
        Source      : 192.168.0.13
        Destination : www.google.com [216.58.206.68]
        MinTime     : 21
        MaxTime     : 38
        AvgTime     : 26
        Text        : {, Pinging www.google.com [216.58.206.68] from 192.168.0.13 with 64 bytes of data:, Reply from 216.58.206.68: bytes=64 time=22ms TTL=47, Reply from 216.58.206.68: bytes=64 time=21ms TTL=47...}

        In this example, a specific destination is included along with a non-default count and byte size.
        The -NoFrag parameter is used to prevent routers from fragmenting the packets and the -Detailed
        parameter is used to return an object containing the result, counts, latency and text.
    .EXAMPLE 
        Example of script use:

        $IPAddress = "192.168.0.13"
        $Connected = Ping-BySourceIP -Source $IPAddress -Quiet
        If (!$Connected) {
            $Adapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where {$_.IPAddress -contains $IPAddress}
            $Null = $Adapter.ReleaseDHCPLease()
            Start-Sleep -Seconds 5
            $Null = $Adapter.RenewDHCPLease()
        }

        In this example, the first step assigns an IP address to the $IPAddress variable as a string. 
  
        In the second step, the function tests whether the IP address can ping the default host using 
        the -Quiet parameter to return a boolean value and stores the result in the $Connected variable.

        In the third step, the scriptblock is only executed if $Connected is not True. Inside the 
        scriptblock the Get-WmiObject cmdlet is piped to Where-Object to determine which local adapter
        has the IP address and a WMI object representing the adapter is stored in the $Adapter variable. 
        The .ReleaseDHCPLease() method is called to release the DHCP lease on the adapter and the results
        assigned to the $Null automatic variable to prevent output being generated. 
        The script then waits for 5 seconds before calling the .RenewDHCPLease() method, attempting 
        to renew the DHCP lease on the adapter.
    .LINK
        Project page: https://github.com/BoonMeister/Ping-BySourceIP
#>
    [CmdletBinding(DefaultParameterSetName="RegularPing",
                    PositionalBinding=$True,
                    HelpUri="https://github.com/BoonMeister/Ping-BySourceIP")]
    [OutputType("System.String")]
    [OutputType("System.Boolean")]
    [OutputType("System.Management.Automation.PSCustomObject")]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidatePattern("^[0-9a-fA-F:][0-9a-fA-F:.]+[0-9a-fA-F]$")]
        [ValidateNotNullOrEmpty()]
        [String]$Source,
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False,Position=1)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False,Position=1)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False,Position=1)]
        [Parameter(ParameterSetName="Regularv6Ping",Mandatory=$True,Position=1)]
        [Parameter(ParameterSetName="Quietv6Ping",Mandatory=$True,Position=1)]
        [Parameter(ParameterSetName="Detailedv6Ping",Mandatory=$True,Position=1)]
        [ValidatePattern("^[0-9a-zA-Z:][0-9a-zA-Z:.-]+[0-9a-zA-Z]$")]
        [ValidateNotNullOrEmpty()]
        [String]$Destination = "internetbeacon.msedge.net",
        [Parameter(Mandatory=$False,Position=2)]
        [ValidateRange(1,4294967295)]
        [Int]$Count = 2,
        [Parameter(Mandatory=$False,Position=3)]
        [ValidateRange(0,65500)]
        [Int]$Size = 32,
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [Switch]$NoFrag = $False,
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [Parameter(ParameterSetName="Regularv6Ping",Mandatory=$False)]
        [Parameter(ParameterSetName="Detailedv6Ping",Mandatory=$False)]
        [Switch]$ResolveIP = $False,
        [Parameter(ParameterSetName="Regularv6Ping",Mandatory=$True)]
        [Parameter(ParameterSetName="Quietv6Ping",Mandatory=$True)]
        [Parameter(ParameterSetName="Detailedv6Ping",Mandatory=$True)]
        [Switch]$ForceIPv6 = $False,
        [Parameter(ParameterSetName="QuietPing",Mandatory=$True)]
        [Parameter(ParameterSetName="Quietv6Ping",Mandatory=$True)]
        [Switch]$Quiet = $False,
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$True)]
        [Parameter(ParameterSetName="Detailedv6Ping",Mandatory=$True)]
        [Switch]$Detailed = $False
    )
    Begin {
        # Effectively Start-Process with stdout redirection and better window suppression
        Function Get-ProcessOutput {
            Param(
                [Parameter(Mandatory=$True)]
                [String]$Command,
                [String]$ArgList,
                [Switch]$NoWindow = $False,
                [Switch]$UseShell = $False,
                [Switch]$WaitForOutput = $False
            )
            $ProcInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcInfo.CreateNoWindow = $NoWindow
            $ProcInfo.FileName = $Command
            $ProcInfo.RedirectStandardError = $True
            $ProcInfo.RedirectStandardOutput = $True
            $ProcInfo.UseShellExecute = $UseShell
            $ProcInfo.Arguments = $ArgList
            $ProcObject = New-Object System.Diagnostics.Process
            $ProcObject.StartInfo = $ProcInfo
            $Null = $ProcObject.Start()
            If ($WaitForOutput) {
                $Output = $ProcObject.StandardOutput.ReadToEnd()
                $ProcObject.WaitForExit()
                $Output
            }
            Else {
                Do {
                    $ProcObject.StandardOutput.ReadLine()
                } Until ($ProcObject.HasExited)
                $ProcObject.StandardOutput.ReadToEnd()
                $ProcObject.WaitForExit()
            }
        }
    }
    Process {

        $MainCommand = "ping.exe"

        # Add switches etc per params
        If ($ResolveIP) {$ProcArgs = "-a -n $Count -l $Size"}
        Else {$ProcArgs = "-n $Count -l $Size"}

        If ($NoFrag) {$ProcArgs += " -f"}

        If ($ForceIPv6) {$ProcArgs += " -S $Source -6 $Destination"}
        Else {$ProcArgs += " -S $Source -4 $Destination"}

        # Parse response with regex to return a boolean value or custom object
        If ($Quiet -or $Detailed) {

            # Text patterns used to determine first line of output and line showing latency details
            $FirstLineRegEx,$LatencyRegEx = "bytes of data:","Average = "
            
            # Counters for number of packets sent and received
            $ReturnedCount,$LineCount = 0,0

            # Run ping and split output by carriage return & newline
            $PingResults = (Get-ProcessOutput -Command $MainCommand -ArgList $ProcArgs -NoWindow -WaitForOutput) -split "\r\n"

            # Check how many lines of output ping returned
            If ($PingResults.Count -gt 2) {

                $ResultTable = @()

                # Select only the packet response lines of output
                $PacketResults = (($PingResults | Select-String $FirstLineRegEx -Context (0,$Count)) -split "\r\n")[1..$Count].Trim()

                # Loop through packet response lines
                Foreach ($Line in $PacketResults) {

                    $LineCount += 1

                    # Use regex to try and determine whether the ping was successful
                    If ($Line -match "^Reply from .+(time=|time<)") {$PacketTest = $True}
                    ElseIf ($Line -match "timed out| unreachable|General failure|transmit failed|needs to be fragmented") {$PacketTest = $False}
                    Else {Throw "Regex failed to match on packet number $LineCount. The data was: '$Line'"}

                    If ($PacketTest) {$ReturnedCount += 1}

                    $ResultTable += $PacketTest
                }

                # Determine percent successful
                $PercentValue,$SentCount,$SizeVar = [Int]($ReturnedCount/$Count*100),$Count,$Size

                # Determine result (true if at least one ping succeeded)
                If ($ResultTable -contains $True) {$Result = $True}
                Else {$Result = $False}
            }
            # Less than 3 lines of output, assumed to have failed (e.g. invalid hostname or ip address)
            Else {$SentCount,$PercentValue,$Result = 0,0,$False}

            # Quiet switch used so return boolean ($Result)
            If ($Quiet) {$Result}
            ElseIf ($Detailed) {

                If ($PingResults | Select-String $FirstLineRegEx -Quiet) {

                    # Use regex to select source and destination from output
                    $FirstLine = ($PingResults | Select-String $FirstLineRegEx).ToString() -split " from "
                    $SourceStr = ($FirstLine[1] -split " ")[0]
                    $DestStr = $FirstLine[0] -replace "^Pinging ",""
                }
                Else {$SourceStr,$DestStr = $Source,$Destination}

                If ($Result -and ($PingResults | Select-String $LatencyRegEx -Quiet)) {

                    # Use regex to select min/max/avg latency from output
                    $Times = (($PingResults | Select-String $LatencyRegEx).ToString() -split ",").Trim()
                    $MinTime = ($Times[0] -split "=")[1].Trim() -replace "ms",""
                    $MaxTime = ($Times[1] -split "=")[1].Trim() -replace "ms",""
                    $AvgTime = ($Times[2] -split "=")[1].Trim() -replace "ms",""
                }

                If (!$ForceIPv6) {$NoFragVar = $NoFrag}

                # Create/return custom object
                [pscustomobject]@{
                    Result = $Result
                    Sent = $SentCount
                    Received = $ReturnedCount
                    Percent = $PercentValue
                    Size = $SizeVar
                    NoFrag = $NoFragVar
                    Source = $SourceStr
                    Destination = $DestStr
                    MinTime = $MinTime
                    MaxTime = $MaxTime
                    AvgTime = $AvgTime
                    Text = $PingResults
                }
            }
        }
        # Return output directly to console
        ElseIf (![string]::IsNullOrEmpty($Source)) {Get-ProcessOutput -Command $MainCommand -ArgList $ProcArgs -NoWindow}
    }
}
