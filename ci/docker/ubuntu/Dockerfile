# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/ubuntu
FROM ubuntu:rolling AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN apt-get update -qq \
&& apt-get install -yq git wget libssl-dev build-essential \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Install CMake 3.17.2
RUN wget "https://cmake.org/files/v3.17/cmake-3.17.2-Linux-x86_64.sh" \
&& chmod a+x cmake-3.17.2-Linux-x86_64.sh \
&& ./cmake-3.17.2-Linux-x86_64.sh --prefix=/usr/local/ --skip-license \
&& rm cmake-3.17.2-Linux-x86_64.sh
# Install swig
RUN apt-get update -qq \
&& apt-get install -yq swig \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Java install
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install -yq default-jdk maven \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV JAVA_HOME=/usr/lib/jvm/default-java
CMD [ "/usr/bin/bash" ]

FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake -S. -Bbuild
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN cmake --build build --target test -v
