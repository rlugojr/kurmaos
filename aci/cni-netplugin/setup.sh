#!/bin/sh

# read stdin
payload=$(mktemp $TMPDIR/cni-command.XXXXXX)
cat > $payload <&0

# locate the plugin
plugin=$(jq -r '.type // ""' < $payload)
if [ "$plugin" == "" ]; then
    echo "No CNI plugin specified"
    exit 1
fi

# check to see if the dhcp daemon should be started
ipam=$(jq -r '.ipam.type // ""' < $payload)
if [ "$ipam" == "dhcp" ]; then
    /usr/bin/dhcp daemon &
fi

exit 0
