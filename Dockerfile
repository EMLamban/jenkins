FROM jenkins/jenkins

USER root

RUN apt-get update && apt-get install software-properties-common -y
RUN apt-get install ansible -y

USER jenkins