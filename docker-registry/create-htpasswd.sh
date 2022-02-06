#!/bin/bash

if [ -z $REGISTRY_USER ]
then
    echo "You need to set REGISTRY_USER env var before execute this script"
    exit 1
fi

if [ -z $REGISTRY_PASS ]
then
    echo "You need to set REGISTRY_PASS env var before execute this script"
    exit 1
fi

TARGET=/tmp/docker-registry
rm -rf $TARGET
mkdir -p $TARGET/auth

docker run --rm --entrypoint htpasswd registry:2.6.2 \
    -Bbn $REGISTRY_USER $REGISTRY_PASS > $TARGET/auth/htpasswd

if [ $? -ne 0 ]
then
    echo "Can't add authentication."
    exit 1
fi

echo "File htpasswd successfuly created in $TARGET/auth"

kubectl create secret generic docker-registry-htpasswd \
    --from-file $TARGET/auth/htpasswd

