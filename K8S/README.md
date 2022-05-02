# Bootcamp DevOps V - Contenedores y Kubernetes - David De la Cruz

## Instrucciones para desplegarla en Kubernetes, incluyendo:

- [Requerimientos](#requirements)
- [Recursos creados en K8S](./candidatos/#readme)
- [Configurabilidad](#custom)

<br>

<a name="requirements"></a>
### Requerimientos:

- Para poder desplegar la App Candidatos en Kubernetes, será necesario disponer de un cluster de Kubernetes con un mínimo de 2 nodos.  
  He realizado la creación de un cluster de Kubernetes en GCP, haciendo uso del SaaS GKE (Google Kubernetes Engine):  

    - El cluster consta de 2 nodos con tipo de hardware **e2-small de núcleo compartido** y **versión de Kubernetes 1.21.10-gke.2000**
      Cada nodo está en una zona distinta de la región y tiene asignado de forma automática por GKE:  
        940mCPU de procesador  
	1.44GB de memoria RAM  
		
    - Para el acceso a la aplicación Web desde el exterior del cluster, es decir, desde Internet, será necesario crear una regla en el
      firewall de GCP, que permita el acceso desde Internet al puerto 30000 de cada nodo.  

      Para ello, primero será necesario tener instalado el [SDK de GCP (gcloud)](https://cloud.google.com/sdk/docs/install) y crear una cuenta de servicio desde la consola de CGP (IAM) para que tu ordenador pueda tener autorización para gestionar los recursos. Esta cuenta de servicio tiene que estár configurada en el fichero ~/.gcp/config.json  

**Comando para crear la regla del firewall en el nodo de GKE:**

```
$ gcloud compute --project=<NOMBRE-PROYECTO> \
firewall-rules create acceso-nodo-gke \
 --description="Acceso a Nodo GKE desde el exterior con SVC" \
 --direction=INGRESS \
 --priority=1002 \
 --network=default \
 --action=ALLOW \
 --rules=tcp:30000 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=gke-skynet-6534cbb1-node

Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/maximal-quanta-337913/global/firewalls/acceso-nodo-gke].
Creating firewall...done.                                                                    
NAME             NETWORK  DIRECTION  PRIORITY  ALLOW      DENY  DISABLED
acceso-nodo-gke  default  INGRESS    1002      tcp:30000        False
```

<br>

- Una vez creada la regla en el firewall, será necesario conocer la dirección IP pública del nodo que está dando servicio a la web a través del NodePort configurado, para comprobar la conexión e2e:  
  
  **Esta comprobación no podrá llevarse a cabo si antes no se realizado el despliegue de los recursos.**
  Para ello, primero será necesario tener instalado la herramienta de CLI para interactuar con un cluster de Kubernetes [(Kubectl)](https://kubernetes.io/docs/tasks/tools/#kubectl)  
  
  Es necesario realizar la conexión al cluster mediante la CLI a través de Kubectl y de esta forma poder administrar el cluster:  

`gcloud container clusters get-credentials skynet --region europe-west3 --project maximal-quanta-337913`

<br>

```
$ kubectl get node gke-skynet-pool-node-zeus-1b39357c-7jnq  \
-o jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}'

34.159.117.35

$ curl 34.159.117.35:30000
```

<br>

- También será necesario instalar unos plugins de la herramienta Kubectl que ayudarán en la gestión de los recursos del cluster:
	  
   * [Kubectl Krew](https://github.com/kubernetes-sigs/krew/) es un gestor de descarga de plugins para la herramienta Kubectl. 
   * [Kubectl ctx && Kubectl ns ](https://github.com/ahmetb/kubectx) son plugins que permiten un fácil intercambio entre contextos y NameSpaces.

<br>

- La App se encarga de guardar las fotos de los candidatos, por lo que la solución de almacenamiento que se ha definido ha sido crear un disco en Google, ya que la solución de un PersistentVolumeClaim como en el caso de la BBDD no es factible, ya que al replicar el pod en otro nodo, da error de volumen, debido a que ese PV ya está montado en un nodo de una zona determinada.

```
gcloud compute disks create acme-fotos-candidatos \
--project=maximal-quanta-337913 \
--type=pd-standard \
--description=descripcion_fotos_candidatos_acme \
--size=10GB --zone=europe-west3-a
```

<br>

<a name="custom"></a>
### Configurabilidad:

- Documentación de todo lo que sea configurable:

  a. La aplicación debe de poder ser configurable, mediante fichero de configuración y/o variables de entorno, por ejemplo:  
	
   - host de la base de datos  
   - puerto  
   - usuario  
   - contraseña  
   - etc.  

  b. Trata de dotar de la mayor flexibilidad posible al microservicio y documenta todas las opciones de configuración en el README.  

Opciones personalizables:  

 - Nombre de la BBDD  
 - Driver de conexión con la BBDD  
 - URL de conexión a la BBDD  
 - Usuario de acceso root de la BBDD  
 - Password del usuario root de la BBDD  
 - Hostname del servidor de la BBDD (corresponde con el Service creado para la BBDD)  
 - Puerto del servidor de la BBDD  
 - PATH donde ubicar el fichero con el schema de la BBDD  
 - Conjunto de carácteres  
 - TimeZone para la BBDD  
 - URL del repositorio de GitHub con el contenido del código fuente de la App Java.  
