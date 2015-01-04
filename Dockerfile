#
# "elasticsearch+kibana" base by Luispa, Dec 2014
#
# -----------------------------------------------------

#
# Desde donde parto...
#
#FROM debian:jessie
FROM dockerfile/java:oracle-java7

# Autor de este Dockerfile
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Actualizo el sistema operativo e instalo lo mínimo
#
RUN apt-get update && \
    apt-get -y install 	locales \
    					net-tools \
                       	vim \
                       	supervisor \
                       	wget \
                       	curl \
                       	tcpdump \
                        net-tools \
                       	nginx-full

# HOME
ENV HOME /root

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# ------- ------- ------- ------- ------- ------- -------
# Instalo en root
# ------- ------- ------- ------- ------- ------- -------
#
WORKDIR /

# ------- ------- ------- ------- ------- ------- -------
# Instalo ElasticSearch
# ------- ------- ------- ------- ------- ------- -------
#
ENV ES_PKG_NAME elasticsearch-1.4.1
RUN \
  cd / && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz && \
  tar xvzf $ES_PKG_NAME.tar.gz && \
  rm -f $ES_PKG_NAME.tar.gz && \
  mv /$ES_PKG_NAME /elasticsearch

EXPOSE 9200
EXPOSE 9300

# ------- ------- ------- ------- ------- ------- -------
# Instalo Kibana
# ------- ------- ------- ------- ------- ------- -------
RUN cd / && \
	curl https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz | tar xz && \
    mv kibana-* kibana

EXPOSE 80

# Configuracion de nginx y kibana
ADD nginx.conf /etc/nginx/
RUN sed -i -e 's|elasticsearch:.*|elasticsearch: "http://"+window.location.hostname + ":" + window.location.port,|' /kibana/config.js


#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]
