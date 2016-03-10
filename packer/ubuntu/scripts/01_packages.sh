# Abort on error
set -e -x

# Get the codename and update the apt sources. This is to add in the universe
# set of pacakges.
ubuntuCodename=$(lsb_release -s -c)
echo "deb http://us.archive.ubuntu.com/ubuntu/ $ubuntuCodename main restricted universe" > /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ $ubuntuCodename-security main restricted universe" >> /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ $ubuntuCodename-updates main restricted universe" >> /etc/apt/sources.list

# Update packages
apt-get --yes --force-yes update

# http://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt
# Core problem: post-install scripts don't care that we told apt-get --yes/--force-yes
DEBIAN_FRONTEND=noninteractive
UCF_FORCE_CONFFNEW=yes
export DEBIAN_FRONTEND UCF_FORCE_CONFFNEW
ucf --purge /boot/grub/menu.lst
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

## NOTE: Ubuntu 12.04 does NOT like to install this package from the
## percise-security/main repo when scripted with packer. It will when the same
## script is ran locally on the via terminal, but never with Packer.
if [[ "$ubuntuCodename" == "precise" ]]; then
    wget -O /tmp/linux-image-extras.deb http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-image-extra-3.2.0-99-virtual_3.2.0-99.139_amd64.deb
    dpkg -i /tmp/linux-image-extras.deb
    rm /tmp/linux-image-extras.deb
else
    # Install the specific needed linux-image-extra to get aufs
    extraPkg=$(dpkg -l | grep linux-image | grep -v linux-image-virtual | awk '{print $2}' | sed -e 's#linux-image#linux-image-extra#g')
    apt-get -y install $extraPkg
fi

# Some needed apps/libraries
apt-get -y install git libcap2 rsync
