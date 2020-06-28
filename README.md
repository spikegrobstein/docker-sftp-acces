# SFTP Access

A Docker image that contains an SFTP server with automated user creation. The container is designed for
providing access to select filesystems without needing to pollute the host system with extraneous accounts or
software packages while ensuring minimal risk.

## Usage

### Building

To build the image, just run:

    docker build --tag sftp-access .

### Running

This is an example for running the container. All new users will have symlinks to read-only volumes for
`Documents` and `Audio` in their home directories.

    docker run \
      --rm \
      --name sftp-access \
      --volume "path/to/users.txt:/users.txt" \
      --volume "path/to/Documents:/mounts/Documents:ro" \
      --volume "path/to/Audio:/mounts/Audio:ro" \
      --volume "path/to/data:/data" \
      --volume "path/to/home:/home" \
      sftp-access

See [Mounts](#mounts) section below for information on mounts.

See [User accounts](#user-accounts) section below for information on users.

See [Persisting data](#persisting-data) section below for information on persisting data.

## Features

When started, this container will [optionally] read a user database file to initialize itself, creating users.
When creating a user, it accepts the desired username, the user's email address and their github.com account
name. These values are used in the following manner:

 * username -- the account name to use when logging in to the sftp server
 * email -- this is added to the GECOS field when creating the user, ideally for contacting the user after the
     fact by some external system.
 * github account -- this is used to populate the default ssh keys for the user to log in. See [ssh
     keys](#ssh-keys) section below for details on this.

The container uses a script to both intialize and create new users and will create backups of files necessary
for persisting the user accounts.

### SSH Keys

During initial user creation, the user's public Github account should be supplied. When this is done, the
setup script will pull down their public ssh keys from `https://github.com/<username>.keys` and add them to
the user's `authorized_keys` file. This will always append and dedupe the keys in a non-destructive manner.

Connected users can add their own, additional ssh keys without fear of them being clobbered.

### Mounts

When a user account is created and whenever accounts are updated, the setup script will create symlinks into
the user's home of each directory inside `/mounts`. The idea is that when spinning up the container, there
will be read-only volume mounts placed inside `/mounts`. Any mounts that you'd like to provide read/write
access should be mounted read/write.

> With docker, to mount a volume read-only, append a `:ro` to the end of the string. For example
> `/foo:/bar:ro`

### User accounts

User accounts in the container are standard Linux user accounts and should be created with the built-in
`sftpctl` tool or use the [user database file](#database) for creation on-startup.

#### Adding accounts

Running scripts in the container is done via `docker exec`.

Use `sftpctl add <username> <email> <github-account>` to create new user accounts.

#### Database

A user account file lives at `/users.txt`. It's a plaintext file and includes one user account per line in the
format of:

    username|email|github-account

### Persisting data

Data is persisted in 2 ways:

Users' home directories live at `/home` (like usual). This can be a docker volume or a local filesystem mount
to persist data between runs/reboots.

User account data is backed up between executions of `sftpctl add` to `/data`. This should be a docker volume
or a local filesystem mount to persist data between runs/reboots.
