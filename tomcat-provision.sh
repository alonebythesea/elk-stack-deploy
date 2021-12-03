#!/bin/bash

#######################################################################################
#				Tomcat installation				      								  #
#######################################################################################
sudo yum install -y java-1.8.0-openjdk

sudo yum install -y tomcat wget tomcat-admin-webapps tomcat-docs-webapp tomcat-javadoc tomcat-webapps

wget https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war 
sudo mv sample.war /var/lib/tomcat/webapps/

chown tomcat:tomcat -R /var/lib/tomcat/webapps/*
sudo chmod 775 -R /var/lib/tomcat/webapps/
sudo chmod 775 -R /usr/share/tomcat/logs/

sudo tee /usr/share/tomcat/conf/tomcat-users.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users version="1.0" xmlns="http://tomcat.apache.org/xml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd">
  <role rolename="manager-gui"/>
  <role rolename="admin-gui"/>
  <role rolename="manager-script"/>
  <user username="tomcat" password="tomcat" roles="manager-gui,admin-gui,manager-script"/>
</tomcat-users>
EOF

sudo systemctl enable tomcat
sudo systemctl start tomcat
