# Abort on error
set -e -x

# Update packages
dnf -y check-update

# Upgrade to the latest
dnf -y upgrade

# Some needed apps/libraries
dnf -y install git libcap wget
