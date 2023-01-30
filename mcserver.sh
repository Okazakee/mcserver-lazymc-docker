#!/bin/bash

# Declare supported Lazymc archs
lazymc_supported_archs="aarch64 x86_64"

# Getting arch from system
arch=$(uname -m)

# Adapt the answer in x86 case to support Lazymc url schema
[[ $arch == "x86_64" ]] && arch="x64"

# Check if Lazymc is supported for that arch, if not, continue disabling Lazymc
if echo "$lazymc_supported_archs" | grep -wq "$arch"; then
  echo "\032[0;31mWarning! Your CPU architecture ($arch) is not supported by Lazymc. Disabling it... \033[0m"
  LAZYMC_VERSION="disabled"
fi

# Enter server directory
cd mcserver

#display current config to the user and save to server_cfg.txt
echo ""
echo "\033[0;33mMinecraft server settings: \033[0m" | tee server_cfg.txt
echo "" | tee -a server_cfg.txt
echo "Minecraft Version= \033[0;33m$MC_VERSION\033[0m" | tee -a server_cfg.txt
echo "Lazymc version= \033[0;33m$LAZYMC_VERSION\033[0m" | tee -a server_cfg.txt
echo "Server provider= \033[0;33m$SERVER_PROVIDER\033[0m" | tee -a server_cfg.txt
echo "Server build= \033[0;33m$SERVER_BUILD\033[0m" | tee -a server_cfg.txt
echo "CPU architecture= \033[0;33m$CPU_ARCH\033[0m" | tee -a server_cfg.txt
echo "Dedicated RAM= \033[0;33m${MC_RAM:-"Not specified."}\033[0m" | tee -a server_cfg.txt
echo "Java options= \033[0;33m${JAVA_OPTS:-"Not specified."}\033[0m" | tee -a server_cfg.txt
echo ""
echo "\033[0;33mCurrent configuration saved to mcserver/server_cfg.txt \033[0m"
echo ""

#give user time to read
sleep 1

# Lazymc handler
lazymc_download() {
  echo "\033[0;33mDownloading lazymc $LAZYMC_VERSION... \033[0m"
  echo ""
  wget -qO lazymc ${LAZYMC_URL}
  chmod +x lazymc
}

# URL builder
if [ "$LAZYMC_VERSION" = "disabled" ]
then
  # Skip download
  echo "\033[0;33mSkipping lazymc download... \033[0m"
  echo ""
elif [ "$LAZYMC_VERSION" = "latest" ]
then
  # Build latest ver download url
  LAZYMC_VERSION=$(wget -qO - https://api.github.com/repos/timvisee/lazymc/releases/latest | jq -r .tag_name | cut -c 2-)
  if [ -z "$LAZYMC_VERSION" ]
  then
    echo "\033[0;31mError: Could not get latest version of lazymc. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
else
  # Build specified ver download url
  LAZYMC_URL="https://github.com/timvisee/lazymc/releases/download/v$LAZYMC_VERSION/lazymc-v$LAZYMC_VERSION-linux-$CPU_ARCH"
  status_code=$(curl -s -o /dev/null -w '%{http_code}' ${LAZYMC_URL})
  if [ "$status_code" -ne 302 ]
  then
    echo "\033[0;31mError: Lazymc $LAZYMC_VERSION version does not exist or is not available. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
  # Download lazymc
  lazymc_download
fi

# Declaring supported types
allowed_modded_type="fabric"
allowed_servers_type="paper purpur"

# Determine server type
if [ "$SERVER_PROVIDER" = "vanilla" ]
then
    SERVER_TYPE="vanilla"
elif [ -z "$SERVER_PROVIDER" ] || echo "$allowed_modded_type" | grep -wq "$SERVER_PROVIDER"
then
    SERVER_TYPE="modded"
elif [ -z "$SERVER_PROVIDER" ] || echo "$allowed_servers_type" | grep -wq "$SERVER_PROVIDER"
then
    SERVER_TYPE="servers"
else
    echo "\033[0;31mError: $SERVER_PROVIDER is not supported. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
fi

# FETCH LATEST VER API - thx to serverjars.com
API_FETCH_LATEST="https://serverjars.com/api/fetchLatest/${SERVER_TYPE}/${SERVER_PROVIDER}"
# FETCH VER DETAILS API - thx to serverjars.com
API_FETCH_DETAILS="https://serverjars.com/api/fetchDetails/${SERVER_TYPE}/${SERVER_PROVIDER}/${MC_VERSION}"

# Get the latest MC version
if [ ${MC_VERSION} = latest ]
then
  echo "\033[0;33mGetting latest Minecraft version... \033[0m"
  echo ""
  if ! MC_VERSION=$(wget -qO - $API_FETCH_LATEST | jq -r '.response.version')
  then
    echo "\033[0;31mError: Could not get latest version of Minecraft. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
  else
  # Check if the version exists
  if ! [ ${MC_VERSION} = "$(wget -qO - $API_FETCH_DETAILS | jq -r '.response.version')" ]
  then
    echo "\033[0;31mError: Minecraft version $MC_VERSION version does not exist or is not available. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
fi

# FETCH JAR API - thx to serverjars.com
API_FETCH_JAR="https://serverjars.com/api/fetchJar/${SERVER_TYPE}/${SERVER_PROVIDER}/${MC_VERSION}"

# Set the BUILD_FETCH_API value based on SERVER_PROVIDER
case $SERVER_PROVIDER in
    "paper") BUILD_FETCH_API="https://papermc.io/api/v2/projects/paper/versions/${MC_VERSION}/builds/${SERVER_BUILD}";;
    "purpur") BUILD_FETCH_API="https://api.purpurmc.org/v2/purpur/${MC_VERSION}/${SERVER_BUILD}";;
    *) echo "\033[0;33mSkipping build check because $SERVER_PROVIDER does not support custom builds number \033[0m"
       echo "";;
esac

#Server build handler
if [ ${SERVER_BUILD} = latest ]
then
  # Get the latest build - GIMMICK CHECK CODE SINCE MAJOR SCRIPT UPDATE
  echo "\033[0;33mGetting latest build for ${SERVER_PROVIDER}... \033[0m"
  echo ""
else
  # Check if the build exists
  echo "\033[0;33mChecking existance of $SERVER_BUILD build for ${SERVER_PROVIDER} \033[0m"
  echo ""
  status_code=$(curl -s -o /dev/null -w '%{http_code}' ${BUILD_FETCH_API})
  if [ "$status_code" -ne 200 ]
  then
    echo "\033[0;31mError: ${SERVER_PROVIDER} $SERVER_BUILD build does not exist or is not available. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
fi

# Set the jar file name
JAR_NAME=${SERVER_PROVIDER}-${MC_VERSION}-${SERVER_BUILD}.jar

# Update jar if necessary
if [ ! -e ${JAR_NAME} ]
then
  # Remove old server jar(s)
  echo "\033[0;33mRemoving old server jars... \033[0m"
  echo ""
  rm -f *.jar
fi

# Download new server jar
echo "\033[0;33mDownloading $JAR_NAME \033[0m"
echo ""
if ! curl -o ${JAR_NAME} -sS ${API_FETCH_JAR}
then
  echo "\033[0;31mError: Jar URL does not exist or is not available. Exiting... \033[0m" | tee server_cfg.txt
  exit 1
fi

# If this is the first run, accept the EULA
if [ ! -e eula.txt ]
then
  # Run the server once to generate eula.txt
  echo "\033[0;33mGenerating EULA... \033[0m"
  echo ""
  if ! java -jar ${JAR_NAME} > /dev/null 2>&1
  then
      echo "\033[0;31mError: Cannot generate EULA. Exiting... \033[0m" | tee server_cfg.txt
      exit 1
  fi
  # Edit eula.txt to accept the EULA
  echo "\033[0;33mAccepting EULA... \033[0m"
  echo ""
  sed -i 's/false/true/g' eula.txt
fi

# Add RAM options to Java options if necessary
echo "\033[0;33mSetting Java arguments... \033[0m"
echo ""
if [ ! -z "${MC_RAM}" ]
then
  JAVA_OPTS="-Xms512M -Xmx${MC_RAM} ${JAVA_OPTS}"
else
  JAVA_OPTS="-Xms512M ${JAVA_OPTS}"
fi

# Generate lazymc.toml if necessary
if [ ! -e lazymc.toml ] && [ ! "$LAZYMC_VERSION" = "disabled" ]
then
  echo "\033[0;33mGenerating lazymc.toml \033[0m"
  echo ""
  if ! ./lazymc config generate
  then
    echo "\033[0;31mError: Could not generate lazymc.toml. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
fi

# Add new values to lazymc.toml
if [ ! "$LAZYMC_VERSION" = "disabled" ]
then
  echo "\033[0;33mUpdating lazymc.toml with latest details... \033[0m"
  echo ""
  # Check if the comment is already present in the file
  if ! grep -q "mcserver-lazymc-docker" lazymc.toml;
  then
    # Add the comment to the file
    sed -i '/Command to start the server/i # Managed by mcserver-lazymc-docker, please do not edit this!' lazymc.toml
  fi
  if ! sed -i "s~command = .*~command = \"java $JAVA_OPTS -jar $JAR_NAME nogui\"~" lazymc.toml
  then
    echo "\033[0;31mError: Could not update lazymc.toml. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
fi

# Server launch handler
if [ "$LAZYMC_VERSION" = "disabled" ]
then
  # Start directly the server when lazymc is disabled
  echo "\033[0;33mStarting the server! \033[0m"
  echo ""
  if ! java $JAVA_OPTS -jar $JAR_NAME nogui
  then
    echo "\033[0;31mError: Could not start the server. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
else
  echo "\033[0;33mStarting the server! \033[0m"
  echo ""
  if ! ./lazymc start
  then
    echo "\033[0;31mError: Could not start the server. Exiting... \033[0m" | tee server_cfg.txt
    exit 1
  fi
fi