# Begin from KurmaOS stage4
FROM apcera/kurmaos-stage4:20160217-152c1e11

# Run the build.
COPY build.sh kernel.defconfig patches /tmp/
RUN /tmp/build.sh && rm /tmp/build.sh
