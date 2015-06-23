upstream backend {
  server {{ CONTAINER_HOST }};
}

server {
  listen 80;
  location / {
    proxy_pass http://backend;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
