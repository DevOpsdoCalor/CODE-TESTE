# From https://github.com/grpc/grpc-java/tree/master/testing/src/main/resources/certs
#The ca is self-signed:
#----------------------

openssl req -x509 -new -newkey rsa:4096 -nodes -keyout ca-key.pem -out ca-cert.pem -config ca-openssl.cnf -days 3650 -extensions v3_req
# When prompted for certificate information, everything is default.

# cert is issued by CA:
#-----------------------

openssl genrsa -out client.key.rsa 4096
openssl pkcs8 -topk8 -in client.key.rsa -out key.pem -nocrypt
openssl req -new -key key.pem -out client.csr

#When prompted for certificate information, everything is default except the
#common name which is set to psp.

openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -in client.csr -out cert.pem -days 3650

#Clean up:
#---------
rm *.rsa
rm *.csr
