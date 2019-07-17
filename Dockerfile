ARG NGINX_VERSION=1.16.0

##############################
# Build the NGINX-build image.
FROM alpine:3.10 as build-nginx
ARG NGINX_VERSION

# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  git \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
    git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module \
  --conf-path=/opt/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --error-log-path=/opt/nginx/logs/error.log \
  --http-log-path=/opt/nginx/logs/access.log \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

##########################
# Build the release image.
FROM alpine:3.10
LABEL MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>

RUN apk add --update \
  ca-certificates \
  ffmpeg \
  openssl \
  pcre \
  lame \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /opt/nginx /opt/nginx

# Add NGINX config and static files.
ADD nginx.conf /opt/nginx/nginx.conf
RUN mkdir -p /opt/data && mkdir /www
ADD static /www/static

EXPOSE 1935
EXPOSE 80

CMD ["/opt/nginx/sbin/nginx"]
