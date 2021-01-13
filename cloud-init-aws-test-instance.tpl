#cloud-config

hostname: aws_test

users:
  - name: ${client_ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
%{ for line in ssh_authorized_keys ~}
      - ${line}
%{ endfor ~}
