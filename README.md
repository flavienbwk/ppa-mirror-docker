# PPA Mirror Docker

Dockerized PPA downloader for apt installs.

## Why

Since Ubuntu 20.04, `snap` is the new package management standard for Ubuntu, over the old-school `apt`. Unlike `apt`, `snap` packages all dependencies of a package in a single file to be easily deployed (packages are self-contained).

However, it requires tricky configuration for offline infrastructures. For example, in Ubuntu 22.04, Chromium is not in the official `apt` mirror anymore, which is either installable through `snap` or [through the install of a PPA](https://askubuntu.com/questions/1204571/how-to-install-chromium-without-snap) (Personal Packages Archives). This is not possible on "on-the-edge" infrastructures because it requires Internet.

This repositories allows to easily retrieve files from a specific PPA for Ubuntu systems, for packages to be downloadable through the traditional `apt` command.

It is useful for large-clients infrastructures. Another reason might be `snap` is not allowed to be used by your organization.

> Note : If you are allowed to use `snap` and only have 1 package to download, you might consider [downloading it manually](https://askubuntu.com/questions/761742/is-it-possible-to-install-the-snap-application-in-an-offline-computer).

## Downloading & updating

1. Copy and edit the `.env` file with your own configuration

    ```bash
    cp .env.example .env
    ```

2. Run the `mirror` container :

    ```bash
    docker-compose build
    docker-compose run mirror
    ```

> Tips: We recommend you downloading the mirror from [a cloud provider](https://www.scaleway.com/en/) and then transfer files to your computer.

## Serving

1. Check your mirroring succeeded typing `du -sh ./mirror` to check the folder volume. Size varies depending on the PPA downloaded.

2. Run the server :

    ```bash
    docker-compose up -d server
    ```

    Server will run on [`localhost:8080`](http://localhost:8080)  

## Client configuration

1. Add the GPG keys of the downloaded PPAs

    ```bash
    cat ./mirror/ppa.launchpadcontent.net/savoury1/ffmpeg4/ubuntu/savoury1-ffmpeg4.pgp | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/savoury1-ffmpeg4.pgp --import -
    cat ./mirror/ppa.launchpadcontent.net/savoury1/chromium/ubuntu/savoury1-chromium.pgp | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/savoury1-chromium.pgp --import -
    ```

2. Make your Ubuntu computer point to your mirror by creating a `/etc/apt/source.list.d/ppa-mirror.list` file as follow :

    ```conf
    # For default example with ppa.launchpadcontent.net/savoury1 on Ubuntu Jammy (amd64)
    deb [arch=amd64] http://localhost:8080/ppa.launchpadcontent.net/savoury1/ffmpeg4/ubuntu jammy main
    deb [arch=amd64] http://localhost:8080/ppa.launchpadcontent.net/savoury1/chromium/ubuntu jammy main
    ```

:point_right: Feel free to add a reverse proxy or update the [nginx configuration file](./nginx.conf) to secure the mirror with SSL/TLS  
:point_right: Feel free to send **pull requests** as well !
