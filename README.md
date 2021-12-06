# Keytool Local Trust

Make sure the Java `keytool` tool is available!

This repo provides a `Makefile` that goes through the complete set of steps
necessary to produce a PKCS12 `keystore` and `truststore` capable of being used to get
local https working right away.

Just run `make`

```sh
make
Creating root keypair in root.jks
Exporting root pem from root.jks to root.pem
Moving root alias from root.jks into truststore.jks
Creating server keypair in keystore.jks
Creating a server csr in server.csr
Creating a server crt in server.crt
Exporting server pem from keystore.jks to server.pem
Moving server alias from keystore.jks into truststore.jks
Done populating keystore.jks and truststore.jks.
They should be ready to copy to the resources directory of a project, and to be used as the keystore and truststore, respectively.
Try 'make list-root-keystore', 'make list-server-keystore', and 'make list-server-truststore' to see the contents of the keystores.
Try 'make osx-add-root-pem-to-keychain' and 'make osx-add-server-pem-to-keychain' to add the root and server certificates to your OSX keychain.
```

I use OSX for most of my development, so there are some make targets sprinkled in that can help you add and remove the root/server PEM to your OSX keychain.
