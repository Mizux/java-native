# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/centos
FROM centos:latest AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget openssl-devel \
&& dnf -y groupinstall "Development Tools" \
&& dnf clean all \
&& rm -rf /var/cache/dnf

# Install CMake 3.19.2
RUN wget "https://cmake.org/files/v3.19/cmake-3.19.2-Linux-x86_64.sh" \
&& chmod a+x cmake-3.19.2-Linux-x86_64.sh \
&& ./cmake-3.19.2-Linux-x86_64.sh --prefix=/usr/local/ --skip-license \
&& rm cmake-3.19.2-Linux-x86_64.sh

# Install SWIG 4.0.2
RUN dnf -y update \
&& dnf -y install pcre-devel \
&& dnf clean all \
&& rm -rf /var/cache/dnf \
&& wget "https://downloads.sourceforge.net/project/swig/swig/swig-4.0.2/swig-4.0.2.tar.gz" \
&& tar xvf swig-4.0.2.tar.gz \
&& rm swig-4.0.2.tar.gz \
&& cd swig-4.0.2 \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.0.2

# Java install
RUN dnf -y update \
&& dnf -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel maven \
&& dnf clean all \
&& rm -rf /var/cache/dnf

# Add the library src to our build env
FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake -version
RUN cmake -S. -Bbuild -DSKIP_GPG=ON
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN cmake --build build --target test -v

FROM env AS install_env
COPY --from=build /home/project/build/java/javanative-linux-x86-64/target/*.jar ./
RUN mvn org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
 -Dfile=javanative-linux-x86-64-1.0.jar
COPY --from=build /home/project/build/java/javanative-java/target/*.jar ./
RUN mvn org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
 -Dfile=javanative-java-1.0.jar

FROM install_env AS install_devel
WORKDIR /home/sample
COPY ci/samples .

FROM install_devel AS install_build
RUN mvn compile

FROM install_build AS install_test
RUN mvn test
