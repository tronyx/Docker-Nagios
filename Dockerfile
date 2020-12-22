FROM ubuntu:20.04

# Args
ARG VCS_REF
ARG BUILD_DATE

# Labels
LABEL maintainer="Tronyx <tronyx@tronflix.app>" \
    org.label-schema.name="tronyx/nagios" \
    org.label-schema.description="Dockerized Nagios Core" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.vcs-url="https://github.com/tronyx/Docker-Nagios/"

# Environment variables
ENV NAGIOS_HOME=/opt/nagios \
    NAGIOS_USER=nagios \
    NAGIOS_GROUP=nagios \
    NAGIOS_CMDUSER=nagios \
    NAGIOS_CMDGROUP=nagios \
    NAGIOS_FQDN=nagios.example.com \
    NAGIOSADMIN_USER=nagiosadmin \
    NAGIOSADMIN_PASS=nagios \
    APACHE_RUN_USER=nagios \
    APACHE_RUN_GROUP=nagios \
    NAGIOS_TIMEZONE=UTC \
    DEBIAN_FRONTEND=noninteractive \
    NG_NAGIOS_CONFIG_FILE=${NAGIOS_HOME}/etc/nagios.cfg \
    NG_CGI_DIR=${NAGIOS_HOME}/sbin \
    NG_WWW_DIR=${NAGIOS_HOME}/share/nagiosgraph \
    NG_CGI_URL=/cgi-bin \
    NAGIOS_BRANCH=nagios-4.4.6 \
    NAGIOS_PLUGINS_BRANCH=release-2.3.3 \
    NRPE_BRANCH=nrpe-4.0.2 \
    NSCA_TAG=nsca-2.10.0

RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections && \
    echo postfix postfix/mailname string ${NAGIOS_FQDN} | debconf-set-selections && \
    apt-get -qq update && apt-get -qq -y install software-properties-common && \
    add-apt-repository universe && \
    apt-get -qq -y install \
        apache2 \
        apache2-utils \
        autoconf \
        automake \
        bc \
        bsd-mailx \
        build-essential \
        dnsutils \
        fping \
        freetds-dev \
        gettext \
        git \
        gperf \
        iputils-ping \
        jq \
        libapache2-mod-php \
        libcache-memcached-perl \
        libcgi-pm-perl \
        libdbd-mysql-perl \
        libdbi-dev \
        libdbi-perl \
        libradsec-dev \
        libgd-dev \
        libgd-gd2-perl \
        libjson-perl \
        libldap2-dev \
        libmysqlclient-dev \
        libnagios-object-perl \
        libmonitoring-plugin-perl \
        libnet-snmp-perl \
        libnet-snmp-perl \
        libnet-tftp-perl \
        libnet-xmpp-perl \
        libpq-dev \
        libredis-perl \
        librrds-perl \
        libssl-dev \
        libswitch-perl \
        libwww-perl \
        m4 \
        netcat \
        parallel \
        php-cli \
        php-gd \
        postfix \
        python2 \
        python3-pip \
        python3-nagiosplugin \
        rsyslog \
        runit \
        smbclient \
        snmp \
        snmpd \
        snmp-mibs-downloader \
        unzip \
        python2 \
        xinetd && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

RUN ( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    ) && \
    ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    ) && \
    ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

# Reduce unecesssary git output
RUN git config --global advice.detachedHead false

RUN cd /tmp && \
    git clone https://github.com/multiplay/qstat.git && \
    cd qstat && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    make clean

RUN cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b ${NAGIOS_BRANCH} && \
    cd nagioscore && \
    ./configure \
        --prefix=${NAGIOS_HOME} \
        --exec-prefix=${NAGIOS_HOME} \
        --enable-event-broker \
        --with-command-user=${NAGIOS_CMDUSER} \
        --with-command-group=${NAGIOS_CMDGROUP} \
        --with-nagios-user=${NAGIOS_USER} \
        --with-nagios-group=${NAGIOS_GROUP} && \
    make all && \
    make install && \
    make install-config && \
    make install-commandmode && \
    make install-webconf && \
    make clean

RUN cd /tmp && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH && \
    cd nagios-plugins && \
    ./tools/setup && \
    ./configure \
        --prefix=${NAGIOS_HOME} \
        --with-ipv6 \
        --with-ping6-command="/bin/ping6 -n -U -W %d -c %d %s" && \
    make && \
    make install && \
    make clean && \
    mkdir -p /usr/lib/nagios/plugins && \
    ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins

RUN wget -O ${NAGIOS_HOME}/libexec/check_ncpa.py https://raw.githubusercontent.com/NagiosEnterprises/ncpa/v2.0.5/client/check_ncpa.py && \
    chmod +x ${NAGIOS_HOME}/libexec/check_ncpa.py

RUN cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b ${NRPE_BRANCH} && \
    cd nrpe && \
    ./configure \
        --with-ssl=/usr/bin/openssl \
        --with-ssl-lib=/usr/lib/$(uname -m)-linux-gnu && \
    make check_nrpe > /dev/null && \
    cp src/check_nrpe ${NAGIOS_HOME}/libexec/ && \
    make clean

RUN cd /tmp && \
    git clone https://git.code.sf.net/p/nagiosgraph/git nagiosgraph && \
    cd nagiosgraph && \
    ./install.pl --install \
        --prefix /opt/nagiosgraph \
        --nagios-user ${NAGIOS_USER} \
        --www-user ${NAGIOS_USER} \
        --nagios-perfdata-file ${NAGIOS_HOME}/var/perfdata.log \
        --nagios-cgi-url /cgi-bin && \
    cp share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi

RUN cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nsca.git && \
    cd nsca && \
    git checkout ${NSCA_TAG} && \
    ./configure \
        --prefix=${NAGIOS_HOME} \
        --with-nsca-user=${NAGIOS_USER} \
        --with-nsca-grp=${NAGIOS_GROUP} && \
    make all && \
    cp src/nsca ${NAGIOS_HOME}/bin/ && \
    cp src/send_nsca ${NAGIOS_HOME}/bin/ && \
    cp sample-config/nsca.cfg ${NAGIOS_HOME}/etc/ && \
    cp sample-config/send_nsca.cfg ${NAGIOS_HOME}/etc/

RUN cd /opt && \
    wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    pip install "pymssql<3.0" && \
    pip3 install pywbem && \
    git clone https://github.com/willixix/naglio-plugins.git WL-Nagios-Plugins && \
    git clone https://github.com/JasonRivers/nagios-plugins.git JR-Nagios-Plugins && \
    git clone https://github.com/justintime/nagios-plugins.git JE-Nagios-Plugins && \
    git clone https://github.com/nagiosenterprises/check_mssql_collection.git nagios-mssql && \
    chmod +x /opt/WL-Nagios-Plugins/check* && \
    chmod +x /opt/JE-Nagios-Plugins/check_mem/check_mem.pl && \
    cp /opt/JE-Nagios-Plugins/check_mem/check_mem.pl ${NAGIOS_HOME}/libexec/ && \
    cp /opt/nagios-mssql/check_mssql_database.py ${NAGIOS_HOME}/libexec/ && \
    cp /opt/nagios-mssql/check_mssql_server.py ${NAGIOS_HOME}/libexec/

RUN sed -i.bak 's/.*\=www\-data//g' /etc/apache2/envvars

RUN export DOC_ROOT="DocumentRoot $(echo ${NAGIOS_HOME}/share)" && \
    sed -i "s,DocumentRoot.*,${DOC_ROOT}," /etc/apache2/sites-enabled/000-default.conf && \
    sed -i "s,</VirtualHost>,<IfDefine ENABLE_USR_LIB_CGI_BIN>\nScriptAlias /cgi-bin/ ${NAGIOS_HOME}/sbin/\n</IfDefine>\n</VirtualHost>," /etc/apache2/sites-enabled/000-default.conf && \
    ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load

RUN mkdir -p -m 0755 /usr/share/snmp/mibs && \
    mkdir -p ${NAGIOS_HOME}/etc/conf.d && \
    mkdir -p ${NAGIOS_HOME}/etc/monitor && \
    mkdir -p -m 700  ${NAGIOS_HOME}/.ssh && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/.ssh && \
    touch /usr/share/snmp/mibs/.foo && \
    ln -s /usr/share/snmp/mibs ${NAGIOS_HOME}/libexec/mibs && \
    ln -s ${NAGIOS_HOME}/bin/nagios /usr/local/bin/nagios && \
    download-mibs && echo "mibs +ALL" > /etc/snmp/snmp.conf

RUN sed -i 's,/bin/mail,/usr/bin/mail,' ${NAGIOS_HOME}/etc/objects/commands.cfg && \
    sed -i 's,/usr/usr,/usr,' ${NAGIOS_HOME}/etc/objects/commands.cfg

RUN cp /etc/services /var/spool/postfix/etc/ && \
    echo "smtp_address_preference = ipv4" >> /etc/postfix/main.cf

ADD overlay /

RUN echo "use_timezone=${NAGIOS_TIMEZONE}" >> ${NAGIOS_HOME}/etc/nagios.cfg

# Copy example config in-case the user has started with empty var or etc
RUN mkdir -p /orig/var && \
    mkdir -p /orig/etc && \
    mkdir -p /orig/xinetd.d && \
    cp -Rp ${NAGIOS_HOME}/var/* /orig/var/ && \
    cp -Rp ${NAGIOS_HOME}/etc/* /orig/etc/ && \
    cp -Rp /etc/xinetd.d/* /orig/xinetd.d/

RUN a2enmod session && \
    a2enmod session_cookie && \
    a2enmod session_crypto && \
    a2enmod auth_form && \
    a2enmod request

# Make scripts executable
RUN chmod +x /usr/local/bin/start_nagios && \
    chmod +x /etc/sv/*/run && \
    chmod +x /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

RUN cd /opt/nagiosgraph/etc && \
    sh fix-nagiosgraph-multiple-selection.sh

#RUN rm -f /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

# Enable all runit services
RUN ln -s /etc/sv/* /etc/service

ENV APACHE_LOCK_DIR=/var/run \
    APACHE_LOG_DIR=/var/log/apache2

# Set ServerName and timezone for Apache
RUN echo "ServerName ${NAGIOS_FQDN}" > /etc/apache2/conf-available/servername.conf && \
    echo "PassEnv TZ" > /etc/apache2/conf-available/timezone.conf && \
    ln -s /etc/apache2/conf-available/servername.conf /etc/apache2/conf-enabled/servername.conf && \
    ln -s /etc/apache2/conf-available/timezone.conf /etc/apache2/conf-enabled/timezone.conf

# Cleanup
# Remove unecessary packages after install/setup are complete
RUN apt-get -qq -y autoremove && \
    apt-get -qq -y remove software-properties-common && \
    # Remove dirs from git clones
    cd /tmp && \
    rm -rf qstat \
    nagioscore \
    nagios-plugins \
    nrpe \
    nagiosgraph \
    nsca && \
    # Remove some other files and dirs
    rm -rf /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh \
    /opt/get-pip.py \
    /etc/rsyslog.d \
    /etc/rsyslog.conf \
    /etc/sv/getty-5

# Expose port 80 for the web UI
EXPOSE 80

# Specify volumes
VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "/var/log/apache2" "/opt/Custom-Nagios-Plugins" "/opt/nagiosgraph/var" "/opt/nagiosgraph/etc"

# Start command
CMD [ "/usr/local/bin/start_nagios" ]
