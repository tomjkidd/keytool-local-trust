# Mental Model:
# - The 'root' keystore serves a mini Certificate Authority (CA)
# - The 'server' keystore and truststore serve as the Java keystore and truststore, respectively, to use for a webserver
# - The goal is to create a CA Root Certificate and a server Certificate, signed by that CA (both managed as PEM files).

# Once we have the certificates, we can:
# - Load the server private key and server certificate into the keystore to allow the server to server request
# - Load the root and server certificates into the truststore to allow the server establish trust in them
# - Load the root and server certificates into our system keychain (OSX) so client software (Google Chrome) will trust them

# It is very important that the SUBJECT_ALTERNATIVE_NAME is configured to the domain(s) you want to test,
# Google Chrome insists they are present, and you'll get NET::ERR_CERT_COMMON_NAME_INVALID errors if they
# are missing. The 'print-server-csr' and 'print-server-crt' were created so that you can make sure that
# this data is present in the Certificate Signing Request (CSR) and Signed Certificate (CRT) files created
# by this processing.
# The default domains that are supported are 'localhost' and 'keytool-local-trust',
# but you should include any domains you intend to use to test locally.

ROOT_KEYSTORE_NAME?=root.jks
ROOT_KEYSTORE_PASSWORD?=password
ROOT_PEM_NAME=root.pem

SERVER_KEYSTORE_NAME?=keystore.jks
SERVER_KEYSTORE_PASSWORD?=password
SERVER_TRUSTSTORE_NAME?=truststore.jks
SERVER_TRUSTSTORE_PASSWORD?=password

CERT_COMMON_NAME?=keytool-local-trust
# If you provide more DNS values, make sure to update /etc/hosts!
SUBJECT_ALTERNATIVE_NAME=SAN=DNS:localhost,DNS:keytool-local-trust

SERVER_CSR_NAME=server.csr
SERVER_CRT_NAME=server.crt
SERVER_PEM_NAME=server.pem

.PHONY: all

all: move-root-to-truststore move-server-to-truststore
	@echo "Done populating $(SERVER_KEYSTORE_NAME) and $(SERVER_TRUSTSTORE_NAME)."
	@echo "They should be ready to copy to the resources directory of a project, and to be used as the keystore and truststore, respectively."
	@echo "Try 'make list-root-keystore', 'make list-server-keystore', and 'make list-server-truststore' to see the contents of the keystores."
	@echo "Try 'make osx-add-root-pem-to-keychain' and 'make osx-add-server-pem-to-keychain' to add the root and server certificates to your OSX keychain."

clean:
	rm -f $(ROOT_KEYSTORE_NAME) $(SERVER_KEYSTORE_NAME) $(SERVER_TRUSTSTORE_NAME) \
	$(ROOT_PEM_NAME) \
	$(SERVER_CSR_NAME) $(SERVER_CRT_NAME) $(SERVER_PEM_NAME)
	@echo "Don't forget to delete the system certificates, if you added them!"
	@echo "Try 'make osx-find-root-cert', 'make osx-find-server-cert', and 'osx-show-me-delete-certificate-cmd'"

create-root-keypair:
	@echo 'Creating root keypair in $(ROOT_KEYSTORE_NAME)'
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -deststoretype pkcs12 -genkeypair -keyalg RSA \
	-alias root -dname "cn=$(CERT_COMMON_NAME) RootCA, ou=$(CERT_COMMON_NAME) Root_CertificateAuthority, o=CertificateAuthority, c=US"
remove-root-from-root-keystore:
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -delete -alias root
list-root-keystore:
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -list -v

create-server-keypair:
	@echo 'Creating server keypair in $(SERVER_KEYSTORE_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -deststoretype pkcs12 -genkeypair -keyalg RSA \
	-validity 395 -keysize 2048 -sigalg SHA256withRSA \
	-alias server -dname "CN=localhost,O=$(CERT_COMMON_NAME),OU=$(CERT_COMMON_NAME),L=Boston,ST=MA,C=US" -ext "$(SUBJECT_ALTERNATIVE_NAME)"
list-server-keystore:
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -list -v

create-server-csr: create-server-keypair
	@echo 'Creating a server csr in $(SERVER_CSR_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -certreq -keyalg RSA \
	-alias server -ext "$(SUBJECT_ALTERNATIVE_NAME)" > $(SERVER_CSR_NAME)
print-server-csr:
	keytool -printcertreq -file $(SERVER_CSR_NAME) -v

create-server-crt: create-server-csr
	@echo 'Creating a server crt in $(SERVER_CRT_NAME)'
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -gencert -keyalg RSA \
	-alias root -infile $(SERVER_CSR_NAME) -ext "$(SUBJECT_ALTERNATIVE_NAME)" > $(SERVER_CRT_NAME)
print-server-crt: $(SERVER_CRT_NAME)
	keytool -printcert -file $(SERVER_CRT_NAME) -v

export-root-pem-from-root-keystore: create-root-keypair
	@echo 'Exporting root pem from $(ROOT_KEYSTORE_NAME) to $(ROOT_PEM_NAME)'
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -exportcert -rfc -alias root > $(ROOT_PEM_NAME)
export-server-pem-from-server-keystore: create-server-crt
	@echo 'Exporting server pem from $(SERVER_KEYSTORE_NAME) to $(SERVER_PEM_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -exportcert -rfc -alias server > $(SERVER_PEM_NAME)

import-root-pem-to-server-keystore: export-root-pem-from-root-keystore
	@echo 'Importing $(ROOT_PEM_NAME) into $(SERVER_KEYSTORE_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -importcert -keyalg RSA \
	-alias root -file $(ROOT_PEM_NAME) -trustcacerts --noprompt

import-server-crt-to-server-keystore: create-server-crt
	@echo 'Importing $(SERVER_CRT_NAME) into $(SERVER_KEYSTORE_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -importcert -keyalg RSA \
	-alias server -file $(SERVER_CRT_NAME) -trustcacerts --noprompt

move-root-to-truststore: export-root-pem-from-root-keystore
	@echo 'Moving root alias from $(ROOT_KEYSTORE_NAME) into $(SERVER_TRUSTSTORE_NAME)'
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -export -alias root | \
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -import -alias root -trustcacerts -noprompt

move-server-to-truststore: export-server-pem-from-server-keystore
	@echo 'Moving server alias from $(SERVER_KEYSTORE_NAME) into $(SERVER_TRUSTSTORE_NAME)'
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -export -alias server | \
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -import -alias server -trustcacerts -noprompt

list-server-truststore:
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -list -v

osx-add-root-pem-to-keychain: $(ROOT_PEM_NAME)
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" $(ROOT_PEM_NAME)

osx-add-server-pem-to-keychain: $(SERVER_PEM_NAME)
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" $(SERVER_PEM_NAME)

osx-dump-keychain:
	sudo security dump-keychain "/System/Library/Keychains/SystemRootCertificates.keychain" | grep '$(CERT_COMMON_NAME)'

osx-find-root-cert:
	sudo security find-certificate -c '$(CERT_COMMON_NAME) RootCA' -Z "/Library/Keychains/System.keychain"

osx-find-server-cert:
	sudo security find-certificate -c 'localhost' -a -Z "/Library/Keychains/System.keychain"

osx-show-me-delete-certificate-cmd:
	echo 'sudo security delete-certificate -Z <sha-1-hash> "/Library/Keychains/System.keychain"'
