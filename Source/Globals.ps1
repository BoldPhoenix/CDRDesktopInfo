#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory

$appversion = "2.0.0.0"
$About_Date = "10/08/20"
$ScriptDirectory = (Get-Item -Path ".\" -Verbose).FullName
$Programs64 = "$Env:ProgramFiles"
$Programs86 = "$Env:ProgramFiles(x86)"
$ThisServer = $env:COMPUTERNAME

$LocalDesktopInfoPath = 'c:\Scripts\CDRDesktopInfo.exe'

function DesktopInfo
{
	# Configuration:
	
	# Font Family name
	$font = "Verdana"
	# Font size in pixels
	$size = 10.0
	# spacing in pixels
	$textPaddingLeft = 10
	$textPaddingTop = 10
	$textItemSpace = 4
	#$lineHeight = 1.80
	
	$wallpaperImageOutput = "$Env:USERPROFILE"
	
	# Get local info to write out to wallpaper
	$HostName = $Env:ComputerName
	$AuthenticatedUsers = "Authenticated Users"
	$os = Get-CimInstance Win32_OperatingSystem
	$DiskInfo = Get-CimInstance Win32_LogicalDisk | where FreeSpace -gt 1
	$cpu = (get-WmiObject Win32_Processor).Name | get-unique
	$cpulogical = (get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
	$BootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
	$BootTimeConverted = ($boottime.toString("M/d/yyyy h:mm tt"))
	$BootTimeSpan = (New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date))
	$logondata = query user
	$LoginTime = ($LogonData.Split()[-3, -2, -1]) -join (" ")
	$ipinfo = (get-WmiObject Win32_NetworkAdapterConfiguration | Where { $_.DefaultIPGateway -gt 1 }).IPAddress
	$subnetmask = (get-WmiObject Win32_NetworkAdapterConfiguration | Where { $_.DefaultIPGateway -gt 1 }).IPSubnet | get-unique
	$gateway = (get-WmiObject Win32_NetworkAdapterConfiguration | Where { $_.DefaultIPGateway -gt 1 }).DefaultIPGateway
	$dnsservers = (get-WmiObject Win32_NetworkAdapterConfiguration | Where { $_.DefaultIPGateway -gt 1 }).DNSServerSearchOrder
	$ServerName = (get-WmiObject Win32_ComputerSystem | Where { $_.Name -gt 1 }).Name
	$MachineDomain = (get-wmiobject -class win32_computersystem).domain
	$ADDomain = $env:userdomain
	$LogonServer = $env:logonserver -replace "\\", ""
	
	$DiskArray = @()
	foreach ($Disk in $DiskInfo)
	{
		$DiskName = $Disk.Name
		$DiskFree = "$([Int]($Disk.FreeSpace / 1GB))GB"
		$DiskFS = $Disk.FileSystem
		$DiskSpace = "$DiskName $DiskFree $DiskFS"
		$DiskArray += "$DiskSpace `n"
	}
	
	$NetworkArray = @()
	foreach ($IP in $IPInfo)
	{
		$IPAddress = $IP.IPAddress
		$IPMask = $IP.IPSubnet
		$IPGateway = $IP.DefaultGateway
		$NetworkArray += "$IPAddress `n"
	}
	

	# Populate Info for Displaying on Desktop
	
	$ComputerInfo = ([ordered]@{
			"HostName:"		      = $HostName

			"Uptime:"			  = "$($BootTimeSpan.Days) days, $($BootTimeSpan.Hours) hours  `n"
			"Domain/Workgroup:"	  = $MachineDomain
			"OS Version:"		  = $($os.Caption)
			"Architecture:"	      = $($os.OSArchitecture)
			"Boot Time:"		  = $BootTimeConverted
			"Login Time:"		  = "$LoginTime   `n"
			"IP Address:"		  = $IPInfo
			"Subnet Mask:"	      = $subnetmask
			"Default Gateway:"    = $gateway
			"DNS Servers:"	      = "$dnsservers `n"
			"User Name:"		  = $env:UserName
			"Logon Domain:"	      = $ADDomain
			"Logon Server:"	      = "$LogonServer `n"
			"CPU:"			      = "$cpulogical x $cpu"
			"Memory:"			  = "$([math]::round($os.TotalVisibleMemorySize / 1MB))GB    `n"
			
			"Free Space:"		  = $DiskArray
		})
	
	
	
	# original src: https://p0w3rsh3ll.wordpress.com/2014/08/29/poc-tatoo-the-background-of-your-virtual-machines/
	Function New-ImageInfo
	{
		param (
			[Parameter(Mandatory = $True, Position = 1)]
			[object]$data,
			[Parameter(Mandatory = $True)]
			[string]$in = "",
			[string]$font = "Verdana",
			[float]$size = 8.0,
			#[float] $lineHeight = 1.4,
			[float]$textPaddingLeft = 0,
			[float]$textPaddingTop = 0,
			[float]$textItemSpace = 0,
			[string]$out = "out.png"
		)
		
		
		[system.reflection.assembly]::loadWithPartialName('system') | out-null
		[system.reflection.assembly]::loadWithPartialName('system.drawing') | out-null
		[system.reflection.assembly]::loadWithPartialName('system.drawing.imaging') | out-null
		[system.reflection.assembly]::loadWithPartialName('system.windows.forms') | out-null
		
		$foreBrush = [System.Drawing.Brushes]::White
		$foreBrush2 = [System.Drawing.Brushes]::Yellow
		$backBrush = new-object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
		
		# Create font
#		$nFont = new-object system.drawing.font($font, $size, [System.Drawing.GraphicsUnit]::Pixel)
		$nFont = new-object System.Drawing.Font($font, $size, "Bold", "Pixel")
		
		# Create Bitmap
		$SR = [System.Windows.Forms.Screen]::AllScreens | Where Primary | Select -ExpandProperty Bounds | Select Width, Height
		
		echo $SR >> "$wallpaperImageOutput\wallpaper.log"
		
		$background = new-object system.drawing.bitmap($SR.Width, $SR.Height)
		#   $bmp = new-object system.drawing.bitmap -ArgumentList $in
		
		# Create Graphics
		$image = [System.Drawing.Graphics]::FromImage($background)
		
		# Paint image's background
		$rect = new-object system.drawing.rectanglef(0, 0, $SR.width, $SR.height)
		$image.FillRectangle($backBrush, $rect)
		
		# add in image
		$topLeft = new-object System.Drawing.RectangleF(0, 0, $SR.Width, $SR.Height)
		#  $image.DrawImage($bmp, $topLeft)
		
		# Draw string
		$strFrmt = new-object system.drawing.stringformat
		$strFrmt.Alignment = [system.drawing.StringAlignment]::Near
		$strFrmt.LineAlignment = [system.drawing.StringAlignment]::Near
		
		$taskbar = [System.Windows.Forms.Screen]::AllScreens
		$taskbarOffset = $taskbar.Bounds.Height - $taskbar.WorkingArea.Height
		
		# first get max key & val widths
		$maxKeyWidth = 0
		$maxValWidth = 0
		$textBgHeight = 0 + $taskbarOffset
		$textBgWidth = 0
		
		# a reversed ordered collection is used since it starts from the bottom
		$reversed = [ordered]@{ }
		
		foreach ($h in $data.GetEnumerator())
		{
			$valString = "$($h.Value)"
			$valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
			$valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)
			$maxValWidth = [math]::Max($maxValWidth, $valSize.Width)
			
			$keyString = "$($h.Name):"
			$keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
			$keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)
			$maxKeyWidth = [math]::Max($maxKeyWidth, $keySize.Width)
			
			$maxItemHeight = [math]::Max($valSize.Height, $keySize.Height)
			$textBgHeight += ($maxItemHeight + $textItemSpace)
			
			$reversed.Insert(0, $h.Name, $h.Value)
		}
		
		$textBgWidth = $maxKeyWidth + $maxValWidth
		$textBgX = $SR.Width - ($textBgWidth + $textPaddingLeft)
		$textBgY = $SR.Height - ($textBgHeight + $textPaddingTop)
		
		$textBgRect = New-Object System.Drawing.RectangleF($textBgX, $textBgY, $textBgWidth, $textBgHeight)
		$image.FillRectangle($backBrush, $textBgRect)
		
		echo $textBgRect >> "$wallpaperImageOutput\wallpaper.log"
		
		$i = 0
		$cumulativeHeight = $SR.Height - $taskbarOffset
		
		foreach ($h in $reversed.GetEnumerator())
		{
			$valString = "$($h.Value)"
			$valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
			$valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)
			
			$keyString = "$($h.Name)"
			$keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
			$keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)
			
			
			echo $valString >> "$wallpaperImageOutput\wallpaper.log"
			echo $keyString >> "$wallpaperImageOutput\wallpaper.log"
			
			$maxItemHeight = [math]::Max($valSize.Height, $keySize.Height) + $textItemSpace
			
			$valX = $SR.Width - $maxValWidth
			$valY = $cumulativeHeight - $maxItemHeight
			
			$keyX = $valX - $maxKeyWidth
			$keyY = $valY
			
			$valRect = New-Object System.Drawing.RectangleF($valX, $valY, $maxValWidth, $valSize.Height)
			$keyRect = New-Object System.Drawing.RectangleF($keyX, $keyY, $maxKeyWidth, $keySize.Height)
			
			$cumulativeHeight = $valRect.Top
			
			$image.DrawString($keyString, $keyFont, $foreBrush, $keyRect, $strFrmt)
			$image.DrawString($valString, $valFont, $foreBrush2, $valRect, $strFrmt)
			
			$i++
		}
		
		# Close Graphics
		$image.Dispose();
		
		# Save and close Bitmap
		$background.Save($out, [system.drawing.imaging.imageformat]::Png);
		$background.Dispose();
		#  $bmp.Dispose();
		
		# Output file
		Get-Item -Path $out
	}
	
	function Set-Wallpaper
	{
		param (
			[Parameter(Mandatory = $true)]
			$Path,
			[ValidateSet('Center', 'Stretch')]
			$Style = 'Stretch'
		)
		
		Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
public enum Style : int
{
Center, Stretch
}
public class Setter {
public const int SetDesktopWallpaper = 20;
public const int UpdateIniFile = 0x01;
public const int SendWinIniChange = 0x02;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper ( string path, Wallpaper.Style style ) {
SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
switch( style )
{
case Style.Stretch :
key.SetValue(@"WallpaperStyle", "2") ; 
key.SetValue(@"TileWallpaper", "0") ;
break;
case Style.Center :
key.SetValue(@"WallpaperStyle", "1") ; 
key.SetValue(@"TileWallpaper", "0") ; 
break;
}
key.Close();
}
}
}
"@
		
		[Wallpaper.Setter]::SetWallpaper($Path, $Style)
	}
	
	$wpath = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction Stop).WallPaper
	if (Test-Path -Path $wpath -PathType Leaf)
	{
		$bmp = new-object system.drawing.bitmap -ArgumentList $wpath
		$currentwallpaper = [System.Drawing.Graphics]::FromImage($bmp)
	}
	
	# execute tasks
	echo $ComputerInfo > "$wallpaperImageOutput\wallpaper.log"
	
	# create wallpaper image and save it in user profile
	$WallPaper = New-ImageInfo -data $ComputerInfo -in "$currentwallpaper" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace #-lineHeight $lineHeight
	echo $WallPaper.FullName >> "$wallpaperImageOutput\wallpaper.log"
	
	# update wallpaper for logged in user
	Set-Wallpaper -Path $WallPaper.FullName
	
	# Restore the default VM wallpaper
#	Set-Wallpaper -Path "C:\Windows\Web\Wallpaper\Windows\img0.jpg" -Style Fill
}
