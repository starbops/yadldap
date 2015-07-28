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
│   ├── templates
│   │   └── ldapscripts.adduser.template
│   └── tls
│       ├── ca.info
│       ├── ldap.info
│       └── README.md
├── Dockerfile
├── install
├── key.pub
├── LICENSE
├── README.md
└── scripts
    ├── kickstart.sh
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
$ docker run -d -h <hostname> --name ldap \
    -e LDAP_ADMIN_PASSWORD=<password> \
    -e LDAP_DOMAIN=<domain> \
    -e LDAP_ORGANIZATION=<organization> \
    <image>:<version> /sbin/my_init
```

To query the OpenLDAP server, please use `ldapsearch`:

```
$ ldapsearch -x -H ldaps://<contain_ip> -b "dc=example,dc=com" -D "cn=admin,dc=example,dc=com" -w <password>
```

## Persistent Database

Although the information in the directory will remain while restarting of the
container, it will be lost one the container is deleted. To maintain the
database and config directory persistently, one should use Docker volume. There
are 4 location that store different information:

1. `/var/lib/ldap`: database
2. `/etc/ldap/slapd.d`: config
3. `/build/assets/private`: private keys
4. `/build/assets/certs`: certificates

```
$ docker run -d -h <hostname> --name ldap \
    -e LDAP_ADMIN_PASSWORD=<passwd> \
    -e LDAP_DOMAIN=<domain> \
    -e LDAP_ORGANIZATION=<organization> \
    -v /docker/ldap/database:/var/lib/ldap \
    -v /docker/ldap/config:/etc/ldap/slapd.d \
    -v /docker/ldap/private:/build/assets/private \
    -v /docker/ldap/certs:/build/assets/certs \
    starbops/yadldap:0.1 /sbin/my_init
```

It's highly recommended use `-v /etc/localtime:/etc/localtime:ro` to sync the
time in container with host.

## Caveat

The hostname of the docker container must be set in order to auto-generate the
private keys and certificates.

