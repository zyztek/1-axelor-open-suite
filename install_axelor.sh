#!/bin/bash

# Instalar Git
sudo apt-get update
sudo apt-get install -y git

# Instalar OpenJDK 11
sudo apt-get install -y openjdk-11-jdk

# Instalar Tomcat 9.0.86
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

cd /tmp
curl -O https://downloads.apache.org/tomcat/tomcat-9/v9.0.86/bin/apache-tomcat-9.0.86.tar.gz
sudo mkdir -p /opt/tomcat
sudo tar -xzf apache-tomcat-9.0.86.tar.gz -C /opt/tomcat --strip-components=1

cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/

# Instalar PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# Configurar PostgreSQL
sudo sed -i 's/peer/trust/g' /etc/postgresql/14/main/pg_hba.conf
sudo systemctl restart postgresql

sudo su - postgres -c "createuser axelor --no-createdb --no-superuser"
sudo su - postgres -c "psql -c \"alter user axelor with encrypted password '1234567890'\""
sudo su - postgres -c "psql -c \"CREATE DATABASE axelor\""

# Descargar e implementar el archivo WAR de Axelor
sudo wget https://github.com/axelor/axelor-open-suite/releases/download/v7.2.7/axelor-erp-v7.2.7.war -P /opt/tomcat/webapps/
sudo jar xvf /opt/tomcat/webapps/axelor-erp-v7.2.7.war -C /opt/tomcat/webapps/ROOT/

# Recargará el archivo WAR de Axelor, actualizará la configuración de la base de datos en `axelor-config.properties` y creará un archivo

sudo sed -i 's/db.default.url = jdbc:postgresql:\/\/localhost:5432\/axelor/db.default.url = jdbc:postgresql:\/\/localhost:5432\/axelor/g' /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor-config.properties
sudo sed -i 's/db.default.user = axelor/db.default.user = axelor/g' /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor-config.properties
sudo sed -i 's/db.default.password = axelor/db.default.password = 1234567890/g' /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor-config.properties

# Crear archivo de servicio systemd para Tomcat
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOT

[Unit]
Description=Contenedor de Aplicaciones Web Apache Tomcat
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=root
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Recargar el demonio de systemd e iniciar Tomcat
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Crear archivo de configuración de base de datos para Axelor
sudo tee /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor.properties > /dev/null <<EOT
db.default.driver=org.postgresql.Driver
db.default.url=jdbc:postgresql://localhost:5432/axelor
db.default.user=axelor
db.default.password=1234567890
EOT

# Reiniciar Tomcat para aplicar los cambios
sudo systemctl restart tomcat

echo "¡La instalación de Axelor se ha completado exitosamente!"
ehho "La contrasena por defecto para todo es: 1234567890
echo "Puedes acceder a Axelor ingresando a la siguiente URL: http://localhost:8080/axelor-erp"
