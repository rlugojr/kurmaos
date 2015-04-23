#!/sh

mount --bind /host/lib/firmware /lib/firmware
mount --bind /host/lib/modules /lib/modules

udevd --daemon
udevadm trigger --action=add
udevadm settle
