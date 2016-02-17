# Begin from KurmaOS stage4
FROM apcera/kurmaos-stage4:20160217-1b84a785

# Run the build.
COPY build.sh kernel.defconfig patches /tmp/
RUN /tmp/build.sh && rm /tmp/build.sh
