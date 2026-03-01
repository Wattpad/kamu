FROM node:24

RUN useradd -m --uid 999 --system wattpad

ADD . /opt/kamu
WORKDIR /opt/kamu
RUN npm install sharp
RUN npm install
RUN npm install -g pm2
RUN chown -R wattpad /opt/kamu

USER 999

EXPOSE 8081
CMD ["pm2-docker", "-i", "32", "/opt/kamu/index.js"]

