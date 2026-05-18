# Agente SSH para pruebas de rendimiento con JMeter.
FROM jenkins/ssh-agent:6.11.2-jdk21

USER root

ARG JMETER_VERSION=5.6.3
ENV JMETER_HOME=/opt/jmeter-${JMETER_VERSION} \
    PATH=/opt/jmeter-${JMETER_VERSION}/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz" \
       | tar -xz -C /opt/ \
    && mv "/opt/apache-jmeter-${JMETER_VERSION}" "${JMETER_HOME}" \
    && chmod +x ${JMETER_HOME}/bin/jmeter

# Sin USER al final: setup-sshd del base image arranca como root y baja a jenkins.
