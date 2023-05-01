#!/bin/bash

##Version choice control or taking the latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset";
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/cli/conf.d/timezone.ini;
fi

SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
TAR_GLPI=$(basename ${SRC_GLPI})
FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/
FOLDER_TICGAL=/TICgal/
FOLDER_FILES=/var/lib/glpi
FOLDER_CONFIG=/etc/glpi



#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

#Downloading and extracting GLPI sources
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
else
  #Download and unzip GLPI
	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB} &&
  #Delete compresed glpi file
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
  #Download adminer
  mkdir -p ${FOLDER_WEB}${FOLDER_GLPI}${FOLDER_TICGAL}
  wget https://www.adminer.org/latest-en.php -P ${FOLDER_WEB}${FOLDER_GLPI}/public${FOLDER_TICGAL}
  #Rename adminer with TAG
  mv ${FOLDER_WEB}${FOLDER_GLPI}/public${FOLDER_TICGAL}latest-en.php ${FOLDER_WEB}${FOLDER_GLPI}${FOLDER_TICGAL}adminer-${ID_ADMINER}.php
  #Move glpi files
  mkdir ${FOLDER_CONFIG}
  mkdir ${FOLDER_FILES}
  mv /opt/downstream.php ${FOLDER_WEB}${FOLDER_GLPI}/inc/downstream.php &&
  mv /opt/local_define.php ${FOLDER_CONFIG}/local_define.php && 
  mv  ${FOLDER_WEB}${FOLDER_GLPI}/files/* ${FOLDER_FILES} &&
  chown -R www-data:www-data ${FOLDER_WEB}
  # perform GLPI installation
  php /var/www/glpi/bin/console -n db:install -H mariadb -d $MARIADB_DATABASE -u $MARIADB_USER -p $MARIADB_PASSWORD &&
  #Delete install file
  rm ${FOLDER_WEB}${FOLDER_GLPI}/install/install.php
  # #change dir ownership
   chmod -R 0500 ${FOLDER_WEB}${FOLDER_GLPI}
   chmod -R 0700 ${FOLDER_CONFIG}
   chmod 0400 ${FOLDER_CONFIG}/config_db.php
   chmod -R 0700 ${FOLDER_FILES}
   chmod -R 0700 ${FOLDER_WEB}${FOLDER_GLPI}/marketplace
	 chown -R www-data:www-data ${FOLDER_WEB}
   chown -R www-data:www-data ${FOLDER_CONFIG}
   chown -R www-data:www-data ${FOLDER_FILES}

  
  #Deactivate other users
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE -e 'UPDATE `glpi_users` SET `is_active` = '0' WHERE (`id` = '3') OR (`id` = '4') OR (`id` = '5'));'
  #Automatic Task CLI Mode.
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE  -e 'UPDATE `glpi_crontasks` SET `mode` = '2';'
  #read access to the mysql.time_zone_name table
  mysql -h mariadb -u root -p$MARIADB_ROOT_PASSWORD $MARIADB_DATABASE  -e 'GRANT SELECT ON `mysql`.`time_zone_name` TO 'glpirw'@'%';'
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_ROOT_PASSWORD $MARIADB_DATABASE  -e 'FLUSH PRIVILEGES;'

  #Migration timestamps
  cd ${FOLDER_WEB}${FOLDER_GLPI}
  php bin/console glpi:migration:timestamps

  #Dowload and install plugins.
  cd ${FOLDER_WEB}${FOLDER_GLPI}/plugins
  ##TAM##
  wget https://gitlab.com/ticgalpublic/tam/-/archive/1.4.3/tam-1.4.3.tar.gz  ##No hay realease aún, 
  tar -xzvf tam-1.4.3.tar.gz
  php ../bin/console -n glpi:plugin:install -u glpi tam
  

  #Activate all plugins
  php ../bin/console -n plugin:activate *

  




fi

#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Enable apache rewrite module
a2enmod rewrite && service apache2 restart && service apache2 stop

#Launch the apache service in the foreground
/usr/sbin/apache2ctl -D FOREGROUND