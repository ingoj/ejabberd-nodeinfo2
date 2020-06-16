#!/bin/sh
set -fe
EJBIN=$(command -v ejabberdctl)
EJCONF="/etc/ejabberd/ejabberd.yml"
SQLTYPE=$(grep ^sql_type "${EJCONF}" | cut -d ":" -f2 | sed -e 's/"//g' | tr -d "[:blank:]")
if [ "${SQLTYPE}" = "pgsql" ]; then
	SQLBIN=$(command -v psql)
elif [ "${SQLTYPE}" = "mysql" ]; then
	SQLBIN=$(command -v mysql)
else
	echo "No supported database (pgsql/mysql) found in ${EJCONF}"
	exit 0
fi
SQLSERVER=$(grep ^sql_server "${EJCONF}" | cut -d ":" -f2 | sed -e 's/"//g' | tr -d "[:blank:]")
SQLPORT=$(grep ^sql_port "${EJCONF}" | cut -d ":" -f2 | tr -d "[:blank:]") 
SQLDB=$(grep ^sql_database "${EJCONF}" | cut -d ":" -f2 | sed -e 's/"//g' | tr -d "[:blank:]")
SQLUSER=$(grep ^sql_username "${EJCONF}" | cut -d ":" -f2 | sed -e 's/"//g' | tr -d "[:blank:]")
# password needs to be set in $HOME/.pgpass of user running this script
# see https://www.postgresql.org/docs/12/libpq-pgpass.html for details

# I don't like to have full version reported (eg.: ejabberd 20.04-1~bpo10+1), so instead
# we are just reporting major and minor version
VERSION=$("${EJBIN}" status | grep ^ejabberd | cut -d "-" -f 1 | awk '{print $2}')

# iterate over all registered vhosts in ejabberd 
for VHOST in $("${EJBIN}" registered_vhosts); do 
	# get the data from postgresql database about active and total user counts
	if [ "${SQLTYPE}" = "pgsql" ]; then
		res=$(${SQLBIN} -h "${SQLSERVER}" -p "${SQLPORT}" -U "${SQLUSER}" -t "${SQLDB}" -c "select concat((select count(username) from last where extract(epoch from now())-seconds::integer<86400*7 and server_host='${VHOST}')||':'||(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30 and server_host='${VHOST}')||':'||(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30*6 and server_host='${VHOST}')||':'||(select count(username) from users where server_host='${VHOST}')||':'||(select count(*) from archive where server_host='${VHOST}'))")
		ACTIVEWEEK=$(echo "${res}"|cut -d ":" -f1 )
		ACTIVEMONTH=$(echo "${res}"|cut -d ":" -f2 )
		ACTIVEHALFYEAR=$(echo "${res}"|cut -d ":" -f3 )
		TOTAL=$(echo "${res}"|cut -d ":" -f4 )
		LOCALPOSTS=$(echo "${res}"|cut -d ":" -f5 )
	elif [ "${SQLTYPE}" = "mysql" ]; then
		# MySQL queries to be placed here
		#res=$(${SQLBIN} -h "${SQLSERVER}" -p "${SQLPORT}" -U "${SQLUSER}" -t "${SQLDB}" -c "select concat((select count(username) from last where extract(epoch from now())-seconds::integer<86400*7 and server_host='${VHOST}')||':'||(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30 and server_host='${VHOST}')||':'||(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30*6 and server_host='${VHOST}')||':'||(select count(username) from users where server_host='${VHOST}'))")
		#ACTIVEWEEK=$(echo "${res}"|cut -d ":" -f1 )
		#ACTIVEMONTH=$(echo "${res}"|cut -d ":" -f2 )
		#ACTIVEHALFYEAR=$(echo "${res}"|cut -d ":" -f3 )
		#TOTAL=$(echo "${res}"|cut -d ":" -f4 )
		#LOCALPOSTS=$(echo "${res}"|cut -d ":" -f5 )
		true
	fi
	# is the registration closed or open?
	REGRES=$(curl -s "https://compliance.conversations.im/server/${VHOST}/" | awk  '/XEP-0077/,/\/div/' | head -n 3 | grep "img src" | cut -d"=" -f2 | sed -e 's/>//g' -e 's/"//g'  | cut -d"/" -f3)
	case "${REGRES}" in 
		"passed.svg")
			REGISTRATION="true"
			;;
		*)
			REGISTRATION="false"
			;;
	esac
	# output the JSON file to a webserver path & include VHOST name
	# replace "name" and "contact" to match your sites
	cat > "/var/www/well-known/${VHOST}_x-nodeinfo2" << EOF
{
  "organization": {
    "name": "Hookipa admins",
    "contact": "xmpp:discussion@chat.hookipa.net?join"
  },
  "server": {
    "baseUrl": "https://${VHOST}/",
    "version": "${VERSION}",
    "name": "${VHOST}",
    "software": "ejabberd"
  },
  "services": {
    "outbound": [
      "xmpp"
    ],
    "inbound": [
      "xmpp"
    ]
  },
  "protocols": [
    "xmpp"
  ],
  "version": "1.0",
  "openRegistrations": ${REGISTRATION},
  "usage": {
    "users": {
      "activeWeek": ${ACTIVEWEEK},
      "total": ${TOTAL},
      "activeMonth": ${ACTIVEMONTH},
      "activeHalfyear": ${ACTIVEHALFYEAR}
    },
    "localPosts": ${LOCALPOSTS},
    "localComments": 0
  }
}
EOF
 
done

