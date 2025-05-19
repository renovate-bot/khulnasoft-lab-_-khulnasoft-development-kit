localhost.crt: localhost.key

localhost.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${hostname}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt" -addext "subjectAltName=DNS:${hostname}"
	$(Q)chmod 600 $@
