FROM ubuntu:latest
LABEL Author="Bernardo Ballesteros" Description="Docker image with Ubuntu-PHP-Apache for GLPI" NAME="ubuntu-glpi"
# Stop dpkg-reconfigure tzdata from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

# Install apache and php
RUN apt-get update && \
    apt-get -y install \
        vim\
        jq\
        php-bz2\
        wget\
        curl\
        apache2 \
        mysql-client \ 
        libapache2-mod-php \
        libapache2-mod-auth-openidc \
        php-bcmath \
        php-cli \
        php-curl \
        php-mbstring \
        php-gd \
        php-mysql \
        php-json \
        php-ldap \
        php-memcached \
        php-mime-type \
        php-pgsql \
        php-tidy \
        php-intl \
        php-xmlrpc \
        php-soap \
        php-uploadprogress \
        php-zip \             
# Ensure apache can bind to 80 as non-root
        libcap2-bin && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2 && \
    dpkg --purge libcap2-bin && \
    apt-get -y autoremove && \
# As apache is never run as root, change dir ownership
    a2disconf other-vhosts-access-log && \
    chown -Rh www-data. /var/run/apache2 && \
# Install ImageMagick CLI tools
    apt-get -y install --no-install-recommends imagemagick && \
# Clean up apt setup files
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# Setup apache
    a2enmod rewrite headers expires ext_filter

# Override default apache and php config
COPY src/000-default.conf /etc/apache2/sites-available
COPY src/mpm_prefork.conf /etc/apache2/mods-available
COPY src/status.conf      /etc/apache2/mods-available
COPY src/99-local.ini     /etc/php/8.1/apache2/conf.d

# Expose details about this docker image
COPY src/index.php /var/www/html
# Files to setup glpi directories
COPY src/downstream.php /opt/downstream.php
COPY src/local_define.php /opt/local_define.php
#RUN mkdir /var/www/html/glpi
COPY glpi.sh /opt/
RUN chmod +x /opt/glpi.sh

#Change dir ownership
#RUN chown -R www-data:www-data /var/www


EXPOSE 80 443


ENTRYPOINT ["/opt/glpi.sh"]


