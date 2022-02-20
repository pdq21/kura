
<#
Nov. 2020

record, topic, partition, offset, producer/consumer,  

zk
listener: 2181 (clientPort), data: /tmp/data (dataDir)
kafka 
listener: 9092 (listeners=PLAINTEXT://:9092)
zookeeper.connect, zookeeper.connection.timeout.ms
socket.send.buffer.bytes, socket.receive.buffer.bytes, socket.request.max.bytes
flush buffered segment file to disk: log.flush.interval.messages, log.flush.interval.ms
segment file: log.retention.hours, log.retention.bytes, log.segment.bytes, log.retention.check.interval.ms

Src
https://www.apache.org/dyn/closer.cgi/zookeeper/
https://kafka.apache.org/downloads

Linux
./bin/zkServer.sh start
./bin/kafka-server-start.sh
./bin/kafka-server-stop.sh
./bin/zkServer.sh stop
#>
function Start-Setup {
    ${global:cfg} = "${PWD}\..\conf\kafka"
    ${global:kafkaCfgPath} = "${cfg}"
    ${global:zkCfg} = "${cfg}\zoo.cfg"
    ${global:shims} = "${env:UserProfile}\scoop\shims"
    ${global:kafkaPorts} = @{}
    ${global:kafkaInstances} = [int]1
    ${global:zkPort} = ((Get-Content $zkCfg) -match "clientPort" -split "=" -split ",")[1]
}
function Get-KafkaCmds {
    (Get-ChildItem -Path ${global:shims} -Name "kafka*.cmd" -Force) -replace ".cmd", ""
}
function Get-Topics {
    $p = "--list --zookeeper localhost:${global:zkPort}"
    Start-Process "kafka-topics.cmd" -ArgumentList $p -NoNewWindow 
}
function Get-TopicDesc {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$topic
    )
    $p = "--list --zookeeper localhost:${global:zkPort}"
    Start-Process "kafka-topics.cmd" -ArgumentList $p -NoNewWindow 
}
function Get-zkCmds {
    (Get-ChildItem -Path ${global:shims} -Name "zookeeper*.cmd" -Force) -replace ".cmd", ""
}
function Set-Consumer {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$topic
    )
    $p = "--bootstrap-server localhost:${global:zkPort}"
    $p += " --topic ${topic} --from-beginning"
    Start-Process "kafka-console-consumer.cmd" -ArgumentList $p -NoNewWindow
}
function Set-Topic {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$topic
    )
    $p = "--create --zookeeper localhost:${global:zkPort} --topic ${topic}"
    $p += " --replication-factor ${global:kafkaInstances} --partitions 100"
    Start-Process "kafka-topics.cmd" -ArgumentList $p -NoNewWindow
}
function Start-Kafka {
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(1,2,3)]
        [int]$instances = ${global:kafkaInstances}
    )
    ${global:kafkaInstances} = $instances
    $zk = "nt cmd /k `"zookeeper-server-start ${global:zkCfg}`";"
    for ($i = 0; $i -lt $instances; $i++) {
        $p = "${global:kafkaCfgPath}\server-${i}.properties"
        $k += " sp cmd /k `"timeout /t 10 && kafka-server-start ${p}`";"
        $port = (((Get-Content $p) -match "listeners" -notmatch "#" -split "=" `
            -split ",")[1] -split ":")[-1]
        ${global:kafkaPorts}.add($i, $port)
    }
    Start-Process "wt.exe" -ArgumentList "-M ${zk}${k} ft"
}
function Start-zkShell {
    zookeeper-shell localhost:${global:zkPort} #ls /brokers/topics
}
function Stop-Kafka {
    Start-Setup
    Write-Host "stopping Kafka..."
    kafka-server-stop
    Write-Host "stopping Zookeeper..."
    zookeeper-server-stop
}
Start-Setup