# Agente SSH para tests Python: unit, rest, static, security, coverage.
FROM jenkins/ssh-agent:6.11.2-jdk21

USER root

# Python + curl. Las versiones de los módulos las gestiona requirements.txt
# y se instalan en cada build del pipeline (libertad de cada repo).
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        ca-certificates \
        procps \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/local/bin/python

# Tooling Python global (versiones congeladas para reproducibilidad).
RUN pip3 install --no-cache-dir --break-system-packages \
        pytest==7.4.4 \
        flask==3.0.3 \
        flake8==6.1.0 \
        bandit==1.7.10 \
        coverage==7.4.4

USER jenkins
