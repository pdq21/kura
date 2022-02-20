@echo off
setlocal
rem 11.2020
rem start influxdb, grafana, influx & eclipse with kura
rem assumes scoop in path env

rem influxDB
rem http://localhost:8086/metrics
rem https://docs.influxdata.com/influxdb/v1.8/query_language/explore-data/
rem https://influxdbcom.readthedocs.io/en/latest/content/docs/v0.9/query_language/query_syntax/
rem 
rem grafana
rem https://grafana.com/docs/grafana/latest/installation/windows/
rem https://grafana.com/docs/grafana/latest/administration/configuration/
rem localhost:3000, localhost:3000/metrics
rem profiling: localhost:6060
rem conf\sample.ini -> custom.ini, not default.ini
rem
rem prometheus
rem http://localhost:9090/graph, /metrics

set wd=%~dp0
set root=%wd%..
set conf=%root%\cfg
set scoop=%UserProfile%\scoop\apps
set influx_cfg=%conf%\influxdb\influxdb.conf
set influx_err===^> error while contacting influxd.
set grafana_cfg=%conf%\grafana\custom.ini
set grafana_home=%scoop%\grafana\current
set eclipse=C:\TMP\eclipse-jee-2020-03-R-incubation-win32-x86_64\eclipse\eclipse.exe
set mqtt=%LocalAppData%\Programs\MQTT-Explorer\MQTT Explorer.exe
set sm=start /min
set webkura=http://localhost:8080/kura
set webgf=http://localhost:3000/dashboards
set webif=http://localhost:8086/metrics
set mq=cmd /k "%mqtt%"
set ifd=cmd /k "influxd -config "%influx_cfg%""
set if=cmd /k "timeout /t 5 & influx -execute "show databases" && influx || echo %influx_err%"
set gf=cmd /k "grafana-server -config "%grafana_cfg%" -homepath "%grafana_home%""

(
    echo %path% | find /i "powershell\7" && set mw=pwsh -wd %root% -NoLogo || (
        echo %path% | find /i "powershell\v1.0" && (
            set mw=powershell -Command {Set-Location %root%} -NoLogo -NoExit || (
                set mw=cmd /k "cd %root%"
            )   
        )
    )
) >nul
rem sp %mq%;
set wtargs=-M nt %mw%; sp %if%; sp %ifd%; sp %gf%; ft

%sm% %eclipse%
if exist "%scoop%\windows-terminal" (
    wt %wtargs% || windowsterminal %wtargs%
) else (
    %sm% %ifd%
    %sm% %gf%
rem    %sm% %mq%
    %sm% %if%
)
%sm% msedge %webkura% -inprivate
%sm% msedge %webgf% -inprivate
%sm% msedge %webif% -inprivate

endlocal
exit /b