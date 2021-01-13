#cloud-config

hostname: ovpn_server

users:
  - name: ${client_ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
%{ for line in ssh_authorized_keys ~}
      - ${line}
%{ endfor ~}
write_files:
  - content: |
      port 443
      proto tcp-server
      dev tun
      secret /etc/openvpn/static.key
      cipher AES-256-CBC
      ifconfig 10.8.0.1 255.255.255.0
      verb 3
      topology subnet
%{ for line in onprem_network_netmask ~}
      route ${line} 10.8.0.2
%{ endfor ~}
      keepalive 10 120
      persist-key
      persist-tun 
    path: /etc/openvpn/server.conf
  - content: |
%{ for line in ovpn_static_key ~}
      ${line}
%{ endfor ~}
    path: /etc/openvpn/static.key
    permissions: '0600'
    owner: root.root
runcmd:
- apt update
- apt upgrade -y
- apt install openvpn -y 
- sed -i 's/\#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
- reboot
