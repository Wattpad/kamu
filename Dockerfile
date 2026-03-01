FROM node:24

# node https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md#non-root-user
USER 1000

# Ensure /home/node exists and is owned by user 1000
RUN mkdir -p /home/node && chown -R 1000:1000 /home/node

COPY --chown=1000:1000 . /opt/kamu
WORKDIR /opt/kamu
RUN npm install sharp
RUN npm install
RUN npm install pm2

EXPOSE 8081
CMD ["/opt/kamu/node_modules/pm2/bin/pm2-docker", "-i", "32", "/opt/kamu/index.js"]

