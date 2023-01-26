# JRE base
FROM eclipse-temurin:19-jre-jammy

# Environment variables
ENV CPU_ARCH="" \
    SERVER_PROVIDER="purpur" \
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
CMD ["bash", "./mcserver.sh"]

# Container setup
EXPOSE 25565/tcp
EXPOSE 25565/udp
EXPOSE 25575/tcp
EXPOSE 25575/udp
VOLUME /mcserver
