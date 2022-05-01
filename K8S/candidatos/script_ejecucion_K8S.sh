#!/bin/bash

# Se define la creación de un NameSpace llamado acme dentro del cluster, para separar los recursos a crear del resto del cluster:
kubectl create ns acme

# Se define la creación de un ConfigMap para ser usado por la bbdd, con origen un archivo de propiedades,
# cuya Key será cada propiedad de dicho archivo:
kubectl -n acme create configmap acme-bbdd-sql --from-env-file=resources/bbdd.properties


# Se define la creación de un ConfigMap que contiene el fichero de la creación del schema y carga de datos de la BBDD:
kubectl -n acme create configmap acme-bbdd-empresa --from-file=resources/bbdd_empresa.sql


# Se define la creación de un ConfigMap para ser usado por la App, con origen un archivo de propiedades,
# cuya Key será cada propiedad de dicho archivo:
kubectl -n acme create configmap acme-app-candidatos --from-env-file=resources/app.properties


# Se define la creación de un ConfigMap que contienen los ficheros de los scripts de la App:
kubectl -n acme create configmap acme-scripts --from-file=scripts/bootstrap.sh --from-file=scripts/script_variables.sh


#Se define la creación de un secret literal para los secretos de la BBDD:
kubectl -n acme create secret generic acme-bbdd \
--from-literal=MYSQL_ROOT_USER=root \
--from-literal=MYSQL_ROOT_PASSWORD=r00t \
--from-literal=MYSQL_USER=kc-java \
--from-literal=MYSQL_PASSWORD=candidatosKC


#Se define la creación de un secret literal para los secretos de la APP:
kubectl -n acme create secret generic acme-candidatos \
--from-literal=DB_USER=root \
--from-literal=DB_PASS=r00t


# Comando para ejecutar la creación de un persistentVolumeClaim para la BBDD:
kubectl -n acme apply -f bbdd-persistentVolumeClaim.yaml

# Comando para ejecutar la creación del deployment de la BBDD:
kubectl -n acme apply -f bbdd-deployment.yaml

# Comando para ejecutar la creación del service de la BBDD:
kubectl -n acme apply -f bbdd-service.yaml


# Comando para ejecutar la creación del deployment de la APP:
kubectl -n acme apply -f candidatos-deployment.yaml

# Comando para crear un HPA para autoescalar la APP:
kubectl -n acme autoscale deployment acme-candidatos --min=1 --max=2 --cpu-percent=70

# Comando para ejecutar la creación del service de la APP:
kubectl -n acme apply -f candidatos-service.yaml
