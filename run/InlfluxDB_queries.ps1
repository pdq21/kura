#https://docs.influxdata.com/influxdb/v1.8/query_language/explore-schema/
#influx -execute 'command'
#SHOW DATABASES
#show  DIAGNOSTICS
#USE <dbname>
#show measurements #tables
#SELECT "value" FROM "TmpSensor_1/Chn-Tmp"
#select "value","usertime" from "TmpSensor_1/Chn-Tmp"
#SELECT mean(\"value\") FROM \"measurement\" WHERE time >= now() - 6h GROUP BY time(20s) fill(null)
