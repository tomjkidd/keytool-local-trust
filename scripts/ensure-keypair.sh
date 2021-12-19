#!/usr/bin/env bash

if [ -e $KEYSTORE_NAME ]; then
    echo "$KEYSTORE_NAME exists";
    (if (keytool -keystore $KEYSTORE_NAME -storepass $KEYSTORE_PASSWORD -list -alias $ALIAS >/dev/null); then
        echo "$ALIAS keypair already exists. Doing nothing";
    else
        echo "Generating $ALIAS keypair";
        (if [ $ALIAS == "server" ]; then make create-server-keypair; elif [ $ALIAS == "root" ]; then make create-root-keypair; fi;)
     fi;)

else
    echo "$KEYSTORE_NAME does not exist, generating $ALIAS keypair";
    (if [ $ALIAS == "server" ]; then make create-server-keypair; elif [ $ALIAS == "root" ]; then make create-root-keypair; fi;)
fi;
