# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/fedora
FROM fedora:latest AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget \
&& dnf -y groupinstall "Development Tools" \
&& dnf -y install gcc-c++ cmake \
&& dnf clean all
# Install swig
RUN dnf -y update \
&& dnf -y install swig \
&& dnf clean all
# Java install
RUN dnf -y update \
&& dnf -y install java-1.8.0-openjdk-devel maven \
&& dnf clean all
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk
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
