#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exit_cmd=""
defer() { exit_cmd="$@; $exit_cmd"; }
trap 'bash -c "$exit_cmd"' EXIT

PACKAGES=${@:-pkgbuild/*}
CHROOT="$PWD/root"

SSHFS_HOST=165.227.215.148
REPO_PATH=repo/x86_64
REPO_NAME=wiltech

mkdir -p "$CHROOT"
[[ -d "$CHROOT/root" ]] || mkarchroot -C /etc/pacman.conf $CHROOT/root base base-devel oh-my-zsh-git

for package in $PACKAGES; do
    cd "$package"
    rm -f *.pkg.tar.xz
    makechrootpkg -curn $CHROOT
    cd -
done

repo="$(mktemp -d)"
defer "rmdir '$repo'"

sshfs -o idmap=user,IdentityFile=/home/doc/.ssh/id_rsa doc@${SSHFS_HOST}:/var/www/html "$repo"
defer "fusermount -u '$repo'"

rsync --ignore-existing -v pkgbuild/*/*.pkg.tar.xz "$repo/$REPO_PATH"
repose --verbose --xz --root="$repo/$REPO_PATH" "$REPO_NAME"
