# Ansible Playbooks

## Requirements

1. Linux-based system for running the ansible control node
    1. OpenSSH client installed
    1. Your SSH private key is setup on the control node system in `~/.ssh`
    1. Your SSH public key is propogated to the target systems' `~/.ssh/authorized_keys`
1. If using docker containers for running ansible:
    1. Setup `ssh-agent` for sharing the private key to the container via Linux sockets

## Setup

The Ansible control node could either be setup via:

1. Using pip: `pip install --user ansible`
1. or using docker:
    1. `docker build . -t ansible`
    1. `eval $(ssh-agent)`
    1. `ssh-add`
    1. `docker run -it --rm -v $SSH_AUTH_SOCK:/ssh_auth.sock -v ~/.ssh/known_hosts:/root/.ssh/known_hosts -v /etc/ansible:/etc/ansible/ -e SSH_AUTH_SOCK=/ssh_auth.sock ansible all -m ping`

## Generating known_hosts file via Ansible

It might be helpful to generate your known_hosts file beforehand, in order to use the SSH keys without the Public Key signature authentication prompt. With your ansible control node, run the following playbook:

```bash
ansible-playbook ansible-playbook playbooks/get-ssh-known-host.yml
```
