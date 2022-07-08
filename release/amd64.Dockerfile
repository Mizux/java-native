FROM quay.io/pypa/manylinux2014_x86_64:latest AS env

#############
##  SETUP  ##
#############
RUN yum -y update \
&& yum -y groupinstall 'Development Tools' \
&& yum -y install wget curl pcre-devel openssl redhat-lsb-core pkgconfig autoconf libtool zlib-devel which \
&& yum clean all \
&& rm -rf /var/cache/yum

ENTRYPOINT ["/usr/bin/bash", "-c"]
CMD ["/usr/bin/bash"]

# Install CMake 3.23.2
RUN wget -q --no-check-certificate "https://cmake.org/files/v3.23/cmake-3.23.2-linux-x86_64.sh" \
&& chmod a+x cmake-3.23.2-linux-x86_64.sh \
&& ./cmake-3.23.2-linux-x86_64.sh --prefix=/usr --skip-license \
&& rm cmake-3.23.2-linux-x86_64.sh

# Install Swig 4.0.2
RUN curl --location-trusted \
 --remote-name "https://downloads.sourceforge.net/project/swig/swig/swig-4.0.2/swig-4.0.2.tar.gz" \
 -o swig-4.0.2.tar.gz \
&& tar xvf swig-4.0.2.tar.gz \
&& rm swig-4.0.2.tar.gz \
&& cd swig-4.0.2 \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.0.2

# Install Java 8 SDK
RUN yum -y update \
&& yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel maven \
&& yum clean all \
&& rm -rf /var/cache/yum
ENV JAVA_HOME=/usr/lib/jvm/java

# Openssl 1.1
RUN yum -y update \
&& yum -y install epel-release \
&& yum repolist \
&& yum -y install openssl11

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###############
##  PROJECT  ##
###############
FROM env AS devel
WORKDIR /home/project
COPY . .

# Build delivery
FROM devel AS delivery

ENV GPG_ARGS ""

ARG PROJECT_TOKEN
ENV PROJECT_TOKEN ${PROJECT_TOKEN}
ARG PROJECT_DELIVERY
ENV PROJECT_DELIVERY ${PROJECT_DELIVERY:-all}
RUN ./release/build_delivery_linux.sh "${PROJECT_DELIVERY}"

# Publish delivery
FROM delivery AS publish
RUN ./release/publish_delivery_linux.sh "${PROJECT_DELIVERY}"
