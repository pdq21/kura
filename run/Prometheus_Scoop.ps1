<#
Nov. 2020
prevent "Error parsing commandline arguments: flag 'config.file' cannot be repeated"
localhost:9090/metrics
localhost:9090/graph
#>
$git_root=".\.."
$prom_cfg = "prometheus.yml"
$scoop_dir = "${env:UserProfile}\scoop\apps\prometheus\current"
$scoop_mf = "${prom_dir}\manifest.json"
$prom_args = "--config.file=`"${git_root}\config\${prom_cfg}`""

if (Test-Path $scoop_mf) {
    $cfg = Get-Content $scoop_mf
#    Rename-Item $prom_mf_dir -NewName "${$prom_cfg}.bak" -Force
    $cfg -match $prom_cfg | ForEach-Object { $cfg -replace "${_}", "`"`"" }

    $cfg -match $prom_cfg | ForEach-Object { $cfg -replace [regex]::escape($_),"---" }

    $cfg -match $prom_cfg | ForEach-Object { $cfg.replace(${_},"---") }

#    New-Item $prom_dir -Name $prom_mf -Value $cfg -Force
}