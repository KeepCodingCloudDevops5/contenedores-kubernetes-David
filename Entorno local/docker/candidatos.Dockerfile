FROM maven:3.6.3-jdk-11 AS compilacion
WORKDIR /app-java_temp
RUN git clone https://github.com/davidjapo/acme-candidatos.git .
RUN mvn clean package


FROM tomcat:9.0-jdk11-temurin-focal AS app
WORKDIR /usr/local/tomcat/webapps/gestion-candidatos
COPY --from=compilacion /app-java_temp/target/17_gestion_candidatos_mvc-0.0.1-SNAPSHOT.war ./gestion-candidatos.war
COPY ./scripts .
RUN apt update && apt install -y gettext && jar -xvf gestion-candidatos.war
EXPOSE 8080
ENTRYPOINT ["sh", "/usr/local/tomcat/webapps/gestion-candidatos/scripts/bootstrap.sh"]