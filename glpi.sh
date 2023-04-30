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
FOLDER_CONFIG=/ect/glpi


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
  mv /opt/local_define.php ${FOLDER_WEB}/glpi_config/local_define.php && 
  mv  ${FOLDER_WEB}${FOLDER_GLPI}/files/* ${FOLDER_WEB}/glpi_files &&
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
  #Create ticgal user
  
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE -e 'INSERT INTO `glpi_users` (`id`, `name`, `password`, `password_last_update`, `phone`, `phone2`, `mobile`, `realname`, `firstname`, `locations_id`, `language`, `use_mode`, `list_limit`, `is_active`, `comment`, `auths_id`, `authtype`, `last_login`, `date_mod`, `date_sync`, `is_deleted`, `profiles_id`, `entities_id`, `usertitles_id`, `usercategories_id`, `date_format`, `number_format`, `names_format`, `csv_delimiter`, `is_ids_visible`, `use_flat_dropdowntree`, `show_jobs_at_login`, `priority_1`, `priority_2`, `priority_3`, `priority_4`, `priority_5`, `priority_6`, `followup_private`, `task_private`, `default_requesttypes_id`, `password_forget_token`, `password_forget_token_date`, `user_dn`, `registration_number`, `show_count_on_tabs`, `refresh_views`, `set_default_tech`, `personal_token`, `personal_token_date`, `api_token`, `api_token_date`, `cookie_token`, `cookie_token_date`, `display_count_on_home`, `notification_to_myself`, `duedateok_color`, `duedatewarning_color`, `duedatecritical_color`, `duedatewarning_less`, `duedatecritical_less`, `duedatewarning_unit`, `duedatecritical_unit`, `display_options`, `is_deleted_ldap`, `pdffont`, `picture`, `begin_date`, `end_date`, `keep_devices_when_purging_item`, `privatebookmarkorder`, `backcreated`, `task_state`, `palette`, `page_layout`, `fold_menu`, `fold_search`, `savedsearches_pinned`, `timeline_order`, `itil_layout`, `richtext_layout`, `set_default_requester`, `lock_autolock_mode`, `lock_directunlock_notification`, `date_creation`, `highcontrast_css`, `plannings`, `sync_field`, `groups_id`, `users_id_supervisor`, `timezone`, `default_dashboard_central`, `default_dashboard_assets`, `default_dashboard_helpdesk`, `default_dashboard_mini_ticket`, `default_central_tab`, `nickname`) VALUES (7,	'TICgal',	'$2y$10$xNI55RgtV4ScFV43cvBza.2iV1tqWgGtguADLux/nyILmAQqXVFHm',	'2022-05-15 10:41:37',	'986101000',	'',	'',	'',	'Soporte TICgal',	0,	NULL,	0,	NULL,	1,	'',	0,	1,	NULL,	'2022-05-15 10:41:37',	NULL,	0,	0,	0,	0,	0,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'2022-05-15 10:41:37',	0,	NULL,	NULL,	0,	0,	'0',	NULL,	NULL,	NULL,	NULL,	0,	NULL);'
  #Deactivate other users
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE -e 'UPDATE `glpi_users` SET `is_active` = '0' WHERE ((`id` = '2') OR (`id` = '3') OR (`id` = '4') OR (`id` = '5'));'
  #Automatic Task CLI Mode.
  mysql -h mariadb -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE  -e 'UPDATE `glpi_crontasks` SET `mode` = '2';'

  #Dowload and install plugins.
  cd ${FOLDER_WEB}${FOLDER_GLPI}/plugins
  ##TAM##
  wget https://gitlab.com/ticgalpublic/tam/-/archive/1.4.3/tam-1.4.3.tar.gz
  tar -xzvf tam-1.4.3.tar.gz
  php ../bin/console -n glpi:plugin:install -u ticgal tam
  

  #Activate all plugins
  php ${FOLDER_WEB}${$FOLDER_GLPI}/bin/console -n plugin:activate *

  




fi

#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Enable apache rewrite module
a2enmod rewrite && service apache2 restart && service apache2 stop

#Launch the apache service in the foreground
/usr/sbin/apache2ctl -D FOREGROUND