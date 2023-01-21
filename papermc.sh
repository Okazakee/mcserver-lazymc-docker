#!/bin/bash

# Enter server directory
cd papermc

# Get lazymc
if [ ${LAZYMC_VERSION} = latest ]
then
  LAZYMC_VERSION=$(wget -qO - https://api.github.com/repos/timvisee/lazymc/releases/latest | jq -r .tag_name)
fi
LAZYMC_URL="https://github.com/timvisee/lazymc/releases/download/$LAZYMC_VERSION/lazymc-$LAZYMC_VERSION-linux-$CPU_ARCHITECTURE"
wget -O lazymc ${LAZYMC_URL}
chmod +x lazymc

# Generate lazymc.tom if necessary
if [ ! -e lazymc.toml ]
then
  ./lazymc config generate
fi

# Get version information and build download URL and jar name
case $SERVER_PROVIDER in
  "purpur")
    # Get the latest build
    if [ ${MC_VERSION} = latest ] || [ -z ${MC_VERSION} ]
    then
      MC_VERSION=$(wget -qO - https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    fi
    if [ ${SERVER_BUILD} = latest ]
    then
      SERVER_BUILD=$(wget -qO - https://api.purpurmc.org/v2/purpur/${MC_VERSION} | jq -r '.builds[-1]')
    fi
    JAR_NAME=${SERVER_PROVIDER}-${MC_VERSION}-${SERVER_BUILD}.jar
    URL=https://api.purpurmc.org/v2/purpur/${MC_VERSION}/${SERVER_BUILD}/download
    ;;
  "paper")
    URL=https://papermc.io/api/v2/projects/paper
    if [ ${MC_VERSION} = latest ]
    then
      # Get the latest MC version
      MC_VERSION=$(wget -qO - $URL | jq -r '.versions[-1]') # "-r" is needed because the output has quotes otherwise
    fi
    URL=${URL}/versions/${MC_VERSION}
    if [ ${SERVER_BUILD} = latest ]
    then
      # Get the latest build
      SERVER_BUILD=$(wget -qO - $URL | jq '.builds[-1]')
    fi
    JAR_NAME=paper-${MC_VERSION}-${SERVER_BUILD}.jar
    URL=${URL}/builds/${SERVER_BUILD}/downloads/${JAR_NAME}
    ;;
  *)
    echo "Invalid server provider, please use the ones provided in the documentation"
    exit 1
    ;;
esac

# Update if necessary
if [ ! -e ${JAR_NAME} ]
then
  # Remove old server jar(s)
  rm -f *.jar
  # Download new server jar
  wget ${URL} -O ${JAR_NAME}

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
