#! /usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

warn() {
  printf "%s\n" "$@" >&2
}

die() {
  warn "$@"
  exit 1
}

create_user() {
  local username="$1"
  local email="$2"
  local gh_username="$3"

  gh_username="$( tr -d $'\n' <<< "$gh_username" )"

  local homedir="/home/$username"

  warn "Creating user: $username"

  set -x

  useradd \
    -d "$homedir" \
    -s /bin/rbash \
    -c "$email" \
    "$username"

  if [[ ! -d "$homedir" ]]; then
    # if the home directory doesn't eixst (useradd does not create it)
    # then let's set up the authorized_keys file and all that.
    mkdir -p "$homedir/.ssh"

    curl "https://github.com/${gh_username}.keys" > "$homedir/.ssh/authorized_keys"

    warn "Added keys for $username"
    # cat "$homedir/.ssh/authorized_keys"
  fi

  # make sure the user owns their stuff
  chown -R "${username}:${username}" "$homedir"

  # create the mounts
  create_mounts "$homedir"

  set +x
}

create_mounts() {
  local homedir="$1"
  local m
  local mountname

  for m in "$mountsdir"/*; do
    mountname="$( basename "$m" )"

    mkdir -p "$homedir/$mountname"
    mount --bind "$m" "$homedir/$mountname" 
  done
}

mountsdir="/mounts"

userfile=/users.txt

# userfile looks like:
# <username>|<email>|<github-username>

if [[ ! -s "$userfile" ]]; then
  die "No userfile at $userfile."
fi

mapfile -t users < "$userfile"

for user in "${users[@]}"; do
  if [[ -z "$user" || "$user" = "#"* ]]; then
    continue
  fi
  mapfile -t -d '|' userdata <<< "$user"

  create_user "${userdata[@]}"
done

exec /usr/sbin/sshd -D -e

