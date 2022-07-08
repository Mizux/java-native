# To build it on x86_64 please read
# https://github.com/multiarch/qemu-user-static#getting-started

# Use yum
#FROM --platform=linux/arm64 centos:7 AS env
#FROM quay.io/pypa/manylinux2014_aarch64:latest AS env
# Use dnf
FROM quay.io/pypa/manylinux_2_28_aarch64:latest AS env

#############
##  SETUP  ##
#############
RUN dnf -y update \
&& dnf -y groupinstall 'Development Tools' \
&& dnf -y install wget curl pcre-devel openssl redhat-lsb-core pkgconfig autoconf libtool zlib-devel which \
&& dnf clean all \
&& rm -rf /var/cache/dnf

ENTRYPOINT ["/usr/bin/bash", "-c"]
CMD ["/usr/bin/bash"]

# Install CMake 3.23.2
RUN wget -q --no-check-certificate "https://cmake.org/files/v3.23/cmake-3.23.2-linux-aarch64.sh" \
&& chmod a+x cmake-3.23.2-linux-aarch64.sh \
&& ./cmake-3.23.2-linux-aarch64.sh --prefix=/usr --skip-license \
&& rm cmake-3.23.2-linux-aarch64.sh

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
RUN dnf -y update \
&& dnf -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel maven \
&& dnf clean all \
&& rm -rf /var/cache/dnf
ENV JAVA_HOME=/usr/lib/jvm/java

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

#ENV GPG_ARGS ""

ARG PROJECT_TOKEN
ENV PROJECT_TOKEN ${PROJECT_TOKEN}
ARG PROJECT_DELIVERY
ENV PROJECT_DELIVERY ${PROJECT_DELIVERY:-all}
RUN ./release/build_delivery_linux.sh "${PROJECT_DELIVERY}"

# Publish delivery
FROM delivery AS publish
RUN ./release/publish_delivery_linux.sh "${PROJECT_DELIVERY}"
