FROM node:8.7.0

ADD . /opt/kamu
WORKDIR /opt/kamu
RUN npm install sharp
RUN npm install
RUN npm install -g pm2

EXPOSE 8081
CMD ["pm2", "start", "/opt/kamu/index.js", "-i", "0", "--no-daemon", "--no-color"]

