#!/bin/bash

#
#  This generates a ssh config from the hostnames in the puppet db, 
#  which then can be autocompleted when connecting with ssh or ssm
#

(
ssh puppet01.admin.jppol.net <<-\SSH
    echo "santawashere"
    curl -s -X POST http://localhost:8080/pdb/query/v4/facts   -H 'Content-Type:application/json'   -d '{"query":[ "or", ["=","name","ipaddress"],["=", "name", "operatingsystem"]]}'|jq 'group_by([.certname]) | map((.[0]|del(.value)) + { members: (map(.value)) })'|jq -c 'group_by(.certname)[]|add'|sed   's/"/ /g'|awk '{print $4 " " $16 " " $18}'|sort -k3
SSH
) | sed '1,/santawashere/d' > /tmp/asdf

(
while read hostname ip dist; do
    echo -e "# $hostname\t$ip\t$dist"
    echo "Host $hostname"
    echo "    Hostname $ip"
    echo " "
done < /tmp/asdf
) > ~/.ssh/config.jppol
