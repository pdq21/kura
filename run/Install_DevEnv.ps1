<#
.Synopsis
    Install DevEnv with Powershell 5+
.Description
    Install
    set CmdPSPath=.\Install_DevEnv.ps1
    set CmdSetEP=Set-ExecutionPolicy RemoteSigned -Scope Process
    powershell -Command "${env:CmdSetEP} | Out-Null; iex ${env:CmdPSPath}"

    scoop search #available apps in added buckets
    scoop list #installed apps
    scoop bucket <add|list|known>
    https://scoop.sh/
    https://github.com/lukesampson/scoop/wiki/Chocolatey-Comparison
    https://github.com/ScoopInstaller/Main/tree/master/bucket
    https://github.com/lukesampson/scoop-extras/tree/master/bucket
    https://github.com/matthewjberger/scoop-nerd-fonts

    WinGet MS PkgMgr
    Developer Mode enabled
    https://github.com/microsoft/winget-cli/releases

    Windows-Terminal
    https://github.com/Microsoft/Terminal

    oh-my-posh 
    https://github.com/JanDeDobbeleer/oh-my-posh
    https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh

    Cascadia Code 2009.22
    https://github.com/microsoft/cascadia-code

.Notes
    as-is Nov. 2020
    License: MIT
    
	TODO nuget/msstore [y] -force
#>
$scoop = @{
    #append / to signalize a bucket needs to be installed, e.g. nerd-fonts/
    Apps = @(
        "git"
	    "python" #or "winpython"
        "windows-terminal"
        "wsl-terminal"
        "extras/windows-terminal"
	    "extras/vscode"
        "extras/powertoys"
        "nerd-fonts/"
        #kura project
        #"eclipse-java"
        #"kafka"
        #"influxdb"
        #"extras/grafana"
        #"prometheus"
        #win installer
	    #"wixtoolset" #WiX/dark installer toolset
	    #"innounp" #Inno Setup Unpacker
    )
    Uri = [uri]"https://get.scoop.sh"
}
$winget = @{
    Apps = @(
        #"PowerToys"
        #"Windows Terminal"
        #"AdoptOpenJDK.OpenJDK" #AdoptOpenJDK 15.0.1+9 (x64)
        #"thomasnordquist.MQTT-Explorer"
    )
    Uri = [uri]"https://github.com/microsoft/winget-cli/releases/download/v0.2.2941-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
}
$posh = @{
    Modules = @(
        "posh-git"
        "oh-my-posh"
    )   
    Theme = "Paradox"
}
$font = @{
    FontDownload = "CascadiaCode"
    FontInstall = "CascadiaCodePL"
    #TODO resolve to latest .zip
    Uri = [uri] "https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip"
}

function scoopFun {
    $scoopPath = "${env:UserProfile}\scoop"
    try {
        if (!(Test-Path $scoopPath)) {
            Write-Host "Installing Scoop..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString($scoop.Uri) -EA Stop
        }
        $scoop.Apps | ForEach-Object {
            if ($_ -match "/") {
                scoop bucket add $(($_ -split "/")[0])
            }
            if ($_ -match "nerd-fonts") {
#                Invoke-Expression "${scoopPath}\buckets\nerd-fonts\bin\generate-manifests.ps1"
            }
            scoop install $_
<#
    	#sTODO
	if($isAdmin)
	#'scoop checkup' recommendation, exclude from Windows Defender MpEngine
	@('${env:UserProfile}\scoop', '${env:ProgramData}\scoop') | % { Add-MpPreference -ExclusionPath ${_} }
	    #enable long UNC-paths
    	Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
#>
        }
    } catch {
        Write-Host ${Error}[-1]
    }
}

$isadmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).`
            IsInRole("Administrators")

function wingetFun {
    if ($isadmin) {
        if (!(Get-AppxPackage "*Microsoft.DesktopAppInstaller*")) { #Microsoft.Winget.Source
            $devMode = @{
                Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
                Name = "AllowDevelopmentWithoutDevLicense"
                PropertyType = "DWORD"
                Value = 1
                Force = $true
            }
            if (!(Test-Path $devMode.Path)) {
                New-Item $devMode.Path -ItemType "Directory" -Force | Out-Null
            }
            Write-Host "Enabling Developer Mode..."
            New-ItemProperty @devMode | Out-Null

            $wingetIwr = @{
                Uri = $winget.Uri
                UseBasicParsing = $true
                UserAgent = "Chrome"
                OutFile = "${env:TEMP}\$($winget.Uri.Segments[-1])"
            }
            Invoke-WebRequest @wingetIwr

            Add-AppxPackage $wingetIwr.OutFile
        }
        
        $winget.Apps | ForEach-Object {
            winget install $_
        }
    }
    else {
        Write-Host "No Admin. Winget will not be installed." -f Red
    }
}

function replStr {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]$in,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$notMatch,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$append
    )
    $ret = $in -notmatch $notMatch
    return $ret += $append
}

#set ps prompt and theme in current PS and $PROFILE
#call replStr to avoid duplicates inside $PROFILE and to append Modules and Set
function poshFun {
    $psProfile = Get-Content $PROFILE
    if(!$psProfile) {
        $psProfile = "#$(Get-Date -f "u")"
    }
    #if on PS (Core) w/o PSReadLine
    if(!(Get-Module PSReadLine -ListAvailable)) {
        Install-Module -Name "PSReadLine" -Scope "CurrentUser" -Force `
            -SkipPublisherCheck -EA "SilentlyContinue"
    }
    try {
        $posh.Modules | ForEach-Object {
            #TODO get newest version from Get-Module?
            $gm = Get-Module $_
            if (!$gm -and !(Get-Module $_ -ListAvailable)) {
                Install-Module $_ -Scope "CurrentUser" -Force -EA "Stop"
            }
            $ex = "Import-Module ${_}"
            if (!$gm) {
                Invoke-Expression $ex -EA "SilentlyContinue" -Force
            }
            $psProfile = replStr $psProfile $ex "${ex} -Force"
        }
        $psProfile = replStr $psProfile "Set-PoshPrompt" "Set-PoshPrompt $($posh.Theme)"
        $psProfile | Out-File $PROFILE -Force
        Write-Host '$PROFILE modified. Appearence added.' -f Green
    } catch {
        Write-Host ${Error}[-1]
    }
<#TODO
obsolete since which ver? keep for backwards compat?
    @(
        #"Set-Theme"
        #"Set-Prompt"
    ) | ForEach-Object { $i=0 } {
        if ($i -eq 0) {
            $ex = "${_} $($posh.Theme)"
            $i = 1
        }
        else {
            $ex = $_
        }
        $psProfile = replStr $psProfile $_ $ex
    }
#>
}

function fontFun {
    if ($isadmin) {
        $fontsDir = "C:\Windows\Fonts"
    } else {
        $fontsDir = "${env:LocalAppData}\Microsoft\Windows\Fonts"
    }
    if (!(Test-Path "${fontsdir}\$($font.FontInstall)*")) {
        $tmpDest = "${env:TEMP}\$($font.Uri.Segments[-1])"
        $expandDir = ${tmpDest} -replace ".zip",""
        if(!(Test-Path ${expandDir}) -and !(Test-Path ${tmpDest})) {
            $iwr = @{
                Uri = $font.Uri
                OutFile = ${tmpDest}
                UserAgent = "Chrome"
                UseBasicParsing = $true
            }
            Invoke-WebRequest @iwr
            Expand-Archive ${tmpDest} ${expandDir}
            Remove-Item -Path ${tmpDest} -Force
            Write-Host "$($font.FontDownload) expanded to ${expandDir}." -f Yellow
        }
        if(!(Test-Path ${fontsDir})) {
            New-Item -Path ${fontsDir} -ItemType "Directory" -Force | Out-Null
        }
        Copy-Item "${expandDir}\ttf\$($font.FontInstall).ttf" ${fontsDir} -Force
        Write-Host "$($font.FontInstall) installed into ${fontsDir}."
    }
    else {
        Write-Host "$($font.FontInstall) already installed." -f Yellow
    }
}

#cleanup for inline exec
function cleanUp {
    #Remove-Variable
    [System.GC]::Collect()
}

if ($isadmin) {
    Write-Host "Admin Mode" -f Red
} else {
    Write-Host "User Mode" -f Yellow
}
scoopFun
wingetFun
poshFun
fontFun
cleanup