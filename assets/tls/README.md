# Manually Generate Private Keys and Certificates

Generate self-signed CA key and certificate.

```sh
$ certtool --generate-privkey > cakey.pem
$ certtool --generate-self-signed \
           --load-privkey cakey.pem \
           --template ca.info \
           --outfile cacert.pem
```

Generate OpenLDAP server key and certificate.

```sh
$ certtool --generate-privkey > ldapkey.pem
$ certtool --generate-certificate --load-privkey ldapkey.pem \
           --load-ca-privkey cakey.pem \
           --load-ca-certificate cacert.pem \
           --template ldap.info \
           --outfile ldapcert.pem
```

