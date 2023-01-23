#!/bin/bash

# Check if CPU architecture is set and if it's a correct value
ACCEPTED_VALUES="armv7 aarch64 x64 x64-static"
if [ -z "$CPU_ARCHITECTURE" ] || ! echo "$ACCEPTED_VALUES" | grep -wq "$CPU_ARCHITECTURE"; then
  echo "\033[0;31mError: Please include a valid CPU architecture. Exiting... \033[0m"
  exit 1
fi

#display current config to the user and save to server_cfg.txt
echo ""
echo "\033[0;33mMinecraft server settings: \033[0m" | tee server_cfg.txt
echo "" | tee -a server_cfg.txt
echo "Minecraft Version= \033[0;33m$MC_VERSION\033[0m" | tee -a server_cfg.txt
echo "Lazymc version= \033[0;33m$LAZYMC_VERSION\033[0m" | tee -a server_cfg.txt
echo "Server provider= \033[0;33m$SERVER_PROVIDER\033[0m" | tee -a server_cfg.txt
echo "Server build= \033[0;33m$SERVER_BUILD\033[0m" | tee -a server_cfg.txt
echo "CPU architecture= \033[0;33m$CPU_ARCHITECTURE\033[0m" | tee -a server_cfg.txt
echo "Dedicated RAM= \033[0;33m${MC_RAM:-"Not specified."}\033[0m" | tee -a server_cfg.txt
echo "Java options= \033[0;33m${JAVA_OPTS:-"Not specified."}\033[0m" | tee -a server_cfg.txt
echo ""
echo "\033[0;33mCurrent configuration saved to server_cfg.txt \033[0m"
echo ""
#give user time to read
sleep 2

# Enter server directory
cd mcserver

# Get lazymc
if [ "$LAZYMC_VERSION" = "latest" ]
then
  LAZYMC_VERSION=$(wget -qO - https://api.github.com/repos/timvisee/lazymc/releases/latest | jq -r .tag_name | cut -c 2-)
  if [ -z "$LAZYMC_VERSION" ]
  then
    echo "\033[0;31mError: Could not get latest version of lazymc. Exiting... \033[0m"
    echo "Something went wrong, retry." > ../server_cfg.txt
    exit 1
  fi
fi
LAZYMC_URL="https://github.com/timvisee/lazymc/releases/download/v$LAZYMC_VERSION/lazymc-v$LAZYMC_VERSION-linux-$CPU_ARCHITECTURE"
status_code=$(curl -s -o /dev/null -w '%{http_code}' ${LAZYMC_URL})
if [ "$status_code" -ne 302 ]
then
  echo "\033[0;31mError: Lazymc $LAZYMC_VERSION version does not exist or is not available. Exiting... \033[0m"
  echo "Something went wrong, retry." > ../server_cfg.txt
  exit 1
fi

echo "\033[0;33mDownloading lazymc $LAZYMC_VERSION... \033[0m"
echo ""
wget -qO lazymc ${LAZYMC_URL}
chmod +x lazymc

# Get version information and build download URL and jar name
case "$SERVER_PROVIDER" in
  "paper")
      URL=https://papermc.io/api/v2/projects/paper
      if [ ${MC_VERSION} = latest ]
      then
        # Get the latest MC version
        echo "\033[0;33mGetting latest Minecraft version... \033[0m"
        echo ""
        MC_VERSION=$(wget -qO - $URL | jq -r '.versions[-1]') # "-r" is needed because the output has quotes otherwise
        if [ $? -ne 0 ]
        then
          echo "\033[0;31mError: Could not get latest version of Minecraft \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
      fi
      URL=${URL}/versions/${MC_VERSION}
      if [ ${SERVER_BUILD} = latest ]
      then
        # Get the latest build
        echo "\033[0;33mGetting latest build for Paper... \033[0m"
        echo ""
        SERVER_BUILD=$(wget -qO - $URL | jq '.builds[-1]')
        if [ $? -ne 0 ]
        then
          echo "\033[0;31mError: Could not get latest build of Paper \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
        else
        # Check if the build exists
        echo "\033[0;33mChecking existance of $SERVER_BUILD build for Paper \033[0m"
        echo ""
        status_code=$(curl -s -o /dev/null -w '%{http_code}' ${URL}/builds/${SERVER_BUILD})
        if [ "$status_code" -ne 200 ]
        then
          echo "\033[0;31mError: Paper $SERVER_BUILD build does not exist or is not available. Exiting... \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
      fi
      JAR_NAME=${SERVER_PROVIDER}-${MC_VERSION}-${SERVER_BUILD}.jar
      URL=${URL}/builds/${SERVER_BUILD}/downloads/${JAR_NAME}
      ;;
  "purpur")
      URL=https://api.purpurmc.org/v2/purpur/
      if [ ${MC_VERSION} = latest ]
      then
        # Get the latest MC version
        echo "\033[0;33mGetting latest Minecraft version... \033[0m"
        echo ""
        MC_VERSION=$(wget -qO - $URL | jq -r '.versions[-1]')
        if [ $? -ne 0 ]
        then
          echo "\033[0;31mError: Could not get latest version of Minecraft \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
      fi
      BUILD_URL=https://api.purpurmc.org/v2/purpur/${MC_VERSION}/
      if [ ${SERVER_BUILD} = latest ]
      then
        # Get the latest build
        echo "\033[0;33mGetting latest build for Purpur \033[0m"
        echo ""
        SERVER_BUILD=$(wget -qO - $BUILD_URL | jq -r '.builds.latest')
        if [ $? -ne 0 ]
        then
          echo "\033[0;31mError: Could not get latest build of Purpur \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
        else
        # Check if the build exists
        echo "\033[0;33mChecking existance of $SERVER_BUILD build for Purpur \033[0m"
        echo ""
        status_code=$(curl -s -o /dev/null -w '%{http_code}' ${URL}${MC_VERSION}/builds/${SERVER_BUILD})
        if [ "$status_code" -ne 200 ]
        then
          echo "\033[0;31mError: Purpur $SERVER_BUILD build does not exist or is not available. Exiting... \033[0m"
          echo "Something went wrong, retry." > ../server_cfg.txt
          exit 1
        fi
      fi

      JAR_NAME=${SERVER_PROVIDER}-${MC_VERSION}-${SERVER_BUILD}.jar
      URL=${BUILD_URL}${SERVER_BUILD}/download
      ;;
  *)
      echo "\033[0;31mError: $SERVER_PROVIDER is not a valid provider. Exiting... \033[0m"
      echo "Something went wrong, retry." > ../server_cfg.txt
      exit 1
      ;;
esac

# Update jar if necessary
if [ ! -e ${JAR_NAME} ]
then
  # Remove old server jar(s)
  echo "\033[0;33mRemoving old server jars... \033[0m"
  echo ""
  rm -f *.jar
  # Download new server jar
  echo "\033[0;33mDownloading $JAR_NAME \033[0m"
  echo ""
  if ! curl -f -o ${JAR_NAME} -sS ${URL}
  then
    echo "\033[0;31mError: Jar URL does not exist or is not available. Exiting... \033[0m"
    echo "Something went wrong, retry." > ../server_cfg.txt
    exit 1
  fi
fi

# If this is the first run, accept the EULA
if [ ! -e eula.txt ]
then
  # Run the server once to generate eula.txt
  echo "\033[0;33mGenerating EULA... \033[0m"
  echo ""
  java -jar ${JAR_NAME} > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
      echo "\033[0;31mError: Cannot generate EULA. Exiting... \033[0m"
      echo "Something went wrong, retry." > ../server_cfg.txt
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
if [ ! -e lazymc.toml ]
then
  echo "\033[0;33mGenerating lazymc.toml \033[0m"
  echo ""
  ./lazymc config generate
  if [ $? -ne 0 ]
  then
    echo "\033[0;31mError: Could not generate lazymc.toml \033[0m"
    echo "Something went wrong, retry." > ../server_cfg.txt
    exit 1
  fi
else
  # Add new values to lazymc.toml
  echo "\033[0;33mUpdating lazymc.toml with latest details... \033[0m"
  echo ""
  # Check if the comment is already present in the file
  if ! grep -q "mcserver-lazymc-docker" lazymc.toml;
  then
    # Add the comment to the file
    sed -i '/Command to start the server/i # Managed by mcserver-lazymc-docker, please do not edit this!' lazymc.toml
  fi
  sed -i "s~command = .*~command = \"java $JAVA_OPTS -jar $JAR_NAME nogui\"~" lazymc.toml
fi



# Start the server
echo "\033[0;33mStarting the server! \033[0m"
echo ""
./lazymc start
if [ $? -ne 0 ]
then
  echo "\033[0;31mError: Could not start the server \033[0m"
  echo "Something went wrong, retry." > ../server_cfg.txt
  exit 1
fi