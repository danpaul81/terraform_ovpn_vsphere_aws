provider "vsphere" {
	user = var.vcenter_user
	# 1.24.3 did ignore vapp properties, so enforcing 1.24.0
	version  = "1.24.0"
	password = var.vcenter_password
	vsphere_server = var.vcenter_server
	allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
	name	= var.vsphere_cluster
	datacenter_id = data.vsphere_datacenter.dc.id
}


data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resourcepool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}


data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# create cloud-init file for ovpn client on vSphere On-Premises
resource "local_file" "cloud-init-ovpn-client" {
	content = templatefile("${path.module}/cloud-init-ovpn-client.tpl", { 
		client_ssh_user = var.client_ssh_user, 
        ssh_authorized_keys = local.ssh_keys,
		netplan_config = local.netplan_lines,
		aws_ovpn_server_elastic_ip = aws_eip.eip_ovpn_server.public_ip,
		aws_subnet_vpc = cidrhost(var.aws_cidr_vpc,0),
		aws_netmask_vpc = cidrnetmask(var.aws_cidr_vpc),
		ovpn_static_key = local.ovpn_static_key
		}
	)
	filename = "${path.module}/cloud-init-ovpn-client-generated.yaml"
}


resource "vsphere_virtual_machine" "ovpn_client" {
  name                     	 = "ovpn_client_tf"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id          	 = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id
  cdrom {
    client_device = true
  }
  ovf_deploy {
	remote_ovf_url 		= var.remote_ovf_url
 	disk_provisioning	= "thin"
	ip_protocol			= "IPV4"
	ip_allocation_policy	= "STATIC_MANUAL"	
	ovf_network_map = {
        "VM Network" = data.vsphere_network.network.id
    }
  }
  vapp {
	properties = {
		"instance-id" = "ovpn-client"
		user-data = base64encode(local_file.cloud-init-ovpn-client.content)
	}
	}

}

