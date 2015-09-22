FROM alpine:3.2

# Update apt repo
RUN apk --update add virtual \
	nodejs \
	sharp-run-deps \
	sharp-build-deps 

# Install dependencies
RUN apk --update add --virtual graphicsmagick

RUN apk --update add --virtual build-deps \
	gcc g++ make libc-dev \
	curl \
	automake \
	libtool \
	tar \
	gettext
RUN apk --update add --virtual dev-deps \
	glib-dev \
	libpng-dev \
	libwebp-dev \
	libexif-dev \
	libxml2-dev \
	libjpeg-turbo-dev
RUN apk --update add --virtual run-deps \
	glib \
	libpng \
	libwebp \
	libexif \
	libxml2 \
	libjpeg-turbo

RUN rm -rf /var/cache/apk/*

WORKDIR /tmp
ENV LIBVIPS_VERSION_MAJOR 7
ENV LIBVIPS_VERSION_MINOR 42
ENV LIBVIPS_VERSION_PATCH 2

# Build libvips
RUN LIBVIPS_VERSION=${LIBVIPS_VERSION_MAJOR}.${LIBVIPS_VERSION_MINOR}.${LIBVIPS_VERSION_PATCH} && \
  curl -O http://www.vips.ecs.soton.ac.uk/supported/${LIBVIPS_VERSION_MAJOR}.${LIBVIPS_VERSION_MINOR}/vips-${LIBVIPS_VERSION}.tar.gz && \
  tar zvxf vips-${LIBVIPS_VERSION}.tar.gz && \
  cd vips-${LIBVIPS_VERSION} && \
  ./configure --without-python --without-gsf  --with-webp --with-graphicsmagick && \
  make && \
  make install
ENV CPATH /usr/local/include
ENV LIBRARY_PATH /usr/local/lib

# add the code to the image and install deps
RUN mkdir -p /mnt/log /var/kamu/releases && ln -sf /var/kamu/releases/current /var/kamu/current
ADD . /var/kamu/releases/current
RUN rm /var/kamu/releases/current/node_modules/sharp
RUN cd /var/kamu/releases/current; npm install 
RUN npm install -g pm2
# link nodejs to node so pm2 can find it
RUN ln -s /usr/bin/nodejs /usr/local/bin/node

# Expose the Kamu port
EXPOSE 8081

# Run Kamu
CMD ["pm2", "start", "/var/kamu/releases/current/index.js", "-i", "0", "--no-daemon"]
