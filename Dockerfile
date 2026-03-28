FROM eclipse-temurin:25

WORKDIR /app

ARG MC_VERSION=latest
ARG GEYSER_VERSION=latest
ARG SERVER_SOFTWARE=spigot

RUN apk add --no-cache curl

RUN curl -fsSL -o geyser.jar \ 
  https://download.geysermc.org/v2/projects/geyser/versions/${MC_VERSION}/builds/${GEYSER_VERSION}/downloads/${SERVER_SOFTWARE}
