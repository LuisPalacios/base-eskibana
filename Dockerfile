#
# "elasticsearch+kibana" base by Luispa, Dec 2014
#
# -----------------------------------------------------

#
# Desde donde parto...
#

#
# Docker empezó a reemplazar imágenes 'dockerfile' con alternativas
# oficiales, así que he decidido integrar oracle-java7 dentro de mi Dockerfile
# Antiguo: 
#  FROM dockerfile/java:oracle-java7
#
# Pull base image.
#FROM dockerfile/ubuntu
FROM ubuntu:14.04

# Autor de este Dockerfile
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Instalo lo mínimo necesario para que funcione mi contenedor..
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

# Workaround para el Timezone, en vez de montar el fichero en modo read-only:
# 1) En el DOCKERFILE
RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint:
#     if [ -d '/config/tz' ]; then
#         dpkg-reconfigure -f noninteractive tzdata
#         echo "Hora actual: `date`"
#     fi
# 3) Al arrancar el contenedor, montar el volumen, a contiuación un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración:
#     echo "Europe/Madrid" > /Apps/data/tz/timezone
 
# ------- ------- ------- ------- ------- ------- -------
# Instalo en root
# ------- ------- ------- ------- ------- ------- -------
#
WORKDIR /

# ------- ------- ------- ------- ------- ------- -------
# Instalo java
# ------- ------- ------- ------- ------- ------- -------
#
# Instalo Java
RUN \
  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java7-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk7-installer


# Directorio de trabajo
WORKDIR /data

# Variable JAVA
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

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
