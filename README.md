# Keytool Local Trust

A Makefile recipe to wip up an https ready Java keystore and truststore

## Usage

Make sure the Java `keytool` command-line tool is available on your path

This repo provides a `Makefile` that goes through the complete set of steps
necessary to produce a PKCS12 `keystore` and `truststore` capable of being used to get
local https working right away.

Just run `make`

```sh
make
```

This should produce a bunch of files, so lets talk about the mental model...

## Mental model

 - The 'root' keystore serves as a mini Certificate Authority (CA)
 - The 'server' keystore and truststore serve as the Java keystore and truststore, respectively, to use for a webserver
 - The goal is to create a CA Root Certificate and a server Certificate, signed by that CA (both managed as PEM files).

Once we have the certificates, we can:

- Load the server private key and server certificate into the keystore to allow the server to serve requests
- Load the root and server certificates into the truststore so the server will trust them
- Load the root and server certificates into our system keychain (OSX) so client software (Google Chrome) will trust them

Now, let's look at the files created previously by running `make`

``` sh
tree
.
├── Makefile
├── README.md
├── keystore.jks
├── root.jks
├── root.pem
├── server.crt
├── server.csr
├── server.pem
└── truststore.jks

0 directories, 9 files
```

- Makefile: The makefile, take a look at the targets!
- README.md: This file
- keystore.jks: The default server keystore, with the server private key and signed certificate. Ready to use with a Java app.
- root.jks: The default root keystore, with the root private key
- root.pem: The root certificate, to be installed for trust chain
- server.crt: The server certificate, signed by the root.jks
- server.csr: The server certificate signing request, presented to root.jks to sign
- server.pem: The signed server certificate, to be installed for trust chain
- truststore.jks: The default server truststore, with the signed server certificate and the root certificate. Ready to use with a Java app.

Run `clean` to remove all the files 

``` sh
make clean
```

## OSX make targets

I use OSX for most of my development, so there are some make targets sprinkled
in that can help you add and remove the root/server PEM to your OSX keychain,
but these aren't run implicitly.
