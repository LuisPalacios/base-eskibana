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
#
# FROM dockerfile/java:oracle-java7
# FROM dockerfile/ubuntu
# FROM ubuntu:14.04
# FROM debian:jessie
FROM java:7

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
# Método antiguo desde dockerfile/ubuntu
#RUN \
#  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
#  add-apt-repository -y ppa:webupd8team/java && \
#  apt-get update && \
#  apt-get install -y oracle-java7-installer && \
#  rm -rf /var/lib/apt/lists/* && \
#  rm -rf /var/cache/oracle-jdk7-installer

# Método nuevo, fuente: https://github.com/William-Yeh/docker-java7/blob/master/Dockerfile
#RUN \
#    echo "===> add webupd8 repository..."  && \
#    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
#    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
#    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886  && \
#    apt-get update  && \
#    \
#    \
#    echo "===> install Java"  && \
#    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
#    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
#    DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java7-installer oracle-java7-set-default  && \
#    \
#    \
#    echo "===> clean up..."  && \
#    rm -rf /var/cache/oracle-jdk7-installer  && \
#    apt-get clean  && \
#    rm -rf /var/lib/apt/lists/*


# Directorio de trabajo
WORKDIR /data

# Variable JAVA
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

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
