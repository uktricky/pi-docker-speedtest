#!/bin/sh
# These values can be overwritten with env variables
LOOP="${LOOP:-false}"
LOOP_DELAY="${LOOP_DELAY:-60}"
DB_SAVE="${DB_SAVE:-false}"
DB_HOST="${DB_HOST:-http://localhost:8086}"
DB_NAME="${DB_NAME:-speedtest}"
DB_USERNAME="${DB_USERNAME:-admin}"
DB_PASSWORD="${DB_PASSWORD:-password}"

run_speedtest()
{
    DATE=$(date +%s)
    HOSTNAME=$(hostname)

    echo "Running a Speed Test..."

    JSON=$(speedtest --accept-license --accept-gdpr -f json)

    DOWNLOAD="$(echo $JSON | jq -r '.download.bandwidth')"
    UPLOAD="$(echo $JSON | jq -r '.upload.bandwidth')"
    JITTER="$(echo $JSON | jq -r '.ping.jitter')"
    LATENCY="$(echo $JSON | jq -r '.ping.latency')"

    ISP="$(echo $JSON | jq -r '.isp')"

    SVRID="$(echo $JSON | jq -r '.server.id')"
    SVRNAME="$(echo $JSON | jq -r '.server.name')"
    SVRLOCATION="$(echo $JSON | jq -r '.server.location')"
    SVRHOST="$(echo $JSON | jq -r '.server.host')"
    SVRIP="$(echo $JSON | jq -r '.server.ip')"

    echo "Your download speed is $(($DOWNLOAD  / 125000 )) Mbps ($DOWNLOAD Bytes/s)."
    echo "Your upload speed is $(($UPLOAD  / 125000 )) Mbps ($UPLOAD Bytes/s)."

   # Save results in the database
    if $DB_SAVE;
    then
        echo "Saving values to database..."

	curl -s -S -XPOST "$DB_HOST/write?db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" \
	--data-binary "results,host=$HOSTNAME,SVRLOC=$SVRLOCATION,SVRIP=$SVRIP UPLOAD=$UPLOAD,DOWNLOAD=$DOWNLOAD,JITTER=$JITTER,LATENCY=$LATENCY $DATE"

    fi

}

if $LOOP;
then
    while :
    do
        run_speedtest
        echo "Running nest test in ${LOOP_DELAY}s..."
        echo ""
        sleep $LOOP_DELAY
    done
else
    run_speedtest
fi



