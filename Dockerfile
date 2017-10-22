FROM node:8.7.0

ADD . /opt/kamu
WORKDIR /opt/kamu
RUN npm install sharp
RUN npm install
RUN npm install -g pm2

EXPOSE 8081
CMD ["pm2-docker", "-i", "8", "/opt/kamu/index.js"]

