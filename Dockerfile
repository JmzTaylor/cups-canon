# base image
ARG ARCH=amd64
FROM $ARCH/debian:buster-slim

# args
ARG VCS_REF
ARG BUILD_DATE

# environment
ENV ADMIN_PASSWORD=admin

# labels
LABEL maintainer="Florian Schwab <me@ydkn.io>" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="ydkn/cups" \
  org.label-schema.description="Simple CUPS docker image" \
  org.label-schema.version="0.1" \
  org.label-schema.url="https://hub.docker.com/r/ydkn/cups" \
  org.label-schema.vcs-url="https://gitlab.com/ydkn/docker-cups" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.build-date=$BUILD_DATE

# install packages
RUN apt-get update \
  && apt-get install -y \
  sudo \
  cups \
  cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  libpopt0 \
  libatk1.0-0 \
  libpango1.0-0 \
  libxcursor1 \
  libgtk2.0-0 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# add print user
RUN adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin \
  && adduser admin sudo \
  && adduser admin lp \
  && adduser admin lpadmin

# disable sudo password checking
RUN echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

# enable access to CUPS
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid) \
  && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# copy /etc/cups for skeleton usage
RUN cp -rp /etc/cups /etc/cups-skel

# install deps
COPY libjpeg8_8d1-2_amd64.deb /
RUN dpkg --ignore-depends=multiarch-support -i /libjpeg8_8d1-2_amd64.deb
RUN rm /libjpeg8_8d1-2_amd64.deb

COPY libtiff4_3.9.7-2ubuntu1_amd64.deb /
RUN dpkg --ignore-depends=multiarch-support -i /libtiff4_3.9.7-2ubuntu1_amd64.deb
RUN rm /libtiff4_3.9.7-2ubuntu1_amd64.deb

COPY libpng12-0_1.2.54-1ubuntu1.1_amd64.deb /
RUN dpkg -i /libpng12-0_1.2.54-1ubuntu1.1_amd64.deb
RUN rm /libpng12-0_1.2.54-1ubuntu1.1_amd64.deb

# install canon drivers
COPY cnijfilter2_6.30-1_amd64.deb /
RUN dpkg -i /cnijfilter2_6.30-1_amd64.deb
RUN rm /cnijfilter2_6.30-1_amd64.deb

COPY cnijfilter-common_3.70-1_amd64.deb /
RUN dpkg -i /cnijfilter-common_3.70-1_amd64.deb
RUN rm /cnijfilter-common_3.70-1_amd64.deb

COPY cnijfilter-ip100series_3.70-1_amd64.deb /
RUN dpkg -i /cnijfilter-ip100series_3.70-1_amd64.deb
RUN rm /cnijfilter-ip100series_3.70-1_amd64.deb

# entrypoint
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT [ "docker-entrypoint.sh" ]

# default command
CMD ["cupsd", "-f"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631
