# Ping-BySourceIP

SYNOPSIS
--------
Pings a destination using a source IP address

DESCRIPTION
-----------
Sends ICMP echo requests to a destination using the built-in ping.exe utility.
Specify a source IP address and optionally the destination host, byte size or count.
The -Quiet and -Detailed switch parameters can be used to search the text with regular
expressions to return either a boolean value or a results object.

SYNTAX
------
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [<CommonParameters>]
  
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-Detailed] [<CommonParameters>]
  
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-Quiet] [<CommonParameters>]

PARAMETERS
----------
-Source <String>

An IPv4 address of a local network adapter. This parameter is required.

-Destination <String>

An IPv4 address or hostname to send packets to. Default is "internetbeacon.msedge.net".

-Count <Int32>

Number of packets to send, in the range 1 - 4294967295. Default is 2.

-Size <Int32>

Byte size of packets to send, in the range 0 - 65500. Default is 32.

-Quiet <SwitchParameter>
  
Return a boolean value - True if any pings succeed, else False.
This parameter is mutually exclusive with the -Detailed parameter.

-Detailed <SwitchParameter>

Return an object of the result, counts, latency and text.
This parameter is mutually exclusive with the -Quiet parameter.

INPUTS
------
System.String

You can pipe a string that represents a source IP address to this function.

OUTPUTS
-------
System.String, System.Boolean, System.Management.Automation.PSCustomObject

Without any switch parameters this function generates 1 or more strings from ping.exe.
You can specify Quiet to generate a boolean or Detailed to generate a PSCustomObject.

NOTES
-----
Release Date: 2018-03-25
Author: Francis Hagyard

EXAMPLES
--------
Ping-BySourceIP -Source 192.168.0.13

Pinging ds-c-0003.c-msedge.net [13.107.4.52] from 192.168.0.13 with 32 bytes of data:

Reply from 13.107.4.52: bytes=32 time=13ms TTL=120

Reply from 13.107.4.52: bytes=32 time=14ms TTL=120

Ping statistics for 13.107.4.52:

  Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
  
Approximate round trip times in milli-seconds:

  Minimum = 13ms, Maximum = 14ms, Average = 13ms

Ping using a specific source IP address and print to console.

-------------------------------------------------------------
"192.168.0.13" | Ping-BySourceIP -Quiet

True

In this example, the source IP address is piped to the function and the -Quiet parameter
is used to return a boolean value.

-------------------------------------------------------------
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
Text        : {, Pinging www.google.com [216.58.206.68] from 192.168.0.13 with 64 bytes of data:, Reply from 209.85.202.99:                 bytes=64 time=22ms TTL=47, Reply from 209.85.202.99: bytes=64 time=21ms TTL=47...}

In this example, a specific destination is included along with a non-default count and byte size.
The -Detailed parameter is used to return an object containing the result, counts, latency and text.

-------------------------------------------------------------
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
