
### vSphere specific Variables

variable "vcenter_server" {
	description		= "vCenter Server"
	type			= string
	default			= "192.168.110.22"
}

variable "vcenter_password" {
	description		= "vCenter Server Password"
	type			= string
	default			= "VMware1!"
}

variable "vcenter_user" {
	description		= "vCenter Server User"
	type			= string
	default			= "administrator@vsphere.local"
}

variable "remote_ovf_url" {
	description		= "URL for On-Prem Ubuntu OVF Download"
	type			= string
	default			= "http://192.168.110.10/bionic-server-cloudimg-amd64.ova"
	#default 		= "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.ova"
}

variable "vsphere_datacenter" {
	description ="vSphere pre-created Datacenter for ovpn_client VM"
	type		= string
	default 	= "DC-SiteA"
}

variable "vsphere_cluster" {
	description ="vSphere pre-created Cluster for ovpn_client VM"
	type		= string
	default 	= "Mgmt-Edge-Cluster"
}

variable "vsphere_datastore" {
	description ="vSphere pre-created Datastore for ovpn_client VM"
	type		= string
	default 	= "ds-site-a-nfs02"
}

variable "vsphere_resourcepool" {
	description ="vSphere pre-created Resource Pool for ovpn_client VM"
	type		= string
	default 	= "Mgmt-Pool"
}

variable "vsphere_host" {
	description ="vSphere pre-created ESXi Host for ovpn_client VM"
	type		= string
	default 	= "esxmgmt-01a.corp.local"
}

variable "vsphere_network" {
	description ="vSphere pre-created PortGroup or NSX Segment for ovpn_client VM"
	type		= string
	default 	= "LabNet"
}

### AWS specific Variables

variable "aws_region" {
	description ="AWS region"
	type		= string
	default 	= "eu-west-1"
}

variable "aws_cidr_vpc" {
	description ="CIDR block for VPC"
	type		= string
	default 	= "172.30.0.0/16"
}

variable "aws_tag_vpc" {
	description ="VPC Name Tag"
	type		= string
	default 	= "AWS_VPC_DEMO"
}


variable "aws_cidr_sn1" {
	description ="CIDR block for Subnet1"
	type		= string
	default 	= "172.30.1.0/24"
}

variable "aws_tag_sn1" {
	description ="SN1 Name Tag"
	type		= string
	default 	= "AWS_VPC_SN1"
}

variable "aws_tag_igw" {
	description ="IGW Name Tag"
	type		= string
	default 	= "IGW"
}

variable "aws_ami_image" {
	description ="AMI Image to use for OpenVPN Server"
	type		= string
	default 	= "ami-0dc8d444ee2a42d8a"  # Ubuntu 16.04 LTS image
}

variable "aws_instance_type" {
	description ="AWS Instance Type for OpenVPN Server"
	type		= string
	default 	= "t2.nano"
}


### NETWORKS

variable "cidr_onprem" {
	description	=	"CIDR of on-premise-networks. Needed for routing from AWS VPC/OVPN"
	type		= 	list(string)
	default 	= 	[
						"172.16.0.0/16",
						"192.168.110.0/24"
					]
}

variable "cidr_onprem_external" {
	description = "External CIDR of OnPrem Environment. External access to OVPN Server will be limited to theese"
	type 		= list(string)
	default 	= [
					"146.247.47.0/24",
					"91.40.250.40/32"
				]
}

## Generic Variables used for both VM and EC2 Instance

# user to create
variable "client_ssh_user" {
	description ="Local username for client/server ovpn instances"
	type		= string
	default 	= "vmware"
}

# SSH keys for user Login. Please provide keys in named file
data "local_file" "provided_ssh_keys" {
  filename = "${path.module}/config_data/authorized_keys.txt"
}

# netplan config file for ovpn client. Check and modify if needed
data "local_file" "ovpn_client_netplan" {
  filename = "${path.module}/config_data/netplan-cloud-init.txt"
}

# static key for ovpn encryption
# you should create your own by running "openvpn --genkey --secret static.key" and replacing file in confi_data
data "local_file" "ovpn_static_key" {
  filename = "${path.module}/config_data/ovpn-static-key.txt"
}

# re-read each config file line-by line, remove line breaks and store in array
# template file will read each line and print with fitting spaces to keep resulting yaml valid
 locals {
	ssh_keys = [
	for line in split("\n", data.local_file.provided_ssh_keys.content):
	  chomp(line)
	 ]

	netplan_lines = [
	for line in split("\n", data.local_file.ovpn_client_netplan.content):
	  chomp(line)
	 ]
	
	ovpn_static_key = [
	for line in split("\n", data.local_file.ovpn_static_key.content):
	  chomp(line)
	 ]

   onprem_network_netmask = [
	for line in var.cidr_onprem :
	  "${cidrhost(line,0)} ${cidrnetmask(line)}"
	]
}
