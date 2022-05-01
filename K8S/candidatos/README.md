# Bootcamp DevOps V - Contenedores, más que VMs - David De la Cruz

## Descripción de los recursos creados (Generación de manifests de Kubernetes):

- [Deployments](#deployments)
- [Services](#services)
- [Persistent Volume Claims](#pvc)
- [ConfigMaps](#configMap)
- [Secrets](#secrets)
- [Affinity](#affinity)
- [Autoescalado](#hpa)

<br>

<a name="deployments"></a>
### Deployments:

1)  Se define en un manifest en formato YAML la creación del WorkLoad Deployment correspondiente a la Base de Datos:  
    Este manifiesto creará un objeto Deployment en el namespace acme con nombre acme-bbdd que consta de:
      - 1 Réplica
      - Imagen del contenedor será MySQL
      - Escuchará en el puerto TCP 3306
      - Persistencia de datos permanente para salvaguardar los datos de la BBDD.

**bbdd-deployment.yaml**

```yaml
apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: acme-bbdd
  namespace: acme
spec: 
  selector:
    matchLabels:
      app: mysql
  replicas: 1 
  template:
    metadata:
      name: acme-bbdd
      namespace: acme
      labels:
        app: mysql
    spec:
      containers:
        - name: bbdd-empresa-sql
          image: mysql:latest
          envFrom:
            - configMapRef:
                name: acme-bbdd-sql
            - secretRef:
                name: acme-bbdd
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
          workingDir: /var/lib/mysql
          ports:
            - containerPort: 3306
          livenessProbe:
            tcpSocket:
              port: 3306
            initialDelaySeconds: 40
            periodSeconds: 90
            timeoutSeconds: 10
            failureThreshold: 3
            successThreshold: 1
      restartPolicy: Always      
      volumes:
        - name: mysql-data
          persistentVolumeClaim:
            claimName: mysql-data  
```

<br>

2)  Se define en un manifest en formato YAML la creación del WorkLoad Deployment correspondiente a la aplicación web:  
    Este manifiesto creará un objeto Deployment en el namespace acme con nombre acme-bbdd que consta de:
      - 1 Réplica
      - Afinidad de preferencia a Pods con label app: mysql para estar cerca del nodo donde está la BBDD corriendo.
      - AntiAfinidad de requerimiento a Pods con label app: acme-candidatos para separar las réplicas de la App en nodos distintos.
      - 2 InitContainers:
          Uno para la compilación de la App por parte de Maven.
          Otro para la carga del schema de la BBDD con un cliente de MySql.
      - Persistencia de datos permanente para almacenar las fotos de los candidatos (en GCP).
      - La App correrá en el contenedor principal con una imagen de Tomcat, escuchando en el puerto 8080.       

**candidatos-deployment.yaml**

```yaml
apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: acme-candidatos
  namespace: acme
spec: 
  selector:
    matchLabels:
      app: acme-candidatos
  replicas: 1 
  template:
    metadata:
      name: acme-webapp
      namespace: acme
      labels:
        app: acme-candidatos
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - mysql
                topologyKey: "kubernetes.io/hostname"
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - acme-candidatos
              topologyKey: "kubernetes.io/hostname"
      initContainers:
        - name: init-java-compilation
          image: maven:3.6.3-jdk-11
          envFrom:
            - secretRef:
                name: acme-candidatos
          env:
            - name: REPO_GITHUB
              valueFrom:
                configMapKeyRef:
                  name: acme-app-candidatos
                  key: REPO_GITHUB
            - name: DB_URL
              valueFrom:
                configMapKeyRef:
                  name: acme-app-candidatos
                  key: DB_URL
            - name: DB_DRIVER
              valueFrom:
                configMapKeyRef:
                  name: acme-app-candidatos
                  key: DB_DRIVER
          volumeMounts:
            - name: java-compilation
              mountPath: /app_java_temp
            - name: scripts
              readOnly: true
              mountPath: /scripts
          workingDir: /app_java_temp
          command: ['sh', "/scripts/bootstrap.sh"]
        - name: init-carga-datos-sql
          image: mysql:latest
          envFrom:
            - configMapRef:
                name: acme-app-candidatos
            - secretRef:
                name: acme-candidatos
          volumeMounts:
            - name: sql-schema
              readOnly: true
              mountPath: /mysql
          workingDir: /mysql
          command: [ "sh", "-c", "mysql -u$DB_USER -p$DB_PASS -h $DB_SERVER -P $DB_PORT --default-character-set=$CHARACTER_SET -D $BBDD < $PATH_BBDD -f" ]
      containers:
        - name: javaee
          image: tomcat:9.0-jdk11-temurin-focal
          envFrom:
            - configMapRef:
                name: acme-app-candidatos
            - secretRef:
                name: acme-candidatos
          volumeMounts:
            - name: java-compilation
              mountPath: /usr/local/tomcat/webapps/gestion-candidatos
              subPath: deploy
            - name: webapp-data
              mountPath: /usr/local/tomcat/webapps/gestion-candidatos/fotos
          workingDir: /usr/local/tomcat/webapps/gestion-candidatos
          command: [ "sh", "-c", "jar -xvf gestion-candidatos.war && catalina.sh run" ]
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 350m
            limits:
              cpu: 450m
          livenessProbe:
            httpGet:
              path: /gestion-candidatos
              port: 8080
              httpHeaders:
                - name: Liveness-probe-http
                  value: "true"
            initialDelaySeconds: 40
            periodSeconds: 90
            timeoutSeconds: 10
            failureThreshold: 3
            successThreshold: 1
      volumes:
        - name: java-compilation
          emptyDir: {}
        - name: webapp-data
          gcePersistentDisk:
            pdName: acme-fotos-candidatos
        - name: sql-schema
          configMap: 
            name: acme-bbdd-empresa
        - name: scripts
          configMap:
            name:  acme-scripts
      restartPolicy: Always
```

<br>

<a name="services"></a>
### Services:

1)  Se define el manifest correspondiente al servicio de la BBDD (Indoor):  
    El servicio expondrá el acceso a la BBDD desde el interior del nodo para que la App pueda acceder desde el interior.

**bbdd-service.yaml**

```yaml
kind: Service
apiVersion: v1
metadata:
  name: bbdd-empresa-sql
  namespace: acme
spec:
  selector:
    app: mysql
  ports:
    - name: mysql
      port: 3306
      targetPort: 3306
```

<br>

2)  Se define el manifest correspondiente al servicio de la App (Outdoor):  
    Este objeto Service expondrá al App al exterior del Nodo a través del puerto 30000.

**candidatos-service.yaml**

```yaml
kind: Service
apiVersion: v1
metadata:
  name: acme-candidatos
  namespace: acme
spec:
  type: NodePort
  selector:
    app: acme-candidatos
  ports:
    - name: http
      port: 8000
      targetPort: 8080
      nodePort: 30000
      protocol: TCP
```

<br>

<a name="pvc"></a>
### Almacenamiento persistente:

1) Se declara en un manifest la creación de un objeto **PersistentVolumeClaim** correspondiente a la persistencia de la BBDD:  
   Este almacenamiento se provisiona de forma dinámica gracias a las Class Storage y a los PVC.

**bbdd-persistentVolumeClaim.yaml**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data
  namespace: acme
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

<br>


<a name="configMap"></a>
### ConfigMaps:

1)  Se define a través de la CLI, la creación de un objeto ConfigMap para ser usado por la BBDD, con origen un archivo de propiedades, cuya Key será cada propiedad de dicho archivo:  

  La única propiedad declarada corresponde al nombre de la BBDD a crear por el asistente de la imagen MySQL en su ejecución.
  Este ConfigMap será utilizado para la creación de las variables de entorno del contenedor, importando los datos desde este configMap.

`kubectl -n acme create configmap acme-bbdd-sql --from-env-file=resources/bbdd.properties`

<br>

**bbdd.properties**

```
MYSQL_DATABASE=empresa
```

<br>

2)  Se define la creación de un ConfigMap para ser usado por la App, con origen un archivo de propiedades, cuya Key será cada propiedad de dicho archivo:

   Este ConfigMap será utilizado para la creación de las variables de entorno del contenedor, importando los datos desde este configMap.

`kubectl -n acme create configmap acme-app-candidatos --from-env-file=resources/app.properties`

<br>

**app.properties**

```
DB_SERVER=bbdd-empresa-sql # Corresponde con el nombre del service creado en Kubernetes para la BBDD.
DB_PORT=3306
BBDD=empresa # Nombre de la BBDD
PATH_BBDD=/mysql/bbdd_empresa.sql
CHARACTER_SET=utf8
DB_TIMEZONE=Europe/Madrid
DB_DRIVER=com.mysql.cj.jdbc.Driver
DB_URL=jdbc:mysql://bbdd-empresa-sql:3306/empresa?serverTimezone=Europe/Madrid
REPO_GITHUB=https://github.com/davidjapo/acme-candidatos.git # Repositorio que contiene el código fuente de la aplicación web
```

<br>

3)  Se define la creación de un ConfigMap que contiene el fichero de la creación del schema de la BBDD, para ser utilizado por el InitContainer de la carga de datos:  

`kubectl -n acme create configmap acme-bbdd-empresa --from-file=resources/bbdd_empresa.sql`

**bbdd_empresa.sql**

```sql
CREATE DATABASE  IF NOT EXISTS `empresa` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_spanish_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `empresa`;
-- MySQL dump 10.13  Distrib 8.0.22, for Linux (x86_64)
--
-- Host: localhost    Database: empresa
-- ------------------------------------------------------
-- Server version	8.0.23

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `candidatos`
--

/*DROP TABLE IF EXISTS `candidatos` */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE IF NOT EXISTS `candidatos` (
  `idCandidato` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `edad` int DEFAULT NULL,
  `puesto` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `foto` varchar(500) COLLATE utf8_spanish_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idCandidato`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `candidatos`
--

LOCK TABLES `candidatos` WRITE;
/*!40000 ALTER TABLE `candidatos` DISABLE KEYS */;
/*INSERT INTO `candidatos` VALUES (1,'test',0,'test','test.png','test@test.test') */;
/*!40000 ALTER TABLE `candidatos` ENABLE KEYS */;
UNLOCK TABLES;
```

<br>

4)  Se define la creación de un ConfigMap que contienen los ficheros de los scripts de la App, para ser utilizado por el InitContainer de la compilación de la App Java:  

  El script de configuración de variables, permite dotar de configurabilidad a la App, realizando la sustitución de valores antes de la compilación del programa. Para ello se hace uso del paquete *envsubst* de Linux para manipular textos.

`kubectl -n acme create configmap acme-scripts --from-file=scripts/bootstrap.sh --from-file=scripts/script_variables.sh`

**script_variables.sh**

```bash
#!/bin/bash

# ESTE SCRIPT REALIZARÁ UN CAMBIO DE VARIABLES EN LOS FICHEROS DE CONFIGURACIÓN DE LA PERSISTENCIA DE LA APP JAVA EE,
# PARA DOTAR DE AUTOMATISMO Y PERSONALIZACIÓN EN CUANTO A LOS VALORES CORRESPONDIENTES A LA BASE DE DATOS:

XML_TMP=/app_java_temp/src/main/java/META-INF/persistence_temp.xml
XML_OUT=/app_java_temp/src/main/java/META-INF/persistence.xml

envsubst "`printf '${%s} ' $(sh -c "env|cut -d'=' -f1")`" < $XML_TMP > $XML_OUT

echo ""
echo "************************************************************************"
echo "Script de automatización de variables BBDD SQL finalizado correctamente"
echo "************************************************************************"
echo ""

exit 0
```

<br>

**persistence_temp.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.1" xmlns="http://xmlns.jcp.org/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_1.xsd">
	<persistence-unit name="empresaPU" transaction-type="RESOURCE_LOCAL">
		<provider>org.hibernate.jpa.HibernatePersistenceProvider</provider>
		<class>model.Candidato</class>
		<properties>
			<property name="javax.persistence.jdbc.url" value="$DB_URL"/>
			<property name="javax.persistence.jdbc.user" value="$DB_USER"/>
			<property name="javax.persistence.jdbc.password" value="$DB_PASS"/>
			<property name="javax.persistence.jdbc.driver" value="$DB_DRIVER"/>
		</properties>
	</persistence-unit>
</persistence>
```

<br>

**bootstrap.sh**

```bash
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
```

<br>

<a name="secrets"></a>
### Como generar los secrets:

1)  Se define la creación de un secret literal para los secretos de la BBDD:  

  Este secret será cargado como variables de entorno en el contenedor.

```
kubectl -n acme create secret generic acme-bbdd \
--from-literal=MYSQL_ROOT_USER=root \
--from-literal=MYSQL_ROOT_PASSWORD=<rootpass> \
--from-literal=MYSQL_USER=<user> \
--from-literal=MYSQL_PASSWORD=<pass>
```

2)  Se define la creación de un secret literal para los secretos de la APP:  

  Este secret será cargado como variables de entorno en el contenedor.

`kubectl -n acme create secret generic acme-candidatos --from-literal=DB_USER=<user> --from-literal=DB_PASS=<pass>`

<br>

<a name="affinity"></a>
### Afinidad:

1)  Asegurar que los PODs de la base de datos y la aplicación permanezcan lo más juntos posibles al desplegarse en Kubernetes:  

  He configurado una regla de Afinidad de Pod para que el scheduling de los Pods de la APP se creen de *preferencia* en el mismo nodo donde se encuentren Pods con la etiqueta de mysql.

<br>

2)  Asegurar que los PODs de las réplicas de la aplicación permanezcan lo más separados posibles:  

  He configurado una regla de AnfiAfinidad de Pod para que el scheduling de las réplicas de los Pods de la App NO se creen de *requerimiento* en el mismo nodo donde ya existan Pods con la etiqueta de la App acme-candidatos.
  
<br>

<a name="hpa"></a>
### Autoescalado:

1)  Autoescalar la aplicación (no la base de datos) cuando pase de un umbral de uso de CPU del 70%, asegurando siempre una alta disponibilidad:  

  Teniendo en cuenta el tipo de hardware que corre sobre el cluster, he definido únicamente un máximo de 2 réplicas.

`kubectl -n acme autoscale deployment acme-candidatos --min=1 --max=2 --cpu-percent=70`

<br>

2)  Para forzar el autoescalado, se procede a inyectar tráfico a la web, haciendo uso de la herramienta ab de Apache2-utils, creando un pod manualmente:  

`kubectl -n acme run test-carga -it --rm --image=ubuntu/apache2 --command -- sh -c 'ab -n 500000 -c 1000 -s 50 http://acme-candidatos:8000/gestion-candidatos'`