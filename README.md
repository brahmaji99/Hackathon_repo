#create a dockerfile to launch jenkins service along with aws-cli && docker cli installed.

FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update -o Acquire::ForceIPv4=true && \
    apt-get install -y docker.io awscli && \
    apt-get clean

USER jenkins


Note-1:Build the Image

docker build -t jenkins-docker-aws .

Note-2: Run the container

docker run -d \
  --name jenkins \
  --group-add 992 \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins-docker-aws


we have to make sure the above dockerfile needs to create on aws ec2-instance where jenkins application has to be configured along with docker and aws configured.
