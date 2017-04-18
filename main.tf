#VERSION=017

terraform {
    required_version = ">= 0.8.2"
}

# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

data "aws_ami" "de_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["Delphix Engine 5.1.4.0 Free Trial"]
  }
  owners = ["180093685553"]
}

data "aws_ami" "lt_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["Delphix Oracle 11G Linux Target"]
  }
  owners = ["180093685553"]
}

data "aws_ami" "ls_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["Delphix Oracle 11G Linux Source"]
  }
  owners = ["180093685553"]
}

resource "aws_security_group" "landshark" {
  name = "${var.instance_name}-${aws_vpc.main.id}"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.main.id}"
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["10.0.1.0/24", "${var.your_ip}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.instance_name}-${var.image_base}-allow_all"
  }
}

resource "aws_instance" "de" {
  instance_type = "m4.xlarge"
  # Lookup the correct AMI based on the region
  # we specified
  ami = "${data.aws_ami.de_ami.id}"

  # The name of our SSH keypair you've created and downloaded
  # from the AWS console.
  #
  # https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:
  #
  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.landshark.id}"]

  subnet_id = "${element(aws_subnet.aw_sub.*.id, 0)}"
  private_ip = "10.0.1.10"
  
  #Instance tags
  tags {
    Name = "${var.instance_name}_${var.image_base}_DE"
  }
}

resource "aws_instance" "lt" {
  instance_type = "m4.large"
  # Lookup the correct AMI based on the region
  # we specified
  ami = "${data.aws_ami.lt_ami.id}"
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file("${var.key_name}.pem")}"
    timeout = "10m"
  }

  # The name of our SSH keypair you've created and downloaded
  # from the AWS console.
  #
  # https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:
  #
  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.landshark.id}"]

  subnet_id = "${element(aws_subnet.aw_sub.*.id, 0)}"
  private_ip = "10.0.1.30"

  user_data = "service dbora start"
  
  # We run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    #This provisioner is to workaround the below issue:
    #https://github.com/hashicorp/terraform/issues/11091
    inline = [
    "sudo cp /usr/bin/tput /usr/bin/tput.bak; sudo cp /dev/null /usr/bin/tput"
    ]
  }

  provisioner "remote-exec" {
    inline = [
    "sudo sed -i -e 's|^MODULE_BASE=.*|MODULE_BASE=GA|' /home/delphix/.ls/config; sleep 60; sudo /u02/app/content/landshark_fetch free_trial -F y"
    ]
  }

  provisioner "remote-exec" {
    inline = [
    "sudo /u02/app/content/landshark_fetch register_engine ${var.community_username} <<EOM\n${var.community_password}\n${var.community_password}\nEOM"
    ]
  }

  provisioner "remote-exec" {
    #This provisioner is to undo the workaround
    inline = [
    "sudo mv /usr/bin/tput.bak /usr/bin/tput"
    ]
  }

  #Instance tags
  tags { 
    Name = "${var.instance_name}_${var.image_base}_LT"
  }
}

resource "aws_instance" "ls" {
  instance_type = "m4.large"
  # Lookup the correct AMI based on the region
  # we specified
  ami = "${data.aws_ami.ls_ami.id}"
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file("${var.key_name}.pem")}"
    timeout = "10m"
  }

  # The name of our SSH keypair you've created and downloaded
  # from the AWS console.
  #
  # https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:
  #
  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.landshark.id}"]

  subnet_id = "${element(aws_subnet.aw_sub.*.id, 0)}"
  private_ip = "10.0.1.20"

  user_data = "service dbora start"
  # We run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    #This provisioner is to workaround the below issue:
    #https://github.com/hashicorp/terraform/issues/11091
    inline = [
    "sudo cp /usr/bin/tput /usr/bin/tput.bak; sudo cp /dev/null /usr/bin/tput"
    ]
  }

  provisioner "remote-exec" {
    inline = [
    "sudo sed -i -e 's|^MODULE_BASE=.*|MODULE_BASE=GA|' /home/delphix/.ls/config; sleep 60; sudo /u02/app/content/landshark_fetch free_trial -F y"
    ]
  }

  provisioner "remote-exec" {
    #This provisioner is to undo the workaround
    inline = [
    "sudo mv /usr/bin/tput.bak /usr/bin/tput"
    ]
  }

  #Instance tags
  tags {
    Name = "${var.instance_name}_${var.image_base}_LS"
  }

}

resource "aws_vpc" "main" {
    cidr_block = "10.0.1.0/24"
    enable_dns_hostnames = true
    tags {
        Name = "${var.instance_name}_${var.image_base}_vpc"
    }
}

resource "aws_route" "r"{
  route_table_id = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

resource "aws_internet_gateway" "main" {
    vpc_id = "${aws_vpc.main.id}"
    tags {
        Name = "${var.instance_name}_${var.image_base}_ig"
    }
}

resource "aws_subnet" "aw_sub" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.instance_name}_${var.image_base}_sub}"
    }
}

output "DE" {
  value = "${
    formatlist(
      "Delphix Engine - Public IP: %s Private IP: %s\n    Access via http://%s\n    Username: delphix_admin Password: landshark",
      aws_instance.de.*.public_ip,
      aws_instance.de.*.private_ip,
      aws_instance.de.*.public_ip
      )}"
}

output "LT" {
  value = "${
    formatlist(
      "Linux Target - Public IP: %s Private IP: %s\n    Access via SSH @%s\n    Username: delphix Password: delphix\n    Dev Employee App: http://%s:2080\n    QA Employee App: http://%s:3080",
      aws_instance.lt.*.public_ip,
      aws_instance.lt.*.private_ip,
      aws_instance.lt.*.public_ip,
      aws_instance.lt.*.public_ip,
      aws_instance.lt.*.public_ip
      )}"
}

output "LS" {
  value = "${
    formatlist(
      "Linux Source - Public IP: %s Private IP: %s\n    Access via SSH @%s\n    Username: delphix Password: delphix\n    Prod Employee App: http://%s:1080",
      aws_instance.ls.*.public_ip,
      aws_instance.ls.*.private_ip,
      aws_instance.ls.*.public_ip,
      aws_instance.ls.*.public_ip
      )}"
}

variable "access_key" {
  description = "Amazon AWS Access Key"
}
variable "secret_key" {
  description = "Amazon AWS Secret Key"
}

variable "image_base" {
  default = "Delphix Free Trial with Oracle 11G"
}

variable "aws_region" {
  description = "The aws region where you will deploy."
}

variable "your_ip" {
  description = "Your IP address (for restricting access to your environment)."
}

variable "key_name" {
  description = "The name of the AWS Key Pair you will use with this environment."
}

variable "instance_name" {
  description = "Any word to help identify your instances in AWS."
}

variable "community_username" {
  description = "Your Delphix Community username."
}

variable "community_password" {
  description = "Your Delphix Community password."
}