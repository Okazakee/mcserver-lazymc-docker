# JRE base
FROM eclipse-temurin:17.0.5_8-jre-jammy

# Environment variables
ENV CPU_ARCHITECTURE="" \
    SERVER_PROVIDER="paper" \
    LAZYMC_VERSION="latest" \
    MC_VERSION="latest" \
    SERVER_BUILD="latest" \
    MC_RAM="" \
    JAVA_OPTS=""

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
