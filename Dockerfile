# Stage 1 - Build React frontend
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN export NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build

# Stage 2 - Build backend
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Copy frontend build into backend's public folder
COPY --from=frontend-build /app/frontend/build ./frontend/build

EXPOSE 3000
CMD ["npm", "start"]
