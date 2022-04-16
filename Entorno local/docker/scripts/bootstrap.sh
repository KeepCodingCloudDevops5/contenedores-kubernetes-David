#!/bin/bash

# ESTE SCRIPT SE ENCARGA DE:
#
#  1.- EJECUTAR EL SCRIPT QUE REALIZARÁ EL CAMBIO DE VARIABLES PARA EL FICHERO persistence.xml
#
#  2.- Dormir durante 20 segundos mientras en la primera ejecución del contenedor docker se 
#      configura el servicio de mySQL, ya que al ser la primera vez, quizás no exista el volúmen
#      de datos en docker.
#
#  3.- Una vez finalizado el tiempo de desplegar el servicio mysql, desde el contenedor candidatos
#      se realiza una conexión a la BBDD que está en el contenedor mysql para inyectarle desde fichero
#      la sentencias SQL necesarias para crear el schema junto con la tabla y los atributos correspondientes.
#
#      Los valores de la contraseña de root, el nombre del servidor y el puerto a utilizar, son obtenidos
#      mediante variables de entorno configuradas desde el fichero de variables web.env de docker-compose.
#
#      La conexión al servidor de base de datos desde el contenedor de la aplicación, se puede llevar a cabo
#      gracias a la conexión TCP/IP que existe dentro de la misma red que Docker ha creado al levantar los
#      servicios desde docker-compose, y que permite visibilidad DNS también a nivel de nombre de contenedor,
#      pudiendo así establecer una conexión.
#
#  4.- Terminada de realizar la carga de datos, se ejecuta el script catalina.sh que se encargará de desplegar
#      la App en el servidor de aplicaciones Tomcat.

sh /usr/local/tomcat/webapps/gestion-candidatos/scripts/script_variables.sh

echo ""
echo "********20 SEGUNDOS DE ESPERA MIENTRAS SE TERMINA DE EJECUTAR EL SERVIDOR DE MYSQL... ANTES DE LA CARGA DE DATOS********"
echo ""

sleep 20

echo ""
echo "********R E A L I Z A N D O   C A R G A   D E   D A T O S********"
echo 

mysql -u root -p$DB_PASS -h $DB_SERVER -P $DB_PORT --default-character-set=utf8 -D empresa < /mysql/bbdd_empresa.sql -f

echo ""
echo "**************************************************"
echo "Carga de datos en la BBDD finalizado correctamente"
echo "**************************************************"
echo ""

catalina.sh run

exit 0