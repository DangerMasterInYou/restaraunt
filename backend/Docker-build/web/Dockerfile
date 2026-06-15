FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY flutter_application_restaraunt/ ./

RUN flutter pub get
RUN flutter build web --release --dart-define=API_SITE_URL=/api

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY backend/Docker-build/web/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
