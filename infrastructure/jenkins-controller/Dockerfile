# Jenkins controller con JDK21, plugins precargados y JCasC.
FROM jenkins/jenkins:2.452.3-lts-jdk21

USER root

# Plugins en modo offline (jenkins-plugin-cli respeta versiones del update-center).
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# JCasC: descripción declarativa del estado de Jenkins.
COPY casc.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Desactiva el wizard de setup inicial.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER jenkins
