FROM python:3.10-bullseye
RUN apt update && apt install -y ansible
RUN mkdir -p /etc/ansible
ENTRYPOINT [ "ansible" ]