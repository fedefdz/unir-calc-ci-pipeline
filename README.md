# CP1 — Pipeline CI/CD sobre Jenkins

Resolución del **Caso Práctico 1 — Apartado B (CP1.2)** del Experto Universitario en DevOps & Cloud de UNIR.

Pipeline de CI completo (unit, integración, estático, seguridad, cobertura, rendimiento) sobre Jenkins, contra una librería Python de calculadora con microservicios Flask. Todo el stack se levanta con `docker compose`.

## Estado por reto

| Reto | Ubicación | Estado esperado |
|---|---|---|
| Reto 1 — pipeline CI completo | `Jenkinsfile` en rama `master` | UNSTABLE (Coverage 97 % líneas / 83 % ramas) |
| Reto 2 — distribución en 3 agentes | `JENKINSFILE_agentes` en rama `master` | UNSTABLE (mismo perfil, ejecución distribuida) |
| Reto 3 — cobertura 100 / 100 | `Jenkinsfile` en rama `feature_fix_coverage` | SUCCESS |

## Requisitos del host

| | |
|---|---|
| Sistema operativo | macOS, Linux o Windows |
| Container runtime | Docker Desktop ≥ 20.10 (o Podman 4+) |
| Memoria asignada al runtime | ≥ 6 GiB |
| CPUs asignadas al runtime | ≥ 4 |
| Puertos libres en el host | 8080 (Jenkins UI), 9090 (Wiremock) |

Nada más. Todo el resto (Java, Python, JMeter, Wiremock, Flask, plugins de Jenkins) vive dentro de los contenedores.

## Levantar el stack

Dos caminos. Hacen exactamente lo mismo.

### Camino A — manual (3 pasos)

```bash
# 1. Llave SSH controller → agentes (ed25519, sin passphrase)
mkdir -p infrastructure/secrets
ssh-keygen -t ed25519 -N "" -C "controller@unir-calc-ci" \
  -f infrastructure/secrets/controller_ssh_key

# 2. .env con admin pass + pubkey en una línea
cat > .env <<EOF
JENKINS_ADMIN_ID=admin
JENKINS_ADMIN_PASSWORD=$(openssl rand -hex 16)
CONTROLLER_SSH_PUBKEY=$(cat infrastructure/secrets/controller_ssh_key.pub)
EOF

# 3. Build + up
docker compose up -d --build
```

### Camino B — script idempotente (1 comando)

```bash
./scripts/bootstrap.sh
```

`bootstrap.sh` ejecuta los 3 pasos del Camino A, además detecta si los secretos ya existen (no los regenera) y espera a que Jenkins UI responda antes de devolver.

### Acceso a Jenkins

```
URL:      http://localhost:8080
Usuario:  admin
Password: ver .env (variable JENKINS_ADMIN_PASSWORD)
```

### Apagar

```bash
docker compose down            # conserva el volumen jenkins_home y los secretos
./scripts/teardown.sh          # equivalente
./scripts/teardown.sh --purge  # apaga + borra volumen + borra secretos (reset total)
```

## Topología del stack

5 contenedores en una red bridge interna (`unir-calc-ci_jenkins`):

| Servicio | Imagen | Rol |
|---|---|---|
| `controller` | `jenkins/jenkins:lts-jdk21` + plugins + JCasC | Jenkins controller (UI 8080, label `controller`) |
| `agent-python` | `jenkins/ssh-agent:6.11.2-jdk21` + Python 3.11 + pytest/flake8/bandit/coverage/flask | Agente SSH (label `python`) |
| `agent-jmeter` | `jenkins/ssh-agent:6.11.2-jdk21` + JMeter 5.6.3 | Agente SSH (label `jmeter`) |
| `wiremock` | `wiremock/wiremock:3.9.1` | Mock HTTP de `/calc/sqrt/64` |
| `flask` | `python:3.11-slim` + Flask 3.0.3 | Sidecar con la app bajo test (volumen `./app:ro`) |

Conexión controller → agentes: **SSH** con par de claves declarado en Jenkins Configuration as Code (`infrastructure/jenkins-controller/casc.yaml`). La clave privada se monta como Docker secret; la pública se inyecta en los agentes vía variable de entorno.

## Manejo de secretos

Todos los secretos del stack se generan en local y nunca se publican.

| Artefacto | Origen | Estado en git |
|---|---|---|
| `infrastructure/secrets/controller_ssh_key{,.pub}` | `ssh-keygen` desde `bootstrap.sh` | gitignored |
| `.env` (incluye `JENKINS_ADMIN_PASSWORD` y `CONTROLLER_SSH_PUBKEY`) | `openssl rand` + lectura de pubkey desde `bootstrap.sh` | gitignored |

El repo público no contiene credenciales. Cualquier máquina que ejecute `bootstrap.sh` genera las suyas propias, independientes.

## Estructura del repo

```
.
├── Jenkinsfile              # Pipeline reto 1 (7 stages: Get Code, Unit, Rest, Static, Security, Performance, Coverage)
├── JENKINSFILE_agentes      # Pipeline reto 2 (4 ramas paralelas distribuidas en 3 agentes)
├── app/                     # Calculator + Flask REST API
├── test/
│   ├── unit/                # pytest unitarios (calc, util)
│   ├── rest/                # pytest integración HTTP
│   ├── wiremock/mappings/   # mocks HTTP
│   └── jmeter/flask.jmx     # JMeter test plan (parametrizable: -Jhost, -Jport)
├── infrastructure/
│   ├── jenkins-controller/  # Dockerfile + plugins.txt + casc.yaml
│   ├── jenkins-agent-python/
│   ├── jenkins-agent-jmeter/
│   ├── jenkins-agent-wiremock/
│   ├── flask/               # sidecar de la app
│   └── secrets/             # llaves SSH (gitignored)
├── scripts/
│   ├── bootstrap.sh         # arranca todo (genera secretos si faltan)
│   └── teardown.sh          # apaga (con --purge: borra volúmenes y secretos)
├── docker-compose.yml
├── pytest.ini
├── .coveragerc              # cobertura solo sobre calc.py y util.py
├── requirements.txt
└── .env.example             # plantilla; el .env real lo crea bootstrap.sh
```

## Crear los jobs en Jenkins (post-bootstrap)

El controller arranca con la configuración declarativa (JCasC) que ya provisiona los 2 agentes SSH. **Los jobs (`calc-ci-reto1`, `calc-ci-reto2`, `calc-ci-reto3`) hay que crearlos manualmente** desde la UI o vía REST API. Cada uno apunta a este repo, una rama y un Jenkinsfile:

| Job | Rama | Script |
|---|---|---|
| `calc-ci-reto1` | `master` | `Jenkinsfile` |
| `calc-ci-reto2` | `master` | `JENKINSFILE_agentes` |
| `calc-ci-reto3` | `feature_fix_coverage` | `Jenkinsfile` |

## Branches

- `master` — código estable + ambos pipelines (`Jenkinsfile`, `JENKINSFILE_agentes`).
- `feature_fix_coverage` — solo añade un test unitario en `test/unit/calc_test.py` que cubre `Calculator.divide(x, 0)`, llevando la cobertura a 100 % líneas + 100 % ramas (reto 3).

## Licencia

MIT.
