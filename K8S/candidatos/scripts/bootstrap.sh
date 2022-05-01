#!/bin/bash

# ESTE SCRIPT SE ENCARGA DE:
#
#  1.- CLONAR EL REPOSITORIO QUE CONTIENE EL CODIGO FUENTE DE LA APP.
#
#  2.- INSTALAR PAQUETERÍA NECESARIA PARA MANIPULAR TEXTOS EN LA SHELL.
#
#  3.- EJECUTAR EL SCRIPT QUE REALIZA EL CAMBIO DE VARIABLES PARA LA PERSISTENCIA DE LA APP JAVA.
#
#  4.- COMPILAR Y EMPAQUETAR LA APP EN FORMARTO .WAR PARA SER CONSUMIDO POR EL SERVIDOR DE APLICACIONES TOMCAT.
#
#  5.- COPIAR EL FICHERO .WAR DEL DEPLOY DE TOMCAT A UN DIRECTORIO MONTADO EN VOLUMEN PARA USO DEL CONTENEDOR DE LA APP.


until
 git clone $REPO_GITHUB /app_java_temp
do 
 echo Esperando a clonar el respositorio de GitHub...
 sleep 2
done
 apt update
 apt install -y gettext
 sh /scripts/script_variables.sh
 mvn clean package
 mkdir /app_java_temp/deploy
 cp /app_java_temp/target/17_gestion_candidatos_mvc-0.0.1-SNAPSHOT.war /app_java_temp/deploy/gestion-candidatos.war
 

exit 0