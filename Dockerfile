FROM alpine:3.14
MAINTAINER rupor (https://github.com/rupor-github/serve-svn)

ARG SVN_UID=1000
ARG SVN_GID=1000
ENV SRV_HOST_PORT=

ENV S6_OVERLAY_VERSION=2.2.0.3
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer / && rm /tmp/s6-overlay-amd64-installer

RUN apk add --no-cache shadow ca-certificates \
    apache2 apache2-utils \
	php7 php7-apache2 php7-session php7-json php7-xml && \
	mkdir -p /run/apache2/

# ensure, apache user can handle svn
RUN if [ "$SVN_UID" != "100" ] ; then usermod -u $SVN_UID apache && groupmod -g $SVN_GID apache ; fi

# For some reason Alpine subversion build does not have svnauthz (or any svn tools for this matter) - have to build my own
COPY replace/subversion-1.14.1-r3.apk /tmp/
RUN apk add --no-cache --allow-untrusted /tmp/subversion-1.14.1-r3.apk && \
	rm /tmp/*.apk && \
	mkdir /home/svn/ && \
	mkdir /etc/subversion/ && touch /etc/subversion/passwd

COPY root /

ENV WEBSVN_VERSION=2.6.1
ADD https://github.com/websvnphp/websvn/archive/refs/tags/${WEBSVN_VERSION}.tar.gz /var/www/
WORKDIR /var/www
RUN tar -xvf ${WEBSVN_VERSION}.tar.gz && \
	mv websvn-${WEBSVN_VERSION} websvn && \
	rm ${WEBSVN_VERSION}.tar.gz

COPY replace/config.php /var/www/websvn/include/config.php
RUN chmod a+w /etc/subversion/* && \
	chmod a+w /home/svn && \
	chmod a+w /var/www/websvn/include/config.php

ENV HOME /home
EXPOSE 80 3690

ENTRYPOINT ["/init"]
CMD []
