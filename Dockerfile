# Update PAPER_VERSION and PAPER_BUILD to match your desired release.
# Find builds at: https://api.papermc.io/v2/projects/paper/versions/<version>/builds
FROM eclipse-temurin:21-jre-jammy

ARG PAPER_VERSION=1.21.1
ARG PAPER_BUILD=127
# Geyser version tracks the Minecraft version it targets.
ARG GEYSER_MC_VERSION=latest
ARG GEYSER_BUILD=latest

WORKDIR /minecraft

# Create a non-root user, install curl, download JARs, accept EULA — all in
# one layer to keep the image small and avoid leaving package caches behind.
RUN \
    # Create a system group and matching non-root user for running the server.
    # Using a system account (no login shell, no home outside /minecraft) limits
    # the blast radius if the process is ever compromised.
    groupadd --system minecraft \
    && useradd --system --gid minecraft --home-dir /minecraft minecraft \
    \
    # Install curl (needed to download JARs below), then wipe the apt cache so
    # it doesn't bloat the image layer.
    && apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    \
    # Download the PaperMC server JAR for the requested version + build number.
    # The URL is constructed from the PAPER_VERSION and PAPER_BUILD build args.
    && curl -fsSL -o paper.jar \
        "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar" \
    \
    # Download the Geyser-Spigot plugin JAR into the plugins directory.
    # Geyser bridges Bedrock Edition clients to the Java Edition server.
    && mkdir -p plugins \
    && curl -fsSL -o plugins/Geyser-Spigot.jar \
        "https://download.geysermc.org/v2/projects/geyser/versions/${GEYSER_MC_VERSION}/builds/${GEYSER_BUILD}/downloads/spigot" \
    \
    # Accept the Minecraft EULA. The server refuses to start without this file.
    && echo "eula=true" > eula.txt \
    \
    # Hand ownership of everything under /minecraft to the non-root user so the
    # server process can write world data, logs, and config files at runtime.
    && chown -R minecraft:minecraft /minecraft

USER minecraft

# World data and logs are the only truly dynamic directories at runtime.
# Mount named volumes here to persist them across container recreations.
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
