#!/bin/bash

# Enter server directory
cd mcserver

# Get lazymc
if [ "$LAZYMC_VERSION" = "latest" ]
then
  LAZYMC_VERSION=$(wget -qO - https://api.github.com/repos/timvisee/lazymc/releases/latest | jq -r .tag_name)
if [ -z "$LAZYMC_VERSION" ]
  then
    echo "Error: Could not get latest version of lazymc. Exiting..."
    exit 1
fi
fi
  LAZYMC_URL="https://github.com/timvisee/lazymc/releases/download/$LAZYMC_VERSION/lazymc-$LAZYMC_VERSION-linux-$CPU_ARCHITECTURE"
  status_code=$(curl -s -o /dev/null -w '%{http_code}' ${LAZYMC_URL})
    if [ "$status_code" -ne 200 ]
      then
        echo "Error: Lazymc version does not exist or is not available. Exiting..."
        exit 1
fi
wget -O lazymc ${LAZYMC_URL}
chmod +x lazymc

# Generate lazymc.tom if necessary
if [ ! -e lazymc.toml ]
then
  ./lazymc config generate
  if [ $? -ne 0 ]; then
    echo "Error: Could not generate lazymc config"
    exit 1
  fi
fi

# Get version information and build download URL and jar name
case "$SERVER_PROVIDER" in
    "paper")
        URL=https://papermc.io/api/v2/projects/paper
        ;;
    "purpur")
        URL=https://purpurmc.io/api/v2/projects/purpur
        ;;
    *)
        echo "Error: Invalid SERVER_PROVIDER. Exiting..."
        exit 1
        ;;
esac

if [ ${MC_VERSION} = latest ]
then
  # Get the latest MC version
  MC_VERSION=$(wget -qO - $URL | jq -r '.versions[-1]') # "-r" is needed because the output has quotes otherwise
  if [ $? -ne 0 ]; then
    echo "Error: Could not get latest version of Minecraft"
    exit 1
  fi
fi

URL=${URL}/versions/${MC_VERSION}
if [ ${SERVER_BUILD} = latest ]
then
  # Get the latest build
  SERVER_BUILD=$(wget -qO - $URL | jq '.builds[-1]')
fi
JAR_NAME=${SERVER_PROVIDER}-${MC_VERSION}-${SERVER_BUILD}.jar
URL=${URL}/builds/${SERVER_BUILD}/downloads/${JAR_NAME}

#check if build exists
status_code=$(curl -s -o /dev/null -w '%{http_code}' ${URL})
if [ "$status_code" -ne 200 ]
  then
  echo "Error: Build does not exist or is not available. Exiting..."
  exit 1
fi

# Update if necessary
if [ ! -e ${JAR_NAME} ]
then
  # Remove old server jar(s)
  rm -f *.jar
  # Download new server jar
  wget ${URL} -O ${JAR_NAME} || exit 1

  # If this is the first run, accept the EULA
  if [ ! -e eula.txt ]
  then
    # Run the server once to generate eula.txt
    java -jar ${JAR_NAME}
    # Edit eula.txt to accept the EULA
    sed -i 's/false/true/g' eula.txt
  fi
fi

# Add RAM options to Java options if necessary
if [ ! -z "${MC_RAM}" ]
then
  JAVA_OPTS="-Xms512M -Xmx${MC_RAM} ${JAVA_OPTS}"
fi

# Update lazymc config command
sed -i -e "s@command =.*@command = \"java -server ${JAVA_OPTS} -jar ${JAR_NAME} nogui\"@" lazymc.toml

# Start server
exec ./lazymc start