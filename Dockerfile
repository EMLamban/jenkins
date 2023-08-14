FROM jenkins/jenkins AS main

USER root

RUN apt-get update && apt-get install software-properties-common -y
RUN apt-get install ansible -y

ARG ANSIBLE_PASSWORD

RUN useradd ansible && \
    echo "ansible:$ANSIBLE_PASSWORD" | chpasswd

WORKDIR /home/ansible