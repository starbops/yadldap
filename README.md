# Yet Another Docker Image with OpenLDAP Server

Using OpenLDAP server as central authentication workstation environment FTW!
The TLS version is also available (by default enabled).

## Usage

To ssh into the box, one must put the public key using the name of `key.pub`
right under project root directory:

```
$ cd ${HOME}/yadldap
$ tree
.
├── assets
│   ├── conf
│   │   └── ldapscripts.conf
│   ├── ldif
│   │   └── tls.ldif
│   └── tls
│       ├── ca.info
│       ├── ldap.info
│       └── README.md
├── Dockerfile
├── key.pub
├── install
├── kickstart.sh
├── README.md
└── slapd.sh
```

Build the Docker image:

```
$ docker build -t <image> .
```

Give it a shot!

```
$ docker run --rm -it -h <hostname> <image>:<version> /sbin/my_init -- bash -l
```

Also we support three kinds of environment variables now.

1. `LDAP_ADMIN_PASSWORD`
2. `LDAP_DOMAIN`
3. `LDAP_ORGANIZATION`

The following is an example:

```
$ docker run -d -h <hostname> --name ldap -e LDAP_ADMIN_PASSWORD=<password> -e LDAP_DOMAIN=<domain> -e LDAP_ORGANIZATION=<organization> <image>:<version> /sbin/my_init
```

To query the OpenLDAP server, please use `ldapsearch`:

```
$ ldapsearch -x -H ldaps://<contain_ip> -b "dc=example,dc=com" -D "cn=admin,dc=example,dc=com" -w <password>
```

## Caveat

The hostname of the docker container must be set in order to auto-generate the
private keys and certificates.

