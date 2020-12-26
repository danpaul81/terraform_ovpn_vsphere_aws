#cloud-config

hostname: ovpn_client

users:
  - name: ${client_ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
%{ for line in ssh_authorized_keys ~}
      - ${line})
%{ endfor ~}
write_files:
  - content: |
%{ for line in netplan_config ~}
      ${line}
%{ endfor ~}
    path: /etc/netplan/50-cloud-init.yaml
  - content: |
      port 443
      proto tcp-client
      dev tun
      remote ${aws_ovpn_server_elastic_ip}
      secret /etc/openvpn/static.key
      cipher AES-256-CBC
      ifconfig 10.8.0.2 255.255.255.0
      verb 3
      topology subnet
      route ${aws_subnet_vpc} ${aws_netmask_vpc} 10.8.0.1
      keepalive 10 120
      persist-key
      persist-tun
    path: /etc/openvpn/client.conf
  - content: |
%{ for line in ovpn_static_key ~}
      ${line}
%{ endfor ~}
    path: /etc/openvpn/static.key
    permissions: '0600'
    owner: root.root
runcmd:
- netplan generate
- netplan apply
- apt update
- apt upgrade -y
- apt install openvpn -y
- sed -i 's/\#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf 
- reboot