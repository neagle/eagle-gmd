#!/bin/bash

# we assume that you installed curl and jq here

# List from the root (oid 1), which should have home dir /world in it,
# which contains /world/${username} 

scurl() {
  theuser=$1
  theurl=$2
  curl  --cert   ../certs/gmdata_${theuser}_cert.pem \
	--key    ../certs/gmdata_${theuser}_key.pem \
	--cacert ../certs/gmdata_ca_cert.pem \
	${theurl}
}

gmdataCommand() {
  theuser=$1
  theCmd=$2
  thedir=$3
  scurl ${theuser} https://localhost:10809/services/gmdata/gmdata/${theCmd}/1${thedir}
}

# Examplesa that assume that you ran ./upladsExample.py for a bit to populate gmdata


echo "Directory listing, for ALL users"
gmdataCommand neagle list "/world" | jq

#echo "Directory listing, just for neagle (created after running uploadsExample.py"
#gmdataCommand neagle list "/world/neagle@gmdata.io" | jq

echo "Stream back the first file we find for neagle, using its oid to shorten the url"
oid=$(gmdataCommand neagle list "/world/neagle@gmdata.io" | jq -r -c 'map(select(.isfile==true))[1].oid')
oname=$(gmdataCommand neagle list "/world/neagle@gmdata.io" | jq -r -c 'map(select(.isfile==true))[1].name')
echo "use this url to look at neagle's file ${oname}"
echo "https://localhost:10809/services/gmdata/gmdata/show/${oid}"
## this is a similar variation that gets the file without classification banners around it
#echo "https://localhost:10809/services/gmdata/gmdata/stream/${oid}"

