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
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>]
  
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-Detailed]
  
Ping-BySourceIP -Source <String> [-Destination <String>] [-Count <Int32>] [-Size <Int32>] [-Quiet]

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
