# ================================
# STAGE 1: BUILD
# ================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --frozen-lockfile

COPY . .

# URLs de ambos backends (se inyectan en tiempo de build)
ARG VITE_VENTAS_API_URL
ARG VITE_DESPACHOS_API_URL
ENV VITE_VENTAS_API_URL=$VITE_VENTAS_API_URL
ENV VITE_DESPACHOS_API_URL=$VITE_DESPACHOS_API_URL

RUN npm run build

# ================================
# STAGE 2: RUNTIME con Nginx
# ================================
FROM nginx:1.25-alpine AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown appuser:appgroup /var/run/nginx.pid

USER appuser

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
