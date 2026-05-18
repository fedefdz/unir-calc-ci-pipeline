# CP1 — Pipeline CI sobre Jenkins (Podman)

Resolución del **Caso Práctico 1** del Experto Universitario en DevOps & Cloud (UNIR).

Pipeline de CI sobre Jenkins orquestado con Podman para una librería Python de calculadora con microservicios Flask. Cubre apartados A (CP1.1) y B (CP1.2).

## Estado por apartado

| Apartado | Nota | Entrega | Estado |
|---|---|---|---|
| CP1.1 (Apartado A) | 0 % — se resuelve en clase | — | base reutilizada |
| **CP1.2 (Apartado B)** | **35 %** | **Plantilla CP1-2 → PDF en Canvas** | en curso |
| CP1.3 (Apartado C) | 0 % — se resuelve en clase | — | pendiente |
| CP1.4 (Apartado D) | 65 % | Plantilla CP1-4 → PDF en Canvas | pendiente |

## Quickstart

```bash
# Levanta todo el stack (Jenkins controller + 3 agentes + Wiremock)
podman-compose -f infrastructure/podman-compose.yml up -d

# Jenkins UI
open http://localhost:8080
```

## Estructura

```
cp1/
├── app/                   # Calculator + Flask REST API
├── test/                  # unit / rest / wiremock / jmeter
├── Jenkinsfile            # pipeline single-agent (Reto 1)
├── Jenkinsfile_agentes    # pipeline distribuido en 3 agentes (Reto 2)
├── infrastructure/        # Containerfiles + podman-compose
├── scripts/               # bootstrap/teardown
└── docs/
    ├── cheatbook.md       # log de comandos
    ├── 01-overview.md     # arquitectura
    ├── 02-prerequisites.md
    ├── ...
    └── adr/               # decisiones arquitectónicas
```

## Decisiones de fondo

- **Podman, no Docker**: rootless, sin daemon, sin licencia, mismo CLI, alineado con el stack de CP2.
- **Jenkins en contenedor**: aislamiento del host; tres agentes especializados modelan el reto 2 de CP1.2 sin necesidad de VMs adicionales.
- **Containerfile por agente**: cada agente trae solo su toolset (Python+pytest, JMeter, Wiremock). Pipelines más limpios; menos drift entre alumnos.

## Branches

- `master` — código estable + pipelines principales (`Jenkinsfile`, `Jenkinsfile_agentes`).
- `feature_fix_coverage` — pruebas unitarias ampliadas para alcanzar cobertura 100/100 (CP1.2 reto 3).

## Documentación

Toda la doc operativa está en [`docs/`](docs/). Punto de entrada: [`docs/01-overview.md`](docs/01-overview.md).

## Licencia

MIT.
