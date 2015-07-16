#!/bin/sh -e

ulimit -n 1024

gen_tls_files () {
    local CAINFO=$1
    local CAKEY=$2
    local CACERT=$3
    local LDAPINFO=$4
    local LDAPKEY=$5
    local LDAPCERT=$6

    certtool --generate-privkey > ${CAKEY}
    certtool --generate-self-signed \
             --load-privkey ${CAKEY} \
             --template ${CAINFO} \
             --outfile ${CACERT}
    certtool --generate-privkey > ${LDAPKEY}
    certtool --generate-certificate --load-privkey ${LDAPKEY} \
             --load-ca-privkey ${CAKEY} \
             --load-ca-certificate ${CACERT} \
             --template ${LDAPINFO} \
             --outfile ${LDAPCERT}

    chmod 600 ${CAKEY}
    chmod 644 ${CACERT}
    chmod 600 ${LDAPKEY}
    chmod 644 ${LDAPCERT}
}

get_base_dn () {
    BASE_DN=""
    IFS='.'

    for i in ${LDAP_DOMAIN}; do
        j="dc=${i},"
        BASE_DN=${BASE_DN}${j}
    done

    BASE_DN=${BASE_DN%,}
}

set_ldapscripts () {
    get_base_dn
    sed -i "s/{{ BASE_DN }}/${BASE_DN}/g" /build/assets/conf/ldapscripts.conf

    [ -f /etc/ldapscripts/ldapscripts.conf ] \
        && mv /etc/ldapscripts/ldapscripts.conf /etc/ldapscripts/ldapscripts.conf.ori
    ln -s /build/assets/conf/ldapscripts.conf /etc/ldapscripts/ldapscripts.conf
    echo -n ${LDAP_ADMIN_PASSWORD} > /etc/ldapscripts/ldapscripts.passwd
    chmod 400 /etc/ldapscripts/ldapscripts.passwd
}

# fix file permission
chown -R openldap:openldap /var/lib/ldap
chown -R openldap:openldap /etc/ldap
chown -R openldap:openldap /build

/etc/init.d/ntp restart

BOOTSTRAP=1 # false

if [ -z "$(ls -A /var/lib/ldap)" ] && [ -z "$(ls -A /etc/ldap/slapd.d)" ]; then
    BOOTSTRAP=0 # true
    echo "databases and config directory are empty"
    echo "-> bootstrapping config"
    cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/internal/adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANIZATION}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF
    dpkg-reconfigure -f noninteractive slapd
elif [ -z "$(ls -A /var/lib/ldap)" ] && [ ! -z "$(ls -A /etc/ldap/slapd.d)" ]; then
    echo "Error: /var/lib/ldap is empty"
    exit 1
elif [ ! -z "$(ls -A /var/lib/ldap)" ] && [ -z "$(ls -A /etc/ldap/slapd.d)" ]; then
    echo "Error: /etc/ldap/slapd.d is empty"
    exit 1
else

    echo "Warning: using existing database and config directory"

    # setup ldapscripts for convenience
    set_ldapscripts

    # OpenLDAP client config
    echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf

fi

if [ ${BOOTSTRAP} -eq 0 ]; then
    # if it is bootstrap

    # start OpenLDAP
    echo "kickstart openldap..."
    /usr/sbin/slapd -h "ldap:/// ldapi:///" -u openldap -g openldap
    echo "done"

    # set up TLS
    sed -i "s/{{ ORGANIZATION_NAME }}/${LDAP_ORGANIZATION}/g" /build/assets/tls/ca.info
    sed -i "s/{{ ORGANIZATION_NAME }}/${LDAP_ORGANIZATION}/g" /build/assets/tls/ldap.info
    sed -i "s/{{ HOSTNAME }}/${HOSTNAME}/g" /build/assets/tls/ldap.info
    gen_tls_files \
        /build/assets/tls/ca.info \
        /build/assets/private/cakey.pem \
        /build/assets/certs/cacert.pem \
        /build/assets/tls/ldap.info \
        /build/assets/private/ldapkey.pem \
        /build/assets/certs/ldapcert.pem

    ldapmodify -Y EXTERNAL -H "ldapi:///" -f /build/assets/ldif/tls.ldif
    chown -R openldap:openldap /build

    # OpenLDAP client config
    echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf

    # Construct basic directory
    set_ldapscripts
    ldapinit -s

    # stop OpenLDAP
    kill -INT `cat /run/slapd/slapd.pid`
fi

exit 0
