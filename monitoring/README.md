


  16. Centralización de Logs [OPCIONAL] : Proporciona una solución de centralización
de todos los logs de tu aplicación (o de todo el cluster) utilizando el stack de Elastic
(Elasticsearch, Kibana y Filebeat). Puedes usar sidecar containers con Filebeat en
tus workloads o desplegar Filebeat como DaemonSet en todos los nodos de
Kubernetes.

17. Exposición de métricas [OPCIONAL]: Proporciona una solución de métricas para
algún componente del ecosistema. Para ello puedes utilizar el Elastic Stack
(Elasticsearch, Kibana, Metricbeat) ó una solución basada en Prometheus
(Prometheus, Grafana e instalar algún exporter). Puedes centrarte en las métricas de
la base de datos, de la aplicación o a nivel de Kubernetes (monitorización de
Kubernetes).

18. Creación de algún dashboard para la visualización de los logs y/o métricas, ó
explica en las instrucciones cómo verificar que los logs y las métricas están llegando
al destino [OPCIONAL].

19. Instala y utiliza algún Operador, por ejemplo: el operador de Elastic (ECK),
Prometheus Operator o incluso [OPCIONAL].

