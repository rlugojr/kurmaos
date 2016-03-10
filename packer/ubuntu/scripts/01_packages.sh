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
apt-get --force-yes -fuy dist-upgrade

# Install the specific needed linux-image-extra to get aufs
extraPkg=$(dpkg -l | grep linux-image | grep -v linux-image-virtual | awk '{print $2}' | sed -e 's#linux-image#linux-image-extra#g')
apt-get -y install $extraPkg

# Some needed apps/libraries
apt-get -y install git libcap2 rsync
