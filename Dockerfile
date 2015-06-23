FROM ubuntu:trusty

# Update apt repo
RUN apt-get update
RUN apt-get install -y nodejs npm

# add the code to the image and install deps
RUN mkdir -p /mnt/log /var/kamu/releases && ln -sf /var/kamu/releases/current /var/kamu/current
ADD . /var/kamu/releases/current
RUN cd /var/kamu/releases/current; npm install 
RUN npm install -g pm2
# link nodejs to node so pm2 can find it
RUN ln -s /usr/bin/nodejs /usr/local/bin/node

# Expose the Kamu port
EXPOSE 8081

# Run Kamu
CMD ["pm2", "start", "/var/kamu/releases/current/index.js", "-i", "0", "--no-daemon"]
