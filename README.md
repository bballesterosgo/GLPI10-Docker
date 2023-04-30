# Docker de GLPI para trabajo interno de TICgal



docker build -t ubuntu-glpi:ubuntu-glpi .

docker run --name=glpi -d -p 8081:80 --env "TIMEZONE=Europe/Brussels" --env "ID_ADMINER=12345" ubuntu-glpi:ubuntu-glpi 

# Variables de entorno

VERSION_GLPI
TIMEZONE
ID_ADMINER