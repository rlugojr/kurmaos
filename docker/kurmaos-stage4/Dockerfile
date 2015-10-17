# Begin from Gentoo stage3
FROM apcera/kurmaos-stage3

# Run the build.
COPY build.sh /tmp/
RUN /tmp/build.sh && rm /tmp/build.sh
