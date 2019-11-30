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

  if [[ -d "$homedir" ]]; then
    # the home directory already exists so we probably made this user already. let's skip
    warn "Skipping $username"
    continue
  fi

  warn "Creating user: $username"

  set -x
  useradd \
    -d "$homedir" \
    -s /bin/rbash \
    -c "$email" \
    "$username"

  mkdir -p "$homedir/.ssh"

  curl "https://github.com/${gh_username}.keys" > "$homedir/.ssh/authorized_keys"

  warn "Added keys for $username"
  # cat "$homedir/.ssh/authorized_keys"

  chown -R "${username}:${username}" "$homedir"
  set +x
}

userfile=/users.txt

# userfile looks like:
# <username>|<email>|<github-username>

if [[ ! -s "$userfile" ]]; then
  die "No userfile at $userfile."
fi

mapfile -t users < "$userfile"

for user in "${users[@]}"; do
  mapfile -t -d '|' userdata <<< "$user"

  create_user "${userdata[@]}"
done

exec /usr/sbin/sshd -D -e

