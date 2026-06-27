# Frontend — Despacho Dashboard 📦

SPA desarrollada con **React 18 + Vite 5**, servida con **nginx**, para la gestión de despachos y ventas de Innovatech Chile.

---

## 🏗️ Arquitectura de despliegue (EP3/EFT — ECS Fargate)

```
Internet
   │
   ▼
Application Load Balancer (innovatech-alb)
   │  ruta: / (default)
   ▼
ECS Fargate — Service: innovatech-svc-frontend
   │  Task Definition: innovatech-frontend (CPU 256 / 512 MB)
   │  Container: frontend — nginx, puerto 8080 (no-root)
   ▼
   ├──► /api/v1/despachos*  → innovatech-svc-despachos
   └──► /api/v1/ventas*     → innovatech-svc-ventas
```

- **Puerto interno 8080 (no 80):** el contenedor corre como usuario no-root (`appuser`), y los puertos <1024 requieren privilegios de root. Usar un puerto no privilegiado mantiene la imagen endurecida sin sacrificar funcionalidad. El ALB sigue expuesto públicamente en el puerto 80 — el cambio es 100% interno.
- **Comunicación con los backends:** mismo dominio (el del ALB), routing por path. Las variables `VITE_DESPACHOS_API_URL` y `VITE_VENTAS_API_URL` se inyectan en **tiempo de build** apuntando ambas al DNS del ALB; el código antepone `/api/v1/despachos` y `/api/v1/ventas` respectivamente, calzando con las listener rules del ALB.
- **Imagen:** publicada en Amazon ECR (`innovatech-frontend`), con escaneo de vulnerabilidades automático (`scanOnPush`).
- **Observabilidad:** logs en CloudWatch (`/ecs/innovatech-frontend`).

---

## ⚙️ Variables de entorno (build-time)

| Variable | Descripción |
|---|---|
| `VITE_DESPACHOS_API_URL` | URL base hacia el backend de despachos (= DNS del ALB) |
| `VITE_VENTAS_API_URL` | URL base hacia el backend de ventas (= DNS del ALB, mismo valor) |

---

## 🐳 Desarrollo local

```bash
npm install
npm run dev
```

O con Docker:
```bash
docker compose up --build
```

---

## 🔄 CI/CD

El pipeline (`.github/workflows/deploy.yml`) se dispara en cada push a la rama `deploy`:

1. Build de la imagen Docker (multi-stage: Node para compilar, nginx para servir), inyectando las URLs de los backends como build-args.
2. Push a Amazon ECR (tags `latest` y hash del commit).
3. Registro de nueva revisión de la Task Definition.
4. Deploy automático al servicio ECS, esperando estabilidad.

**Secrets requeridos en GitHub:**
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (credenciales temporales de AWS Academy Learner Lab)
- `VITE_DESPACHOS_API_URL`, `VITE_VENTAS_API_URL` (ambas con el DNS del ALB)

---

## 🔒 Seguridad

- Contenedor corre como usuario no-root (`appuser`).
- Vulnerabilidades de dependencias npm auditadas con `npm audit` (ver informe técnico para detalle y justificación de las que se dejaron sin resolver).
