FROM openjdk:17-slim

WORKDIR /minecraft

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 minecraft && \
    chown -R minecraft:minecraft /minecraft

USER minecraft

RUN wget -O server.jar https://launcher.mojang.com/v1/objects/e00c4052dac1d59a1188b2aa9d5db57d6691b221/server.jar

COPY --chown=minecraft:minecraft eula.txt .
COPY --chown=minecraft:minecraft server.properties .

EXPOSE 25565

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:25565 || exit 1

ENTRYPOINT ["java", "-Xmx1024M", "-Xms1024M", "-jar", "server.jar", "nogui"]