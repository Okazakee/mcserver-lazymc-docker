# Minecraft Servers w/ `lazymc` using Docker
This is a Linux Docker image for creating Minecraft servers with `lazymc`.

[lazymc](https://github.com/timvisee/lazymc) is a utility that puts your Minecraft server to rest when idle and wakes it up when players try to connect. This allows the server to not waste resources if nobody is connected.

This image provides a basic PaperMC (or alternatives) server. All customizations are left to the user.

# To do:
- [x] Automatically update server variables inside lazymc.toml.
- [x] Add Docker Compose section in this README.
- [x] Do not trgger github actions when README or actions yml get pushed.
- [x] Push updated README to Dockerhub Repo.
- [x] Better logging, remove useless console outputs and give the user clear and clean messages of what is going on.
- [x] Replace Openjdk with Temurin -> reduced docker image size by 57.52%!
- [ ] Add flag to disable lazymc.
- [ ] Vanilla Support.
- [ ] Fabric Support.
- [ ] Pufferfish Support.
- [ ] Arclight Support.
- [ ] Build a webpage for the project.

# Usage
It is assumed that the user has already acquired a working Docker installation. If that is not the case, go do that and come back here when you're done.

With this image, you can create a new PaperMC (or alternatives) Minecraft server with one command or a docker compose file.

`Note that running said command or docker compose indicates agreement to the Minecraft EULA.`

### Here is an example:

## Using docker run:
```bash
sudo docker run -p 25565:25565 -e CPU_ARCHITECTURE="<your_cpu_arch>" okazakee/mcserver-lazymc-docker
```
While this command will work just fine in many cases, it is only the bare minimum required to start a functional server and can be vastly improved by specifying more options/envs.

## Using docker compose:

```yaml
version: '3.3'
services:
    mcserver-lazymc-docker:
        ports:
            - '<your-port>:25565'
        container_name: <your-container-name>
        environment:
            - CPU_ARCHITECTURE=<your-cpu-architecture>
            - SERVER_PROVIDER=<your-server-provider>
            - LAZYMC_VERSION=<your-lazymc-version>
            - MC_VERSION=<your-mc-version>
            - SERVER_BUILD=<your-server-build>
            - MC_RAM=<your-ram-budget>
            - JAVA_OPTS=<your-java-arguments>
        volumes:
            - '<your-volume-or-path>:/mcserver'
        image: okazakee/mcserver-lazymc-docker:<latest/staging>
```


## Options
There are several command line options that users may want to specify when utilizing this image. These options are listed below with some brief explanation. An example will be provided with each. In the example, the part that the user can change will be surrounded by angle brackets (`< >`). Remember to *remove the angle brackets* before running the command.
- Port
  - This option must be specified. Use port `25565` if you don't know what this is.
  - Set this to the port number that the server will be accessed from.
  - If RCON is to be used, this option must be specified a second time for port `25575`.
  - `-p <12345>:25565`
  - `-p <12345>:25565 -p <6789>:25575`
- Volume
  - Set this to a name for the server's Docker volume (defaults to randomized gibberish).
  - Alternatively, set this to a path to a folder on your computer.
  - `-v <my_volume_name>:/mcserver`
  - `-v </path/to/files>:/mcserver`
- Detached
  - Include this to make the container independent from the current command line.
  - `-d`
- Terminal/Console
  - Include these flags if you want access to the server's command line via `docker attach`.
  - These flags can be specified separately or as one option.
  - `-t` and `-i` in any order
  - `-ti` or `-it`
- Restart Policy
  - If you include this, the server will automatically restart if it crashes.
  - Stopping the server from its console will still stop the container.
  - It is highly recommended to only stop the server from its console (not via Docker).
  - `--restart on-failure`
- Name
  - Set this to a name for the container (defaults to a couple of random words).
  - `--name "<my-container-name>"`

There is one more command line option, but it is a bit special and deserves its own section.
### Environment Variables
Environment variables are options that are specified in the format `-e <NAME>="<VALUE>"` where `<NAME>` is the name of the environment variable and `<VALUE>` is the value that the environment variable is being set to. Please note that setting an evironment variable with no value leaves the default value, which you can look up below.

Mandatory `ENV` fields will have a `*` after their name.

This image has seven environment variables:
- Server Provider
  - **Name:** `SERVER_PROVIDER`
  - Set this to the server provider you want to use.
  - Selectable providers are: `paper`, `purpur`.
  - Default value: `paper`.
  - `-e SERVER_PROVIDER="<paper>"`
- CPU Architecture *
  - **Name:** `CPU_ARCHITECTURE`
  - Set this to the cpu architecture you want to use.
  - Selectable architectures are: `x64`, `x64-static`, `aarch64`, `armv7`.
  - No default value for this, make sure to include it in the command.
  - `-e CPU_ARCHITECTURE="<x64>"`
- Minecraft Version
  - **Name:** `MC_VERSION`
  - Set this to the Minecraft version that the server should support.
  - Note: there must be a PaperMC (or alternatives) release for the specified version of Minecraft.
  - If this is not set, the latest version supported by PaperMC (or alternatives) will be used.
  - Changing this on an existing server will change the version *without wiping the server*.
  - `-e MC_VERSION="<latest>"`
- Server Build
  - **Name:** `SERVER_BUILD`
  - Set this to the number of the PaperMC (or alternatives) build that the server should use (**not the Minecraft version**).
  - If this is not set, the latest PaperMC (or alternatives) build for the specified `MC_VERSION` will be used.
  - Changing this on an existing server will change the version *without wiping the server*.
  - `-e SERVER_BUILD="<latest>"`
- Lazymc Version
  - **Name:** `LAZYMC_VERSION`
  - Set this to the version of `lazymc` you want to use.
  - If not set, the [latest release](https://github.com/timvisee/lazymc/releases/latest) will be used.
  - `-e LAZYMC_VERSION="<latest>"`
- RAM
  - **Name:** `MC_RAM`
  - Set this to the amount of RAM the server can use.
  - Must be formatted as a number followed by `M` for "Megabytes" or `G` for "Gigabytes".
  - If this is not set, Java allocates its own RAM based on total system/container RAM.
  - `-e MC_RAM="<4G>"`
- Java options
  - **Name:** `JAVA_OPTS`
  - **ADVANCED USERS ONLY**
  - Set to any additional Java command line options that you would like to include.
  - By default, this environment variable is set to the empty string.
  - `-e JAVA_OPTS="<-XX:+UseConcMarkSweepGC -XX:+UseParNewGC>"`

## Further Setup
From this point, the server should be configured in the same way as any other Minecraft server. The server's files, including `server.properties`, can be found in the volume that was specified earlier. The port that was specified earlier will probably need to be forwarded as well. For details on how to do this and other such configuration, Google it, because it works the same as any other Minecraft server.
### Suggested repo for optimizing your settings: [YouHaveTrouble/minecraft-optimization](https://github.com/YouHaveTrouble/minecraft-optimization)


# Technical
This project *does **NOT** redistribute the Minecraft server files*.

**PLEASE NOTE:** This is an unofficial project. I did not create PaperMC or other providers.

## Project Pages
- [GitHub page](https://github.com/okazakee/mcserver-lazymc-docker).
- [Docker Hub page](https://hub.docker.com/r/okazakee/mcserver-lazymc-docker).