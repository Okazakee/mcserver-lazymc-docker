# JRE base
FROM openjdk:17-slim

# Environment variables
ENV MC_VERSION="latest" \
    LAZYMC_VERSION="latest" \
    SERVER_BUILD="latest" \
    MC_RAM="" \
    JAVA_OPTS="" \
    CPU_ARCHITECTURE="x64" \
    SERVER_PROVIDER="paper"

COPY mcserver.sh .
RUN apt update \
    && apt install -y wget jq curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /mcserver

# Start script
CMD ["sh", "./mcserver.sh"]

# Container setup
EXPOSE 25565/tcp
EXPOSE 25565/udp
VOLUME /mcserver
