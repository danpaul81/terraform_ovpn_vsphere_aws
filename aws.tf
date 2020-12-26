### https://www.vrealize.it/2020/12/09/using-openvpn-to-connect-on-premises-datacenter-to-aws-vpc/

provider "aws" {
	region 	= var.aws_region
}

resource "aws_vpc" "main" {
	cidr_block	= var.aws_cidr_vpc
	enable_dns_hostnames	= true
	enable_dns_support		= true
	tags = {
		Name = var.aws_tag_vpc
	}
}

resource "aws_subnet" "sn1" {
	vpc_id 		= aws_vpc.main.id
	cidr_block 	= var.aws_cidr_sn1
	
	tags = {
		Name = var.aws_tag_sn1
		}
}		

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = var.aws_tag_igw
	}
}

resource "aws_default_route_table" "rt" {
	default_route_table_id = aws_vpc.main.default_route_table_id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
	depends_on = [aws_internet_gateway.igw]	
	tags = {
		Name = "default table"
	}
}

# use the count function to create route entry for each element of var cidr_onprem
resource "aws_route" "onprem_over_ovpn" {
	count = length(var.cidr_onprem)
	route_table_id = aws_vpc.main.default_route_table_id
	destination_cidr_block = element(var.cidr_onprem,count.index)
	instance_id = aws_instance.ovpn.id	
}

#elastic ip for ovpn_server instance
resource "aws_eip" "eip_ovpn_server" {
	instance 	= aws_instance.ovpn.id
	vpc 		= true
	depends_on  = [aws_internet_gateway.igw]
}

# security group for ovpn server
resource "aws_security_group" "sg_ovpn" {
	name 		= 	"sg_ovpn"
	description = 	"Allow TCP 22 and TCP 443 from OnPrem"
	vpc_id		= 	aws_vpc.main.id
	ingress {
		description = "SSH from OnPrem"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		cidr_blocks = var.cidr_onprem_external
		}
	ingress {
		description = "HTTPS from OnPrem"
		from_port 	= 443
		to_port 	= 443
		protocol	= "tcp"
		cidr_blocks = var.cidr_onprem_external
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = "sg_ovpn"
		}
}

# create cloud-init file for ovpn server on AWS
resource "local_file" "cloud-init-ovpn-server" {
	content = templatefile("${path.module}/cloud-init-ovpn-server.tpl", { 
		client_ssh_user = var.client_ssh_user, 
        ssh_authorized_keys = local.ssh_keys,
		ovpn_static_key = local.ovpn_static_key,
		onprem_network_netmask = local.onprem_network_netmask
		}
	)
	filename = "${path.module}/cloud-init-ovpn-server-generated.yaml"
}



resource "aws_instance" "ovpn" {
	ami 					= 	var.aws_ami_image
	instance_type			=	var.aws_instance_type
	vpc_security_group_ids 	=	[aws_security_group.sg_ovpn.id]
	subnet_id				=	aws_subnet.sn1.id
	source_dest_check		= 	false
	user_data = base64encode(local_file.cloud-init-ovpn-server.content)
	tags = {
		Name = "ovpn_server"
	}
}

