#create a dockerfile to launch jenkins service along with aws-cli && docker cli installed.

FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update -o Acquire::ForceIPv4=true && \
    apt-get install -y docker.io awscli && \
    apt-get clean

USER jenkins
