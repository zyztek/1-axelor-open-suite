Axelor Open Suite
================================

Axelor Open Suite reduces the complexity and improve responsiveness of business processes. Thanks to its modularity, you can start with few features and  then activate other modules when needed.

Axelor Open Suite includes the following modules :

* Customer Relationship Management
* Sales management
* Financial and cost management
* Human Resource Management
* Project Management
* Inventory and Supply Chain Management
* Production Management
* Multi-company, multi-currency and multi-lingual

Axelor Open Suite is built on top of [Axelor Open Platform](https://github.com/axelor/axelor-open-platform)

Installation
================================

To compile and run from source, you will need to clone [Open Suite webapp](https://github.com/axelor/open-suite-webapp)
which is including this repository as a submodule.

You can find more detailed [installation instructions](https://docs.axelor.com/abs/5.0/install/index.html) on our documentation.



---------------------------------------------------------

Axelor Ver 7.2.7 Installation in Ubuntu 22.04.3
Prerequisites

    Git 15
    OpenJDK 11
    Tomcat 9.0.86 (10 was incompatible)
    PostgreSQL version 14

**Install Git**

sudo apt-get install git

For Ubuntu, this PPA provides the latest stable upstream Git version

sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git

**Install OpenJDK 11**

sudo apt-get install openjdk-11-jdk

**Install Tomcat 9.0.86**

**For security purposes, Tomcat should be run as an unprivileged user (i.e. not root).**

**First create a new tomcat group:**

sudo groupadd tomcat

**Now create a new tomcat user:**

sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

**Now, download version of Tomcat 9.0.86 from the Tomcat Downloads page 21. Under the Binary Distributions section, copy the link to the .tar.gz package. e.g apache-tomcat-9.0.86cd .tar.gz**

**Follow these commands:**

cd /tmp
curl -O https://downloads.apache.org/tomcat/tomcat-9/v9.0.86/bin/apache-tomcat-9.0.86.tar.gz
sudo mkdir -p /opt/tomcat
sudo tar -xzf apache-tomcat-9.0.86.tar.gz -C /opt/tomcat --strip-components=1

**Now fix permissions:**

cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/

**Install PostgreSQL**

sudo apt update
sudo apt install postgresql postgresql-contrib

**You may also want to configure postgresql server to allow password authentication.**

*****
Example pg_hba.conf

sudo nano /etc/postgresql/14/main/pg_hba.conf

Replace peer to trust in # Â« local Â» is for Unix domain socket connections only. See below

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5

*****

**Once PostgreSQL is configured, create a new database user with password:**

sudo su postgres
createuser axelor --no-createdb --no-superuser
psql -c "alter user axelor with encrypted password 'PUT_YOUR_OWN_PASSWORD_HERE'";
psql -c "CREATE DATABASE axelor";
exit


**Try this method of getthing the WAR file:**

cd /opt/tomcat/webapps/ 
wget https://github.com/axelor/axelor-open-suite/releases/download/v7.2.7/axelor-erp-v7.2.7.war
sudo jar xvf axelor-erp-v7.2.7.war 
sudo systemctl restart tomcat



**Now change the /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor-config.properties by editing the file as follow:**

sudo nano /opt/tomcat/webapps/ROOT/WEB-INF/classes/axelor-config.properties

**However, you have to provide database settings like this or if you have set it up with different database name or user name and password:**

db.default.driver = org.postgresql.Driver
db.default.ddl = update
db.default.url = jdbc:postgresql://localhost:5432/axelor (make sure the database name is [axelor]
db.default.user = axelor
db.default.password = axelor (your own unique password)

**Create Tomcat systemd Service File**

**We want to be able to run Tomcat as a service, so we will set up systemd service file.**

**Tomcat needs to know where Java is installed. This path is commonly referred to as â€œJAVA_HOMEâ€. The easiest way to look up that location is by running this command:**

sudo update-java-alternatives -l

Output
java-1.11.0-openjdk-amd64       1111       /usr/lib/jvm/java-1.11.0-openjdk-amd64

**Your JAVA_HOME is the output from the last column. Given the example above, the correct JAVA_HOME for your server would be:**

JAVA_HOME
/usr/lib/jvm/java-1.11.0-openjdk-amd64

**With this piece of information, we can create the systemd service file. Open a file called tomcat.service in the /etc/systemd/system directory by typing:**

sudo nano /etc/systemd/system/tomcat.service

**Paste the following contents into your service file. Modify the value of JAVA_HOME if necessary to match the value you found on your system Â« /usr/lib/jvm/java-1.8.0-openjdk-amd64 Â». You may also want to modify the memory allocation settings that are specified in CATALINA_OPTS :

/etc/systemd/system/tomcat.service

[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
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

**When you are finished, save and close the file.**


**Next, reload the systemd daemon so that it knows about our service file:**

sudo systemctl daemon-reload

**Start the Tomcat service by typing:**

sudo systemctl start tomcat

**Double check that it started without errors by typing:**

sudo systemctl status tomcat

**After a short time you can access the application at:**

 http://IP-ADDRESS:8080

**While waiting for the application to come up you can check the log file Â« catalina.out Â» located in /opt/tomcat/logs.**

sudo nano /opt/tomcat/logs/catalina.out
OR
tail -f /opt/tomcat/logs/catalina.out

**If you want to run the application with port 80 "without 8080. Note: make sure no other http services is running.**

**Edit the file /opt/tomcat/conf/server.xml as follow:**

sudo nano /opt/tomcat/conf/server.xml 

**and replace this par of the file the port from 8080 to 80**

<Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
