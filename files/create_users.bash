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
  username="$1"
  email="$2"
  gh_username="$3"

  gh_username="$( tr -d $'\n' <<< "$gh_username" )"

  warn "Creating user: $username"

  set -x
  useradd \
    -d "/home/$username" \
    -s /bin/rbash \
    -c "$email" \
    "$username"

  mkdir -p "/home/$username/.ssh"

  curl "https://github.com/${gh_username}.keys" > "/home/$username/.ssh/authorized_keys"

  warn "Added keys for $username"
  cat "/home/$username/.ssh/authorized_keys"

  chown -R "${username}:${username}" "/home/$username"
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

/usr/sbin/sshd -D -e

