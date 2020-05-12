# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/r/opensuse/tumbleweed
FROM opensuse/tumbleweed AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN zypper update -y \
&& zypper install -y git gcc gcc-c++ cmake \
&& zypper clean -a
ENV CC=gcc CXX=g++
# Install swig
RUN zypper update -y \
&& zypper install -y swig \
&& zypper clean -a
# Java install
RUN zypper update -y \
&& zypper install -y java-1_8_0-openjdk-devel maven \
&& zypper clean -a
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
