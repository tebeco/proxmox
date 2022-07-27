#!/bin/bash

SOURCE_FILES=$1
TARGET_USER=$2
TARGET_HOST=$3
TARGET_FOLDER=$4

ARCHIVE_NAME=${TARGET_FOLDER##*/}.tar.gz

function naively-accept-ssh-host()
{
    TARGET_USER=$1
    TARGET_HOST=$2

    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$TARGET_HOST"
    ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/kube-key-ecdsa "$TARGET_USER"@"$TARGET_HOST" 'ls'
}

naively-accept-ssh-host "$TARGET_USER" "$TARGET_HOST"

if [ ! -f "$SOURCE_FILES" ]; then
    echo "$SOURCE_FILES needs to be a file listing all files to archive";
    exit 1;
fi

rm -f /tmp/"$ARCHIVE_NAME"
cd "$(dirname "${SOURCE_FILES}")" || exit
tar -cvzf "/tmp/$ARCHIVE_NAME" -T "$SOURCE_FILES"
cd - || exit

scp -i ~/.ssh/kube-key-ecdsa "/tmp/$ARCHIVE_NAME" "$TARGET_USER@$TARGET_HOST:/tmp"
ssh -i ~/.ssh/kube-key-ecdsa "$TARGET_USER@$TARGET_HOST" "rm -rf $TARGET_FOLDER; mkdir -p $TARGET_FOLDER;tar -xvzf /tmp/$ARCHIVE_NAME --directory $TARGET_FOLDER"

ssh -i ~/.ssh/kube-key-ecdsa "$TARGET_USER@$TARGET_HOST" "cd $TARGET_FOLDER && ./install.sh"