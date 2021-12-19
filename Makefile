# Mental Model:
# - The 'root' keystore serves as a mini Certificate Authority (CA)
# - The 'server' keystore and truststore serve as the Java keystore and truststore, respectively, to use for a webserver
# - The goal is to create a CA Root Certificate and a server Certificate, signed by that CA (both managed as PEM files).

# Once we have the certificates, we can:
# - Load the server private key and server certificate into the keystore to allow the server to serve requests
# - Load the root and server certificates into the truststore so the server will trust them
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
CERT_CITY?=Boston
CERT_STATE?=MA
CERT_COUNTRY?=US
# If you provide more DNS values, make sure to update /etc/hosts!
SUBJECT_ALTERNATIVE_NAME=SAN=DNS:localhost,DNS:keytool-local-trust

SERVER_CSR_NAME=server.csr
SERVER_CRT_NAME=server.crt
SERVER_PEM_NAME=server.pem

# https://www.linuxcommand.org/lc3_adv_tput.php
# tput setaf <fg_color> - used to set foreground color
# tput sgr0 - used to reset
Blue := $(shell tput setaf 69)
Red := $(shell tput setaf 1)
Green := $(shell tput setaf 2)
Yellow := $(shell tput setaf 3)
Orange := $(shell tput setaf 214)
None := $(shell tput sgr0)

.PHONY: all create-root-keypair create-server-keypair

all: move-root-to-truststore move-server-to-truststore
	@echo "$(Blue)Done populating $(SERVER_KEYSTORE_NAME) and $(SERVER_TRUSTSTORE_NAME).$(None)"
	@echo "They should be ready to copy to the resources directory of a project, and to be used as the keystore and truststore, respectively."
	@echo "$(Green)Try 'make list-root-keystore', 'make list-server-keystore', and 'make list-server-truststore' to see the contents of the keystores."
	@echo "Try 'make osx-add-root-pem-to-keychain' and 'make osx-add-server-pem-to-keychain' to add the root and server certificates to your OSX keychain.$(None)"

color-check: tput-check

tput-check:
	@echo "$(Blue)This should be blue$(None)"
	@echo "$(Green)This should be green$(None)"
	@echo "$(Yellow)This should be yellow$(None)"
	@echo "$(Orange)This should be orange$(None)"
	@echo "$(Red)This should be red$(None)"
	@echo "This should be the default"

tput-colors:
	@echo "$(Blue)Displaying tput color options$(None)"
	@scripts/tput-colors.sh

clean:
	@echo "$(Red)Removing all local keystore/truststore and certificate files$(None)"
	rm -f $(ROOT_KEYSTORE_NAME) $(SERVER_KEYSTORE_NAME) $(SERVER_TRUSTSTORE_NAME) \
	$(ROOT_PEM_NAME) \
	$(SERVER_CSR_NAME) $(SERVER_CRT_NAME) $(SERVER_PEM_NAME)
	@echo "$(Yellow)Don't forget to delete the system certificates, if you added them!"
	@echo "Try 'make osx-find-root-cert', 'make osx-find-server-cert', and 'osx-show-me-delete-certificate-cmd'$(None)"

ensure-root-keypair:
	@echo "$(Blue)Ensuring root keypair$(None)"
	@KEYSTORE_NAME=$(ROOT_KEYSTORE_NAME) \
	KEYSTORE_PASSWORD=$(ROOT_KEYSTORE_PASSWORD) \
	ALIAS=root scripts/ensure-keypair.sh

ensure-server-keypair:
	@echo "$(Blue)Ensuring server keypair$(None)"
	@KEYSTORE_NAME=$(SERVER_KEYSTORE_NAME) \
	KEYSTORE_PASSWORD=$(SERVER_KEYSTORE_PASSWORD) \
	ALIAS=server scripts/ensure-keypair.sh

# This command will also create the root keystore file
create-root-keypair:
	@echo "$(Blue)Creating root keypair in $(ROOT_KEYSTORE_NAME)$(None)"
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -deststoretype pkcs12 -genkeypair -keyalg RSA \
	-alias root -dname "cn=$(CERT_COMMON_NAME) RootCA, ou=$(CERT_COMMON_NAME) Root_CertificateAuthority, o=CertificateAuthority, c=$(CERT_COUNTRY)"
$(ROOT_KEYSTORE_NAME): ensure-root-keypair
	@echo "$(Blue)Ensured $(ROOT_KEYSTORE_NAME)$(None)"

list-root-keystore:
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -list -v
remove-root-from-root-keystore:
	@echo "$(Red)Removing root alias from $(ROOT_KEYSTORE_NAME)$(None)"
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -delete -alias root

# This command will also create the server keystore file
create-server-keypair:
	@echo "$(Blue)Creating server keypair in $(SERVER_KEYSTORE_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -deststoretype pkcs12 -genkeypair -keyalg RSA \
	-validity 395 -keysize 2048 -sigalg SHA256withRSA \
	-alias server -dname "CN=localhost,O=$(CERT_COMMON_NAME),OU=$(CERT_COMMON_NAME),L=$(CERT_CITY),ST=$(CERT_STATE),C=$(CERT_COUNTRY)" -ext "$(SUBJECT_ALTERNATIVE_NAME)"
$(SERVER_KEYSTORE_NAME): ensure-server-keypair
	@echo "$(Blue)Ensured $(SERVER_KEYSTORE_NAME)$(None)"

list-server-keystore:
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -list -v

create-server-csr: ensure-server-keypair
	@echo "$(Blue)Creating a server csr in $(SERVER_CSR_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -certreq -keyalg RSA \
	-alias server -ext "$(SUBJECT_ALTERNATIVE_NAME)" > $(SERVER_CSR_NAME)
print-server-csr:
	keytool -printcertreq -file $(SERVER_CSR_NAME) -v

create-server-crt: $(ROOT_KEYSTORE_NAME) create-server-csr
	@echo "$(Blue)Creating a server crt in $(SERVER_CRT_NAME)$(None)"
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -gencert -keyalg RSA -rfc \
	-alias root -infile $(SERVER_CSR_NAME) -ext "$(SUBJECT_ALTERNATIVE_NAME)" > $(SERVER_CRT_NAME)
print-server-crt: $(SERVER_CRT_NAME)
	keytool -printcert -file $(SERVER_CRT_NAME) -v

export-root-pem-from-root-keystore: $(ROOT_KEYSTORE_NAME) ensure-root-keypair
	@echo "$(Blue)Exporting root pem from $(ROOT_KEYSTORE_NAME) to $(ROOT_PEM_NAME)$(None)"
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -exportcert -rfc -alias root > $(ROOT_PEM_NAME)
export-server-pem-from-server-keystore: $(ROOT_KEYSTORE_NAME) $(SERVER_KEYSTORE_NAME) ensure-root-keypair ensure-server-keypair create-server-crt import-server-crt-to-server-keystore
	@echo "$(Blue)Exporting server pem from $(SERVER_KEYSTORE_NAME) to $(SERVER_PEM_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -exportcert -rfc -alias server > $(SERVER_PEM_NAME)

import-root-pem-to-server-keystore: $(ROOT_KEYSTORE_NAME) $(SERVER_KEYSTORE_NAME) export-root-pem-from-root-keystore
	@echo "$(Blue)Importing $(ROOT_PEM_NAME) into $(SERVER_KEYSTORE_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -importcert -keyalg RSA \
	-alias root -file $(ROOT_PEM_NAME) -trustcacerts --noprompt

import-server-crt-to-server-keystore: $(ROOT_KEYSTORE_NAME) $(SERVER_KEYSTORE_NAME) create-server-crt import-root-pem-to-server-keystore
	@echo "$(Blue)Importing $(SERVER_CRT_NAME) into $(SERVER_KEYSTORE_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -importcert -keyalg RSA \
	-alias server -file $(SERVER_CRT_NAME) -trustcacerts --noprompt

move-root-to-truststore: export-root-pem-from-root-keystore
	@echo "$(Blue)Moving root alias from $(ROOT_KEYSTORE_NAME) into $(SERVER_TRUSTSTORE_NAME)$(None)"
	keytool -keystore $(ROOT_KEYSTORE_NAME) -storepass $(ROOT_KEYSTORE_PASSWORD) -export -alias root | \
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -import -alias root -trustcacerts -noprompt

move-server-to-truststore: export-server-pem-from-server-keystore
	@echo "$(Blue)Moving server alias from $(SERVER_KEYSTORE_NAME) into $(SERVER_TRUSTSTORE_NAME)$(None)"
	keytool -keystore $(SERVER_KEYSTORE_NAME) -storepass $(SERVER_KEYSTORE_PASSWORD) -export -alias server | \
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -import -alias server -trustcacerts -noprompt

list-server-truststore:
	keytool -keystore $(SERVER_TRUSTSTORE_NAME) -storepass $(SERVER_TRUSTSTORE_PASSWORD) -list -v

# ===== OSX specific stuff =====
# See https://ss64.com/osx/security.html for more information

osx-add-root-pem-to-keychain: $(ROOT_PEM_NAME)
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" $(ROOT_PEM_NAME)

osx-add-server-pem-to-keychain: $(SERVER_PEM_NAME)
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" $(SERVER_PEM_NAME)

osx-find-root-cert:
	sudo security find-certificate -c '$(CERT_COMMON_NAME) RootCA' -Z "/Library/Keychains/System.keychain"

osx-find-server-cert:
	sudo security find-certificate -c 'localhost' -a -Z "/Library/Keychains/System.keychain"

osx-show-me-delete-certificate-cmd:
	echo 'sudo security delete-certificate -Z <sha-1-hash> "/Library/Keychains/System.keychain"'
