#!/bin/bash

usage() {
  echo "Usage: $0 --webhookurl URL --hostname HOSTNAME --servicename SERVICENAME --hoststate HOSTSTATE --servicestate SERVICESTATE --notificationtype TYPE --longdatetime DATETIME --hostalias HOSTALIAS --hostaddress ADDRESS --servicedesc DESC --serviceoutput OUTPUT --serviceperfdata PERF --icingaurl ICINGAURL"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --webhookurl) WEBHOOK_URL="$2"; shift ;;
    --hostname) HOSTNAME="$2"; shift ;;
    --servicename) SERVICENAME="$2"; shift ;;
    --hoststate) HOSTSTATE="$2"; shift ;;
    --servicestate) SERVICESTATE="$2"; shift ;;
    --notificationtype) NOTIFICATIONTYPE="$2"; shift ;;
    --longdatetime) LONGDATETIME="$2"; shift ;;
    --hostalias) HOSTALIAS="$2"; shift ;;
    --hostaddress) HOSTADDRESS="$2"; shift ;;
    --servicedesc) SERVICEDESC="$2"; shift ;;
    --serviceoutput) SERVICEOUTPUT="$2"; shift ;;
    --serviceperfdata) SERVICEPERFDATA="$2"; shift ;;
    --icingaurl) ICINGAURL="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

if [ -z "$WEBHOOK_URL" ] || [ -z "$HOSTNAME" ] || [ -z "$SERVICENAME" ] || [ -z "$HOSTSTATE" ] || [ -z "$SERVICESTATE" ] || [ -z "$NOTIFICATIONTYPE" ] || [ -z "$LONGDATETIME" ] || [ -z "$HOSTALIAS" ] || [ -z "$HOSTADDRESS" ] || [ -z "$SERVICEDESC" ] || [ -z "$SERVICEOUTPUT" ] || [ -z "$ICINGAURL" ]; then
  usage
fi

if [ "$NOTIFICATIONTYPE" == "PROBLEM" ]; then
    if [ "$SERVICESTATE" == "CRITICAL" ] || [ "$HOSTSTATE" == "DOWN" ]; then
        MESSAGE_COLOR="FF0000"  # Red
    else
        MESSAGE_COLOR="FFA500"  # Orange
    fi
    MESSAGE_TITLE="Problem detected"
elif [ "$NOTIFICATIONTYPE" == "RECOVERY" ]; then
    MESSAGE_COLOR="00FF00"  # Green
    MESSAGE_TITLE="Recovery detected"
else
    MESSAGE_COLOR="FFFF00"  # Yellow
    MESSAGE_TITLE="Notification"
fi

ICINGA_SERVICE_URL="${ICINGAURL}/icingadb/service?host.name=${HOSTNAME}&name=${SERVICENAME}"

SHORTSERVICEOUTPUT=$(echo "$SERVICEOUTPUT" | head -n 1 | cut -c 1-100)

payload=$(cat <<EOF
{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "$MESSAGE_COLOR",
    "summary": "Icinga Notification",
    "sections": [{
        "activityTitle": "$MESSAGE_TITLE",
        "activitySubtitle": "$LONGDATETIME",
        "facts": [
            { "name": "Host:", "value": "$HOSTNAME" },
            { "name": "Service:", "value": "$SERVICENAME" },
            { "name": "State:", "value": "$HOSTSTATE $SERVICESTATE" },
            { "name": "Address:", "value": "$HOSTADDRESS" },
            { "name": "Output:", "value": "$SHORTSERVICEOUTPUT" }
        ],
        "markdown": true
    }],
    "potentialAction": [{
        "@type": "OpenUri",
        "name": "View in Icinga",
        "targets": [
            { "os": "default", "uri": "$ICINGA_SERVICE_URL" }
        ]
    }]
}
EOF
)

curl -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL"

exit 0

