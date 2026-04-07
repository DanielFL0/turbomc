# Place paper.jar in the repo root and plugin JARs in plugins/ before building.
# Download Paper from https://papermc.io/downloads
# Download Geyser from https://geysermc.org/download
FROM eclipse-temurin:21-jre-jammy

WORKDIR /minecraft

# Create a non-root user and accept the EULA.
RUN groupadd --system minecraft \
    && useradd --system --gid minecraft --home-dir /minecraft minecraft \
    && echo "eula=true" > eula.txt

# Copy server JAR and plugins from the build context.
COPY paper.jar .
COPY plugins/ plugins/

# Hand ownership to the non-root user.
RUN chown -R minecraft:minecraft /minecraft

USER minecraft

# World data and logs persist across container recreations.
VOLUME ["/minecraft/world", "/minecraft/world_nether/", "/minecraft/world_the_end/", "/minecraft/logs"]

# Java edition (TCP) and Geyser/Bedrock edition (UDP)
EXPOSE 25565/tcp
EXPOSE 19132/udp

# Confirm the Java port is accepting connections before marking healthy.
# start-period gives the server time to generate the world on first boot.
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD bash -c 'echo >/dev/tcp/localhost/25565' || exit 1

# Aikar's recommended JVM flags for Minecraft servers.
# Tune -Xms/-Xmx to match the memory available on your host.
CMD ["java", \
     "-Xms1G", "-Xmx2G", \
     "-XX:+UseG1GC", \
     "-XX:+ParallelRefProcEnabled", \
     "-XX:MaxGCPauseMillis=200", \
     "-XX:+UnlockExperimentalVMOptions", \
     "-XX:+DisableExplicitGC", \
     "-XX:+AlwaysPreTouch", \
     "-XX:G1NewSizePercent=30", \
     "-XX:G1MaxNewSizePercent=40", \
     "-XX:G1HeapRegionSize=8M", \
     "-XX:G1ReservePercent=20", \
     "-XX:G1HeapWastePercent=5", \
     "-XX:G1MixedGCCountTarget=4", \
     "-XX:InitiatingHeapOccupancyPercent=15", \
     "-XX:G1MixedGCLiveThresholdPercent=90", \
     "-XX:G1RSetUpdatingPauseTimePercent=5", \
     "-XX:SurvivorRatio=32", \
     "-XX:+PerfDisableSharedMem", \
     "-XX:MaxTenuringThreshold=1", \
     "-Dusing.aikars.flags=https://mcflags.emc.gs", \
     "-Daikars.new.flags=true", \
     "-jar", "paper.jar", "--nogui"]
