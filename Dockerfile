FROM alpine:3.2

RUN apk upgrade --update

RUN apk add nodejs \
  python \
  git \
  gcc g++ make libc-dev \
  curl \
  automake \
  libtool \
  tar \
  gettext \
  glib-dev \
  libpng-dev \
  libwebp-dev \
  libexif-dev \
  libxml2-dev \
  libjpeg-turbo-dev \
  glib \
  libpng \
  libwebp \
  libexif \
  libxml2 \
  libjpeg-turbo \
  gtk-doc \
  gobject-introspection-dev \
  autoconf \
  swig

#RUN apk add graphicsmagick

RUN rm -rf /var/cache/apk/*

# Build libvips
WORKDIR /tmp
RUN git clone http://github.com/jcupitt/libvips.git && cd libvips && \
  ./bootstrap.sh && \
  ./configure --without-python --without-gsf --with-webp --with-graphics && \
  make && \
  make install
ENV CPATH /usr/local/include
ENV LIBRARY_PATH /usr/local/lib

# Install sharp

# add the code to the image and install deps
RUN mkdir -p /mnt/log /var/kamu/releases && ln -sf /var/kamu/releases/current /var/kamu/current
ADD . /var/kamu/releases/current
RUN rm -rf /var/kamu/releases/current/node_modules/sharp
RUN git clone https://github.com/lovell/sharp.git /var/kamu/releases/current/node_modules/sharp
RUN cd /var/kamu/releases/current/node_modules/sharp; npm install
RUN cd /var/kamu/releases/current; npm install 
RUN npm install -g pm2
# link nodejs to node so pm2 can find it
RUN ln -s /usr/bin/nodejs /usr/local/bin/node

# Expose the Kamu port
EXPOSE 8081

# Run Kamu
CMD ["pm2", "start", "/var/kamu/releases/current/index.js", "-i", "0", "--no-daemon"]
