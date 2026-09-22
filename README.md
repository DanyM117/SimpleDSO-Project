# DevSecOps Project: Secure CI/CD Pipeline with AWS OIDC

Este repositorio demuestra la implementación de un pipeline DevSecOps automatizado para una aplicación web en Python. La arquitectura integra pruebas de seguridad en múltiples etapas (Shift-Left) y utiliza federación de identidades (Zero-Trust) para despliegues en infraestructura de AWS, eliminando la exposición de credenciales estáticas.

## Arquitectura del Pipeline (GitHub Actions)

El flujo de trabajo se ejecuta bajo un modelo de detención en cascada (Fail-Fast) dividido en tres fases principales:

1. **Integración Continua y Análisis Estático (SAST / SCA)**
   - **Calidad de Código:** Evaluación de sintaxis y convención de estándares mediante `Ruff`.
   - **SAST (Static Application Security Testing):** Escaneo de vulnerabilidades integradas en el código fuente utilizando `Bandit`.
   - **SCA (Software Composition Analysis):** Auditoría de la cadena de suministro y mitigación de CVEs públicos en librerías de terceros con `pip-audit`.

2. **Construcción y Escaneo de Contenedor**
   - Construcción de la imagen Docker aplicando el principio de menor privilegio.
   - Escaneo estructural del artefacto final utilizando `Trivy`. El pipeline bloquea el despliegue automáticamente si se detectan vulnerabilidades a nivel de sistema operativo base o binarios con severidad `HIGH` o `CRITICAL`.

3. **Despliegue Continuo (CD) y Autenticación OIDC**
   - **Federación de Identidades:** GitHub Actions asume un rol de AWS IAM mediante OpenID Connect (OIDC) para obtener tokens STS de corta duración en memoria.
   - Restricción estricta de confianza validando los *Immutable Subject Claims* del token de GitHub (IDs numéricos inmutables de repositorio y organización) para prevenir escalada de privilegios o *Repo Spoofing*.
   - Publicación automatizada de la imagen validada hacia un registro privado en AWS Elastic Container Registry (ECR).

## Prácticas de Seguridad Implementadas

- **Autenticación Secretless:** Eliminación absoluta de llaves de acceso a largo plazo (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) en el gestor de secretos del repositorio.
- **Shift-Left Security:** Detección temprana de vulnerabilidades lógicas y dependencias comprometidas antes de empaquetar el artefacto o aprovisionar infraestructura.
- **Hardening de Contenedores:**
  - Reducción drástica de la superficie de ataque utilizando imágenes base de huella mínima (Alpine Linux).
  - Prevención de escalada de privilegios a nivel de sistema operativo anfitrión ejecutando el servicio de la aplicación exclusivamente mediante un usuario no-root (`USER appuser`) y gestión estricta de permisos de sistema de archivos.

## Stack Tecnológico

- **Aplicación Base:** Python 3.12, Flask
- **Orquestación CI/CD:** GitHub Actions
- **Herramientas de Seguridad:** Ruff, Bandit, pip-audit, Aqua Trivy
- **Nube (AWS):** IAM (OIDC Identity Providers), Elastic Container Registry (ECR)