#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

setup_chroot

mkdir -p ../output/images/vmware
touch ../output/images/vmware/vmware.vmdk

echo "Generating"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile
cd kurmaos/packaging
qemu-img convert -f raw ../output/images/raw.img -O vmdk -o adapter_type=lsilogic ../output/images/vmware/vmware.vmdk
EOF

cat >"../output/images/vmware/vmware.vmx" <<EOF
#!/usr/bin/vmware
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "7"
cleanShutdown = "TRUE"
displayName = "KurmaOS"
ethernet0.addressType = "generated"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "vmxnet3"
floppy0.present = "FALSE"
guestOS = "other3xlinux-64"
memsize = "1024"
powerType.powerOff = "soft"
powerType.powerOn = "hard"
powerType.reset = "hard"
powerType.suspend = "hard"
scsi0.present = "TRUE"
scsi0.virtualDev = "pvscsi"
scsi0:0.fileName = "vmware.vmdk"
scsi0:0.present = "TRUE"
sound.present = "FALSE"
usb.generic.autoconnect = "FALSE"
usb.present = "TRUE"
rtc.diffFromUTC = 0
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
EOF
