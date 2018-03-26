Function Ping-BySourceIP {
<#
.SYNOPSIS
    Pings a destination using a source IP address
.DESCRIPTION
    Sends ICMP echo requests to a destination using the built-in ping.exe utility.
    Specify a source IP address and optionally the destination host, byte size or count.
    The -Quiet and -Detailed switch parameters can be used to search the text with regular
    expressions to return either a boolean value or a results object.
.PARAMETER Source
    An IPv4 address of a local network adapter. This parameter is required.
.PARAMETER Destination
    An IPv4 address or hostname to send packets to. Default is "internetbeacon.msedge.net".
.PARAMETER Count
    Number of packets to send, in the range 1 - 4294967295. Default is 2.
.PARAMETER Size
    Byte size of packets to send, in the range 0 - 65500. Default is 32.
.PARAMETER Quiet
    Return a boolean value - True if any pings succeed, else False.
    This parameter is mutually exclusive with the -Detailed parameter.
.PARAMETER Detailed
    Return an object of the result, counts, latency and text.
    This parameter is mutually exclusive with the -Quiet parameter.
.INPUTS
    System.String

    You can pipe a string that represents a source IP address to this function.
.OUTPUTS
    System.String, System.Boolean, System.Management.Automation.PSCustomObject

    Without any switch parameters this function generates 1 or more strings from ping.exe.
    You can specify Quiet to generate a boolean or Detailed to generate a PSCustomObject.
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

    Ping using a specific source IP address and print to console.
.EXAMPLE
    "192.168.0.13" | Ping-BySourceIP -Quiet

    True

    In this example, the source IP address is piped to the function and the -Quiet parameter
    is used to return a boolean value.
.EXAMPLE
    Ping-BySourceIP -Source 192.168.0.13 -Destination www.google.com -Count 4 -Size 64 -Detailed

    Result      : True
    Sent        : 4
    Received    : 4
    Percent     : 100
    Size        : 64
    Source      : 192.168.0.13
    Destination : www.google.com [216.58.206.68]
    MinTime     : 21
    MaxTime     : 38
    AvgTime     : 26
    Text        : {, Pinging www.google.com [216.58.206.68] from 192.168.0.13 with 64 bytes of data:, Reply from 209.85.202.99: bytes=64 time=22ms TTL=47, Reply from 209.85.202.99: bytes=64 time=21ms TTL=47...}

    In this example, a specific destination is included along with a non-default count and byte size.
    The -Detailed parameter is used to return an object containing the result, counts, latency and text.
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
  
    In the second step, the function tests whether the IP address can ping the default host using the -Quiet parameter
    to return a boolean value, and stores the result in the $Connected variable.

    In the third step, the scriptblock is only executed if $Connected equals False (i.e. no pings successfully responded). In the 
    scriptblock the Get-WmiObject cmdlet is piped to Where-Object to determine which local adapter has the IP address and a WMI 
    object representing the adapter is stored in the $Adapter variable. The .ReleaseDHCPLease() method is called to release the
    DHCP lease on the adapter and the results assigned to the $Null automatic variable to prevent output being generated. The script
    then pauses for 5 seconds before calling the .RenewDHCPLease() method in an attempt to renew the DHCP lease on the adapter.
.LINK
    Online: https://github.com/BoonMeister/Ping-BySourceIP
#>
    [CmdletBinding(DefaultParameterSetName="RegularPing")]
    Param(
        [Parameter(ParameterSetName="RegularPing",Mandatory=$True,ValueFromPipeline=$True)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$True,ValueFromPipeline=$True)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Source,
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [String]$Destination = "internetbeacon.msedge.net",
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [ValidateRange(1,4294967295)]
        [Int]$Count = 2,
        [Parameter(ParameterSetName="RegularPing",Mandatory=$False)]
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False)]
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [ValidateRange(0,65500)]
        [Int]$Size = 32,
        [Parameter(ParameterSetName="QuietPing",Mandatory=$False)]
        [Switch]$Quiet = $False,
        [Parameter(ParameterSetName="DetailedPing",Mandatory=$False)]
        [Switch]$Detailed = $False
    )
    $MainCommand = "ping -n $Count -l $Size -S $Source -4 $Destination"
    If ($Quiet -or $Detailed) {
        $FirstLineRegEx = "bytes of data:"
        $LatencyRegEx = "Average = "
        $PingResults = Invoke-Expression -Command $MainCommand
        $ReturnedCount = 0
        If ($PingResults.Count -gt 1) {
            $ResultTable = @()
            $FailureStrings = @(
                "Request timed out"
                "Destination host unreachable"
                "General failure"
                "transmit failed"
            )
            $PacketResults = (($PingResults | Select-String $FirstLineRegEx -Context (0,$Count)) -split "\r\n")[1..$Count]
            Foreach ($Line in $PacketResults) {
                $Line = $Line.ToString()
                If (($Line -match "Reply from") -and (($Line -match "time=") -or ($Line -match "time<"))) {$PacketTest = $True}
                Else {
                    $PacketTest = $True
                    Foreach ($String in $FailureStrings) {
                        If ($Line -match $String) {
                            $PacketTest = $False
                            Break
                        }
                    }
                }
                If ($PacketTest) {$ReturnedCount += 1}
                $ResultTable += $PacketTest
            }
            $SentCount = $Count
            $PercentValue = [Int]($ReturnedCount/$Count*100)
            If ($ResultTable -contains $True) {$Result = $True}
            Else {$Result = $False}
        }
        Else {
            $Result = $False
            $SentCount = 0
            $PercentValue = 0
            Remove-Variable -Name Size
        }
        If ($Quiet) {
            Return $Result
        }
        Elseif ($Detailed) {
            If ($PingResults | Select-String $FirstLineRegEx -Quiet) {
                $FirstLine = ($PingResults | Select-String $FirstLineRegEx).ToString() -split " from "
                $SourceStr = ($FirstLine[1] -split " ")[0]
                $DestStr = $FirstLine[0] -replace "Pinging ",""
            }
            Else {
                $SourceStr = $Source
                $DestStr = $Destination
            }
            If ($Result -and ($PingResults | Select-String $LatencyRegEx -Quiet)) {
                $Times = (($PingResults | Select-String $LatencyRegEx).ToString() -split ",").Trim()
                $MinTime = ($Times[0] -split "=")[1].Trim() -replace "ms",""
                $MaxTime = ($Times[1] -split "=")[1].Trim() -replace "ms",""
                $AvgTime = ($Times[2] -split "=")[1].Trim() -replace "ms",""
            }
            $ResultObj = New-Object PsObject
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Result" -Value $Result
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Sent" -Value $SentCount
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Received" -Value $ReturnedCount
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Percent" -Value $PercentValue
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Size" -Value $Size
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Source" -Value $SourceStr
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Destination" -Value $DestStr
            $ResultObj | Add-Member -MemberType NoteProperty -Name "MinTime" -Value $MinTime
            $ResultObj | Add-Member -MemberType NoteProperty -Name "MaxTime" -Value $MaxTime
            $ResultObj | Add-Member -MemberType NoteProperty -Name "AvgTime" -Value $AvgTime
            $ResultObj | Add-Member -MemberType NoteProperty -Name "Text" -Value $PingResults
            Return $ResultObj
        }
    }
    Else {Invoke-Expression -Command $MainCommand}
}