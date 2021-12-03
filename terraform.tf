provider "aws" {
	region = "us-east-1"
}


data "aws_vpc" "default" {
	default = true
}

data "aws_subnet_ids" "all" {
	vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_ssh" {
	name = "allow_ssh"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 22
	  to_port     = 22
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
	  from_port   = 0
	  to_port     = 0
	  protocol    = -1
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_internal" {
	name = "allow_internal"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 0
	  to_port     = 0
          protocol    = -1
	  cidr_blocks = [data.aws_vpc.default.cidr_block]
	}
}

resource "aws_security_group" "allow_8080" {
	name = "allow_8080"
	vpc_id = data.aws_vpc.default.id

	ingress {
	  from_port   = 8080
	  to_port     = 8080
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_9200" {
	name = "allow_9200"
	vpc_id = data.aws_vpc.default.id

	ingress {
	  from_port   = 9200
	  to_port     = 9200
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_5601" {
	name = "allow_5601"
	vpc_id = data.aws_vpc.default.id

	ingress {
	  from_port   = 5601
	  to_port     = 5601
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "ek-stack" {
	count 	      	       = 1
	ami           	       = "ami-0083662ba17882949"
	instance_type 	       = "t3.medium"
	availability_zone      = "us-east-1a" 
	key_name      	       = "my-key"
	vpc_security_group_ids = [aws_security_group.allow_internal.id, aws_security_group.allow_ssh.id, aws_security_group.allow_9200.id, aws_security_group.allow_5601.id]
	
	connection {
		type = "ssh"
		host = self.public_ip 
		user = "centos"
		private_key = file("~/.ssh/my-key.pem") 
	}
	
	provisioner "file" {

		source = "."
		destination = "/tmp"
	}

	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/elk-provision.sh",
			"sudo /tmp/elk-provision.sh",
		]
	}

}

resource "aws_instance" "appserver" {
	count 	      	       	= 1
	ami           	       	= "ami-0083662ba17882949"
	instance_type 	       	= "t3.small"
	availability_zone      	= "us-east-1a" 
	key_name      	       	= "my-key"
	vpc_security_group_ids 	= [aws_security_group.allow_internal.id, aws_security_group.allow_ssh.id, aws_security_group.allow_8080.id]

	connection {
		type = "ssh"
		host = self.public_ip 
		user = "centos"
		private_key = file("~/.ssh/my-key.pem") 
	}
	
	provisioner "file" {

		source = "."
		destination = "/tmp"
	}

	provisioner "remote-exec" {
		inline = [
			"sudo echo ${aws_instance.ek-stack[0].public_ip} >> /tmp/ip", 
			"chmod +x /tmp/tomcat-provision.sh",
			"sudo /tmp/tomcat-provision.sh",
		]
	}
} 
