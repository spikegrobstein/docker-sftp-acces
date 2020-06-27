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

  # set -x

  useradd \
    -d "$homedir" \
    -s /bin/rbash \
    -c "$email" \
    "$username" \
    || true

  backup_accounts

  if [[ ! -d "$homedir" ]]; then
    # if the home directory doesn't eixst (useradd does not create it)
    # then let's set up the authorized_keys file and all that.
    mkdir -p "$homedir/.ssh"

    curl "https://github.com/${gh_username}.keys" >> "$homedir/.ssh/authorized_keys"

    cat "$homedir/.ssh/authorized_keys" \
      | sort -u \
      | sponge "$homedir/.ssh/authorized_keys"

    warn "Added keys for $username"
    # cat "$homedir/.ssh/authorized_keys"
  fi

  # make sure the user owns their stuff
  for d in "$homedir"/*; do
    if [[ -L "$d" ]]; then
      # skip any symlinks
      continue
    fi

    chown -R "${username}:${username}" "$d"
  done

  pushd "$homedir" &> /dev/null

  local dir_name 

  # create the mounts
  for d in /mounts/*; do
    dir_name=$( basename "$d" )

    if [[ -L "$dir_name" ]]; then
      continue
    fi

    ln -s "$d"
  done

  popd &> /dev/null

  # set +x
}

# copy account files into data directory for persistence
backup_accounts() {
  cp "${account_files[@]}" "$datadir/"
}

# copy account files from data directory to restore
restore_accounts() {
  cp /data/* /etc/

  chown root:root "${account_files[@]}"
  chmod 600 /etc/shadow /etc/shadow-
  chmod 640 /etc/passwd /etc/passwd- /etc/group /etc/group-
}

action_init() {
  local userdata

  # first, restore accounts
  restore_accounts

  if [[ -s "$userfile" ]]; then
    mapfile -t users < "$userfile"

    for user in "${users[@]}"; do
      if [[ -z "$user" || "$user" = "#"* ]]; then
        continue
      fi

      userdata="$( tr '|' $'\n' <<< "$user" )"
      mapfile -t userdata <<< "$userdata"

      create_user "${userdata[@]}"
    done
  fi

  exec /usr/sbin/sshd -D -e
}

action_add() {
  if [[ "$#" -ne 3 ]]; then
    die "Incorrect usage"
  fi

  create_user "$@"
}

mountsdir="/mounts"

userfile=/users.txt

datadir="/data"
account_files=(
  /etc/{shadow,group,passwd}
  /etc/{shadow,group,passwd}-
)

# userfile looks like:
# <username>|<email>|<github-username>

action="$1"
shift

case "$action" in
  init)
    action_init "$@"
    ;;

  add)
    action_add "$@"
    ;;
esac

