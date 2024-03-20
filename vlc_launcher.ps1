### This script is aimed to update and run VLC nightly, you can convert this to executable (with ps2exe) for a better usage.
### Place the script (or executable) in an empty folder for first time install, or in an already existing vlc nighlty directory and execute it.
### The script or executable name must match the following $LauncherName variable

$LauncherName = "vlc_launcher.exe"


#Check version
$Path = Get-Location
$Nightly = 'https://artifacts.videolan.org/vlc/nightly-win64/'
$AllBuilds = (Invoke-WebRequest -Uri $Nightly).Links
$LatestBuild = $AllBuilds[1].href

#Create text file for the build number
if (-not (Test-Path -Path $Path\nightlyBuild.txt -PathType Leaf)) {
	Set-Content -Path $Path\nightlyBuild.txt -Value ""
}

#Begin installation or update process if build is outdated or "nightlyBuild.txt" missing
if ((Get-Content -Path $Path\nightlyBuild.txt) -ne ($LatestBuild)) {

	#Checks for update or installation 
	$checkfold = Get-ChildItem -Path $Path
	$checkvlc = Get-ChildItem -Path $Path -Filter vlc.exe
	$checkproc = Get-Process vlc -ErrorAction SilentlyContinue
	if (($checkvlc.count -eq 0) -and ($checkfold.count -gt 1)){
		Remove-Item -Path $Path\nightlyBuild.txt
		Write-Output "The script may be placed in the wrong folder. If you are going to install VLC for the first time place this script in an empty folder. Press any key to exit... "
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		exit 
	}
	if ($checkproc.count -ne 0){
		Write-Output "VLC process is running, close it then run this script again. Press any key to exit... "
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		exit 
	}

	#Select latest build and corresponding sha512 code
	$LatestBuildUrl = $Nightly + $LatestBuild
	$ZipSelect = (Invoke-WebRequest -Uri $LatestBuildUrl).Links.href | where {$_ -match 'zip'} | where {$_ -notmatch 'debug'}
	$ZipLink = $LatestBuildUrl+$ZipSelect
	$SHALink = $LatestBuildUrl+'SHA512SUM'

	#Downloading and verification
	Invoke-WebRequest -uri $ZipLink -OutFile 'VLC_update.zip'
	Invoke-WebRequest -uri $SHALink -OutFile 'SHA512SUM'
	$SHALine = Get-Content SHA512SUM | where {$_ -match 'zip'} | Where {$_ -notmatch 'debug'}
	$SHAVal = $SHALine.substring(0,128)
	$GetHash = (Get-FileHash 'VLC_update.zip' -Algorithm SHA512).Hash
	if ($SHAVal -ne $GetHash){
		Remove-Item -Path $Path\VLC_update.zip
		Write-Output "Hash file verification failed, installation aborted, press any key to exit... "
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		exit 
	}
	else
	{
		Write-Output "Hash file verification successful"
	}

	#Installation: replace 
	Remove-Item -Recurse -Path $Path\* -Exclude VLCNightlyUpdate.ps1,$LauncherName,VLC_update.zip
	Expand-Archive -Path VLC_update.zip -DestinationPath $Path
	$ExtractedDir = Get-ChildItem vlc* -Directory
	$ExtractedPath = $Path.Path+'\'+$ExtractedDir.Name
	Move-Item -Path $ExtractedPath\* -Destination $Path -Force
	Remove-Item $ExtractedPath,VLC_update.zip
	Write-Output "Installation COMPLETED! Launching VLC... "
	
} elseif ((Get-Content -Path $Path\nightlyBuild.txt) -eq ($LatestBuild)) {
	Write-Output "Already latest VLC nighlty build. Launching VLC... "
}

#Launch VLC
Set-Content -Path $Path\nightlyBuild.txt -Value $LatestBuild
Start-Process -FilePath $Path\vlc.exe -NoNewWindow