#!/bin/bash 

#######################################################################
#			Elasticsearch installation		                          #
#######################################################################
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo tee /etc/yum.repos.d/elasticsearch.repo  << EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

sudo yum install -y --enablerepo=elasticsearch elasticsearch 
sudo tee -a /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 0.0.0.0
transport.host: localhost
EOF

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

#######################################################################################
#				Logstash installation				      							  #
#######################################################################################

elastic_ip=$(cat /tmp/ip)

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo tee /etc/yum.repos.d/logstash.repo  << EOF
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install -y logstash

cat << EOF | sudo tee /etc/logstash/conf.d/logstash.conf
input {
	file {
		path => "/usr/share/tomcat/logs/*"
		start_position => "beginning"
		type => "tomcat_logs"
	}
}
output {
	elasticsearch {
		hosts => ["${elastic_ip}:9200"]
	}
	stdout { codec => rubydebug}
}
EOF
sudo tee /etc/logstash/logstash.yml << EOF
path.config: "/etc/logstash/conf.d/*.conf"
EOF

sudo systemctl enable logstash
sudo systemctl start logstash

#####################################################################
#			Kibana installation			                            #
#####################################################################
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo tee /etc/yum.repos.d/kibana.repo << EOF
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install -y kibana 

sudo sed -i "s/server\.port.*$/server\.port: 5601/" /etc/kibana/kibana.yml
sudo sed -i "s/network\.host.*$/network\.host: 0.0.0.0" /etc/kibana/kibana.yml
sudo sed -i "s/http\.port.*$/http\.port: 9200/" /etc/kibana/kibana.yml

sudo tee -a /etc/kibana/kibana.yml  <<EOF
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

sudo systemctl enable kibana
sudo systemctl start kibana
