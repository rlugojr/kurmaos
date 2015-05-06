#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

OUTPUT_PATH="../output/images/vagrant_vmware"

setup_chroot

mkdir -p $OUTPUT_PATH
cp ../output/images/raw.img $OUTPUT_PATH/vmware.bin
touch $OUTPUT_PATH/kurmaos.vmdk

echo "Generating"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile
cd kurmaos/packaging

./lib/disk_util --disk_layout=base mount $OUTPUT_PATH/vmware.bin /tmp/rootfs
cp oem_vagrant.json /tmp/rootfs/boot/oem/kurma_oem.json
./lib/disk_util umount /tmp/rootfs

./lib/disk_util --disk_layout=vm update $OUTPUT_PATH/vmware.bin

qemu-img convert -f raw $OUTPUT_PATH/vmware.bin -O vmdk -o adapter_type=lsilogic $OUTPUT_PATH/kurmaos.vmdk
rm $OUTPUT_PATH/vmware.bin
EOF

cat >"$OUTPUT_PATH/kurmaos.vmx" <<EOF
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
scsi0:0.fileName = "kurmaos.vmdk"
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

(
    cd $OUTPUT_PATH
    touch Vagrantfile
    echo '{"provider":"vmware_desktop"}' > metadata.json
    tar -czf kurmaos-vagrant-vmware.box Vagrantfile metadata.json kurmaos.vmx kurmaos.vmdk
)
