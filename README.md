# Ping-BySourceIP

SYNOPSIS
--------
Pings a destination using a source IP address

DESCRIPTION
-----------
Sends ICMP echo requests from a specific local network adapter using the built-in 
ping.exe utility. Specify a source IP address and optionally the destination host, 
byte size or count. The -Quiet and -Detailed parameters can be used to parse the 
text with regular expressions to return either a boolean value or a results object.

SYNTAX
------
    Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-NoFrag] [-ResolveIP] 
    Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-NoFrag] [-ResolveIP] [-Detailed]
    Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-NoFrag] [-Quiet]

PARAMETERS
----------
-Source (String)

An IPv4 address of a local network adapter. This parameter is required.

-Destination (String)

An IPv4 address or hostname to send packets to. Default is "internetbeacon.msedge.net".

-Count (Int32)

Number of packets to send, in the range 1 - 4294967295. Default is 2.

-Size (Int32)

Byte size of packets to send, in the range 0 - 65500. Default is 32.

-NoFrag (SwitchParameter)

Specifies that packets should not be fragmented whilst en route. When using -Quiet 
or -Detailed a packet that requires fragmentation will be evaluated as a failed response.
    
-ResolveIP (SwitchParameter)

When specified with an IP address for the destination parameter attempts to 
perform a reverse DNS lookup in order to retrieve the destination hostname.

-Quiet (SwitchParameter)
  
Return a boolean value - True if any pings succeed, else False.

-Detailed (SwitchParameter)

Return an object of the result, counts, latency and text.

INPUTS
------
System.String

You can pipe a string that represents a source IP address to this function.

OUTPUTS
-------
System.String, System.Boolean, System.Management.Automation.PSCustomObject

Without any switch parameters this function generates 1 or more strings from ping.exe.
You can specify Quiet to generate a boolean or Detailed to generate a PSCustomObject.

EXAMPLES
--------

- Return normal output:

      Ping-BySourceIP -Source 192.168.0.13
      
      Pinging ds-c-0003.c-msedge.net [13.107.4.52] from 192.168.0.13 with 32 bytes of data:
      Reply from 13.107.4.52: bytes=32 time=13ms TTL=120
      Reply from 13.107.4.52: bytes=32 time=14ms TTL=120

      Ping statistics for 13.107.4.52:
        Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
      Approximate round trip times in milli-seconds:
        Minimum = 13ms, Maximum = 14ms, Average = 13ms

- Pipe source and return boolean:

      "192.168.0.13" | Ping-BySourceIP -Quiet
      
      True

- Specify destination, count, size, no fragmentation, perform reverse lookup and return an object:

      Ping-BySourceIP -Source 192.168.0.13 -Destination 216.58.206.68 -Count 4 -Size 128 -NoFrag -ResolveIP -Detailed
      
      Result      : True
      Sent        : 4
      Received    : 4
      Percent     : 100
      Size        : 128
      NoFrag      : True
      Source      : 192.168.0.13
      Destination : lhr35s11-in-f4.1e100.net [216.58.206.68]
      MinTime     : 17
      MaxTime     : 73
      AvgTime     : 41
      Text        : {, Pinging lhr35s11-in-f4.1e100.net [216.58.206.68] from 192.168.0.13 with 128 bytes of data:, Reply from 216.58.206.68: bytes=64 (sent 128) time=17ms TTL=54, Reply from 216.58.206.68: bytes=64 (sent 128) time=73ms TTL=54...}

- Renew DHCP lease of a local network adapter if not connected:

      $IPAddress = "192.168.0.13"
      $Connected = Ping-BySourceIP -Source $IPAddress -Quiet
      If (!$Connected) {
          $Adapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where {$_.IPAddress -contains $IPAddress}
          $Null = $Adapter.ReleaseDHCPLease()
          Start-Sleep -Seconds 5
          $Null = $Adapter.RenewDHCPLease()
      }
      
- Ping multiple destinations and export csv of the details:

      $LocalIP = "192.168.0.13"
      $DestList = @(
          "192.168.0.1"
          "8.8.8.8"
          "internetbeacon.msedge.net"
      )
      $Results = @()
      Foreach ($Dest in $DestList) {
          $Details = Ping-BySourceIP -Source $LocalIP -Destination $Dest -Count 10 -ResolveIP -Detailed
          $Results += $Details | Select-Object -Property * -ExcludeProperty Text
      }
      $Results | Export-Csv -Path D:\Results.csv -Force -NoTypeInformation

NOTES
-----
Release Date: 2018-03-25

Author: Francis Hagyard
