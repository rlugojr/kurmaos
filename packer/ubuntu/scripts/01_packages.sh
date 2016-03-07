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

# Install linux-image-extra. No longer exists after Ubuntu 15.04. Of releases
# before then, we only care about Ubuntu 14.04 and 12.04.
ubuntuRelease=$(lsb_release -s -r)
if [[ "$ubuntuRelease" == "14.04" || "$ubuntuRelease" == "12.04" ]]; then
    apt-get -y install linux-image-extra
fi

# Some needed apps/libraries
apt-get -y install git libcap2
