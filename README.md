# SFTP Access

This repo creates a Docker image that provides STFP services via OpenSSH along with a script for managing the
server and the users in the container. New users can be added without restarting the container.

A management utility (`sftpctl`) provides the main method for user management and startup.

When properly configured, this container will persist user accounts and settings between runs.

At this time, it's expected that one builds this Docker image themselves as it allows for the most
customisation (eg: custom `sshd_config`).

## Quickstart

To get started quickly, first, clone this repo and build the docker image:

    docker build --tag sftp-access .

Then, start the container:

    docker run \
      -d \
      --rm \
      --name sftp-access \
      --volume "$PWD/data:/data" \
      --volume "$PWD/home:/home" \
      --volume "/mnt/nas/Photos:/mounts/Photos:ro" \
      --volume "/mnt/nas/Documents:/mounts/Documents:ro" \
      -p 2222:22 \
      sftp-access:latest

Then, add a user:

    docker exec sftp-access sftpctl add-user carl carl@example.com coralisdead

Below is details on how everything works.

## `sftpctl`

The `sftpctl` utility is the main point of interaction in the running container. It is used for user
management, initializing/starting `sshd`.

The usage of the utility is:

    sftpctl <subcommand> [ <arg> ... ]

Running the `sftpctl` utility in a running container can be done through `docker exec`:

    docker exec sftp-access sftpctl <subcommand> [ <arg> ... ]

Below are supported subcommands.

### init

The `init` subcommand takes no arguments and is the default command in the container. When started with no
arguments, the container executes `sftpctl init` which will perform the following actions:

 * read the user database and ensure accounts are created
 * re-sync each user's ssh keys to their GitHub accounts (if one is configured)
 * ensure that the user owns all of the files in their home directory
 * ensure all mounts are symlinked into the root of their home directories
 * start the sshd daemon via `exec` so it's the primary process of the container.

### add-user

The `add-user` subcommand is used to add a user to a running container without service interruption.

Usage:

    sftpctl add-user <username> <email> [ <github-username> ]

Running this subcommand will add the user to the user database, then ensure that the user's account is
created. The email address is inserted into the GECOS field in `/etc/passwd`. Any files/directories in the
`/mounts` directory are then symlinked into the user's home folder.

If the `<github-username>` is provided, this subcommand will pull the list of public ssh keys from the user's
aGitHub account and add them to `~$username/.ssh/authorized_keys` so they can log in via ssh/sftp without a
password and without any further configuration.

> Github makes all public ssh keys available for a user at the `https://github.com/<username>.keys`endpoint

Each time a user is added, the `sftpctl` script backs up the unix system account files (`passwd`, `shadow`,
`group`) to the `/data/` directory. See the [Data persistence](#data-persistence) section, below, for more
info.

See the [Mounts](#mounts) section for more information on giving users access to mounts.

See the [`sync`](#sync) subcommand for more information on keeping user accounts in sync.

See the [User database](#user-database) section for more information on the user database.

### add-key

The `add-key` subcommand is used for adding arbitrary public ssh keys to an existing user account's
`authorized_keys` file:

    sftpctl add-key <username> <key-data>

The `sftpctl` utility will validate that the key is a valid ssh key by using `ssh-keygen` before adding and
will exit with a non-zero status without adding the key if the key is not valid.

The `<key-data>` argument should be the public ssh key, as a string.

### sync

The `sync` subcommand iterates over every user in the `userdb` and ensures that they're configured correctly.

Usage:

    sftpctl sync

Running `sync` performs the following steps:

 * pull all public ssh keys from the user's GitHub account and ensure that they're added to the user's
     `authorized_keys` file
 * ensure that all files in the user's home directory are owned by that user
 * ensure that all mounts in the `/mounts` directory are symlinked to the root of the user's home directory

> Heads up: when sync'ing the user's ssh keys from GitHub, this is always an additive operation. SSH keys will
> not be deleted from `authorized_keys`.

## Data persistence

The `sftp-access` container keeps backups of the `passwd`, `shadow` and `group` files as well as copies of the
ssh host keys under `/data`. When starting the container, it's a good idea to either use a Docker volume or
mount a directory from the local filesystem to this location to ensure that these files can be re-used. It's
especially important for the ssh host keys so that users aren't presented with big scary warnings each time
the container is restarted.

> Specifically, user data files are stored under `/data/users` and host keys under `/data/host_keys`

If using `docker run` to run this container, mount a volume read/write to `/data`:

    --volume "path/to/data:/data"

### ssh host keys

The first time this container is started, it will generate fresh ssh host keys and make a copy into
`/data/host_keys`.

## User database

When starting up, this container will read in its user database from `/userdb` and create/configure each user
described in the file. In addition, the `sftpctl add-user` subcommand will append to this databaase file.

Ideally, one should always use the `sftpctl add-user` subcommand for creating users, but they can be
pre-populated into this file ahead of time for bulk actions.

The format of this file is one user per line, `<username>`, `<email>`, `<github-username>`, separated by
pipes:

    alice|alice@example.com|alicehub
    bob|bob@example.com|bob1234

This file should be persisted between runs by mounting the file to `/userdb`. If using `docker run`, the
following arguments can be used:

    --volume "path/to/userdb:/userdb"

## Mounts

The whole purpose of this container is that it provides access to files for users over SFTP. This section will
describe how to enable users to access these files in a consistent manner.

When user accounts are created and sync'd, the `sftpctl` utility will look into the `/mounts` directory,
iterate over them, and create symlinks for each into the user's home directory. By leveraging the power of
Docker mounts, you can granularly grant access to directories on the host filesystem with the access
permissions that you'd like.

For example, to mount a directory called `Documents` that is read-only, the following arguments can be passed
to `docker run`:

    --volume "path/to/Documents:/mounts/Documents:ro"

Alternatively, to create a read-write mount:

    --volume "path/to/Documents:/mounts/Documents"

Outside of that, standard unix permissions will be followed, as expected.

## Customisation

This container offers a couple of options for customisatoin/persionalisation.

### Welcome banner

Mounting a text file in the container at `/etc/ssh/banner` will display the banner to users before they log in
(the sshd `Banner` configuration directive).

For example, pass the following arguments when using `docker run`:

    --volume "path/to/banner:/etc/ssh/banner:ro"

### MOTD

Mounting a text file in the container at `/etc/motd` will display a welcome message when users successfully
log in.

For example, pass the following arguments when using `docker run`:

    --volume "path/to/motd:/etc/motd:ro"


