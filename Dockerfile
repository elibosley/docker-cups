# base image

FROM --platform=amd64 debian:buster-slim
# args
ARG VCS_REF
ARG BUILD_DATE

# environment
ENV ADMIN_PASSWORD=admin

# labels
LABEL maintainer="Eli Bosley <eli@bosley.dev>" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="elibosley/cups" \
  org.label-schema.description="Simple CUPS docker image" \
  org.label-schema.version="0.1" \
  org.label-schema.url="https://hub.docker.com/r/elibosley/cups" \
  org.label-schema.vcs-url="https://github.com/elibosley/docker-cups" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.build-date=$BUILD_DATE

# install packages
RUN apt-get update \
  && apt-get install -y \
  sudo \
  build-essential \
  cmake \
  curl \
  git \
  libcups2-dev \
  qpdf \
  cups \
  cups-bsd \
  cups-filters \
  usbutils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


ARG BRPRINTER_VERSION=2.2.3-1
RUN curl -O https://download.brother.com/welcome/dlf006893/linux-brprinter-installer-${BRPRINTER_VERSION}.gz \
  && gunzip linux-brprinter-installer-${BRPRINTER_VERSION}.gz \
  && chmod +x linux-brprinter-installer-${BRPRINTER_VERSION} \
  && ./linux-brprinter-installer-${BRPRINTER_VERSION} HL-L2300D \
  && rm linux-brprinter-installer-${BRPRINTER_VERSION}

# install BRLaser
#RUN git clone https://github.com/pdewacht/brlaser.git \
#  && cd brlaser \
#  && cmake . \
#  && make \
#  && make install

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

# entrypoint
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT [ "docker-entrypoint.sh" ]

# default command
CMD ["cupsd", "-f"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631
