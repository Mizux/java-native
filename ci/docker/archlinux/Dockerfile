# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/archlinux/
FROM archlinux/base AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN pacman -Syu --noconfirm git base-devel cmake
# Install swig
RUN pacman -Syu --noconfirm swig
# Java install
RUN pacman -Syu --noconfirm jdk-openjdk maven
ENV JAVA_HOME=/usr/lib/jvm/default
CMD [ "/bin/bash" ]

FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake -S. -Bbuild
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN cmake --build build --target test -v
