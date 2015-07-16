FROM phusion/baseimage:0.9.16
MAINTAINER Zespre Schmidt <starbops@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Set up sshd.
RUN rm -f /etc/service/sshd/down && /etc/my_init.d/00_regen_ssh_host_keys.sh
COPY key.pub /tmp/key.pub
RUN cat /tmp/key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/key.pub

# Add openldap user and group.
RUN groupadd -r openldap && useradd -r -g openldap openldap

# Install OpenLDAP, and remove default database.
RUN apt-get -y update && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y \
        slapd \
        ldap-utils \
        gnutls-bin \
        ldapscripts \
        ntp \
        && rm -rf /var/lib/ldap /etc/ldap/slapd.d

# Default environment variables.
ENV LDAP_ADMIN_PASSWORD=admin \
    LDAP_DOMAIN=example.com \
    LDAP_ORGANIZATION=Example

# initialization scripts.
COPY assets /build/assets
COPY scripts /build/scripts
COPY install /build/install
RUN /build/install

# Expose service ports.
EXPOSE 22 389 636

# Set up OpenLDAP database and config directory in data volume.
VOLUME ["/var/lib/ldap", "/etc/ldap/slapd.d", "/build/assets/private", "/build/assets/certs"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
