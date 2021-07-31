FROM ubuntu:focal
RUN useradd -m -s /bin/bash opensrf
RUN echo "export PATH=\$PATH:/openils/bin" >> /home/opensrf/.bashrc

RUN apt-get update

RUN apt-get install -y git build-essential vim netcat iputils-ping

# install OpenSRF

RUN mkdir -p /src/OpenSRF

RUN git clone git://git.evergreen-ils.org/OpenSRF.git /src/OpenSRF
# if you wish to build from a local source tree, use something like this instead:
# COPY src/opensrf /src/OpenSRF

WORKDIR /src/OpenSRF

ENV DEBIAN_FRONTEND=noninteractive
RUN cd /src/OpenSRF && make -f src/extras/Makefile.install ubuntu-focal

RUN autoreconf -i

RUN ./configure --prefix=/openils --sysconfdir=/openils/conf && make

RUN make install

RUN echo /openils/lib > /etc/ld.so.conf.d/opensrf.conf && ldconfig

RUN chown -R opensrf:opensrf /openils
RUN touch /openils/conf/opensrf.xml && \
	touch /openils/conf/opensrf_core.xml && \
	touch /home/opensrf/.srfsh

RUN mkdir /services && \
	mkdir -p /services/router && \
	mkdir -p /services/opensrf.math

COPY wrapper.sh /openils/bin/wrapper.sh
RUN chmod +x /openils/bin/wrapper.sh

CMD [ "/openils/bin/wrapper.sh" ]