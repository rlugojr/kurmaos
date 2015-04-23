#!/sh
# FIXME convert spaces in NTP_SERVERS to be multiple -p arguments
exec /ntpd -n -N -p $NTP_SERVERS
