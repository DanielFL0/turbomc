FROM eclipse-temurin:25

WORKDIR /app

ARG PAPER_VERSION=1.21.11
ARG PAPER_BUILD=127
ARG MC_VERSION=latest
ARG GEYSER_VERSION=latest
ARG SERVER_SOFTWARE=spigot

RUN apt-get update && apt-get install -y curl

RUN curl -fsSL -o paper.jar \
  https://fill-data.papermc.io/v1/objects/da497e12b43e5b61c5df150e4bfd0de0f53043e57d2ac98dd59289ee9da4ad68/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar

RUN curl -fsSL -o geyser.jar \ 
  https://download.geysermc.org/v2/projects/geyser/versions/${MC_VERSION}/builds/${GEYSER_VERSION}/downloads/${SERVER_SOFTWARE}

EXPOSE 25565

CMD ["java", "-Xmx2G", "-jar", "paper.jar", "--nogui"]