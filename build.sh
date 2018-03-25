#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exit_cmd=""
defer() { exit_cmd="$@; $exit_cmd"; }
trap 'bash -c "$exit_cmd"' EXIT

PACKAGES=${@:-pkgbuild/*}
CHROOT="$PWD/root"

#RSYNC_SRV=rsync://ipv4:port
REPO_PATH=repo/x86_64
REPO_NAME=wiltech

mkdir -p "$CHROOT"
[[ -d "$CHROOT/root" ]] || mkarchroot -C /etc/pacman.conf $CHROOT/root base base-devel

for package in $PACKAGES; do
    cd "$package"
    rm -f *.pkg.tar.xz
    makechrootpkg -cur $CHROOT
    cd -
done

repo="$(mktemp -d)"
defer "rmdir '$repo'"

#s3fs "$BUCKET" "$repo" -o "nosuid,nodev,default_acl=public-read"
#defer "fusermount -u '$repo'"

rsync --ignore-existing -v pkg/*/*.pkg.tar.xz "$repo/$REPO_PATH"
repose --verbose --xz --root="$repo/$REPO_PATH" "$REPO_NAME"
