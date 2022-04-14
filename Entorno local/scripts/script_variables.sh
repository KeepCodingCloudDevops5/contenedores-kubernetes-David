#!/bin/bash

# ESTE SCRIPT REALIZARÁ UN CAMBIO DE VARIABLES EN LOS FICHEROS DE CONFIGURACIÓN DE LA PERSISTENCIA DE JAVA EE,
# PARA DOTAR DE AUTOMATISMO Y PERSONALIZACIÓN EN CUANTO A LOS VALORES CORRESPONDIENTES A LA BASE DE DATOS:

XML_TMP=./WEB-INF/classes/META-INF/persistence_temp.xml
XML_OUT=./WEB-INF/classes/META-INF/persistence.xml

#SERVIDOR=$DB_SERVER
#PUERTO=$DB_PORT
#BD=$BBDD
#ZONE=$DB_TIMEZONE

#export DB_URL="jdbc:mysql://$SERVIDOR:$PUERTO/$BD?serverTimezone=$ZONE"
#export DB_USER="root"
#export DB_PASS="r00t"
#export DB_DRIVER="com.mysql.cj.jdbc.Driver"

envsubst "`printf '${%s} ' $(sh -c "env|cut -d'=' -f1")`" < $XML_TMP > $XML_OUT

echo ""
echo "************************************************************************"
echo "Script de automatización de variables BBDD SQL finalizado correctamente"
echo "************************************************************************"
echo ""

exit 0