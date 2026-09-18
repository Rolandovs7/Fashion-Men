# ============================================================
# Dockerfile - Frontend MenStyle (Angular)
# ============================================================
FROM node:20-alpine AS build

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependencias
RUN npm ci

# Copiar código
COPY . .

# Build de producción
RUN npm run build -- --configuration production

# ============================================================
# Stage 2: Servidor Nginx
# ============================================================
FROM nginx:alpine

# Copiar build de Angular a nginx
COPY --from=build /app/dist/frontend/browser /usr/share/nginx/html

# Configuración de nginx para SPA
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
