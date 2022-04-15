#!/bin/bash

# ESTE SCRIPT REALIZARÁ UN CAMBIO DE VARIABLES EN LOS FICHEROS DE CONFIGURACIÓN DE LA PERSISTENCIA DE JAVA EE,
# PARA DOTAR DE AUTOMATISMO Y PERSONALIZACIÓN EN CUANTO A LOS VALORES CORRESPONDIENTES A LA BASE DE DATOS:

XML_TMP=./WEB-INF/classes/META-INF/persistence_temp.xml
XML_OUT=./WEB-INF/classes/META-INF/persistence.xml

envsubst "`printf '${%s} ' $(sh -c "env|cut -d'=' -f1")`" < $XML_TMP > $XML_OUT

echo ""
echo "************************************************************************"
echo "Script de automatización de variables BBDD SQL finalizado correctamente"
echo "************************************************************************"
echo ""

exit 0