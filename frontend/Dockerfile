FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

ARG VITE_ENABLE_ADD_PROJECT=false
ENV VITE_ENABLE_ADD_PROJECT=$VITE_ENABLE_ADD_PROJECT

ARG VITE_ENABLE_ADMIN=false
ENV VITE_ENABLE_ADMIN=$VITE_ENABLE_ADMIN

RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
