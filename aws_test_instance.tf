# security group for aws_test server
resource "aws_security_group" "sg_test" {
	name 		= 	"sg_test"
	description = 	"Allow TCP 22 and ICMP from OnPrem"
	vpc_id		= 	aws_vpc.main.id
	ingress {
		description = "SSH from OnPrem"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		cidr_blocks = var.cidr_onprem
		}
	ingress {
		description = "ICMP from OnPrem"
		protocol	= "icmp"
		from_port	= "-1"
		to_port		= "-1"
		cidr_blocks = var.cidr_onprem
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = "sg_test"
		}
}

# create cloud-init file for ovpn server on AWS
resource "local_file" "cloud-init-aws-test-instance" {
	content = templatefile("${path.module}/cloud-init-aws-test-instance.tpl", { 
		client_ssh_user = var.client_ssh_user, 
        ssh_authorized_keys = local.ssh_keys
		}
	)
	filename = "${path.module}/cloud-init-aws-test-instance-generated.yaml"
}


resource "aws_instance" "aws_test" {
	ami 					= 	var.aws_ami_image
	instance_type			=	var.aws_instance_type
	vpc_security_group_ids 	=	[aws_security_group.sg_test.id]
	subnet_id				=	aws_subnet.sn1.id
	user_data = base64encode(local_file.cloud-init-aws-test-instance.content)
	tags = {
		Name = "aws_test"
	}
}




