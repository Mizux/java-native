# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/rockylinux/rockylinux
FROM rockylinux/rockylinux:9 AS env

# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget openssl-devel cmake \
&& dnf -y groupinstall "Development Tools" \
&& dnf clean all \
&& rm -rf /var/cache/dnf
CMD [ "/usr/bin/bash" ]

# Install SWIG 4.2.1
RUN dnf -y update \
&& dnf -y install pcre2-devel \
&& dnf clean all \
&& rm -rf /var/cache/dnf \
&& wget -q "https://github.com/swig/swig/archive/refs/tags/v4.2.1.tar.gz" -O swig-4.2.1.tar.gz \
&& tar xvf swig-4.2.1.tar.gz \
&& rm swig-4.2.1.tar.gz \
&& cd swig-4.2.1 \
&& ./autogen.sh \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.2.1

# Install Java
RUN dnf -y update \
&& dnf -y install java-11-openjdk  java-11-openjdk-devel maven \
&& dnf clean all \
&& rm -rf /var/cache/dnf
RUN alternatives --set java /usr/lib/jvm/java-11-openjdk*.x86_64/bin/java
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Add the library src to our build env
FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake --version
RUN cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN cmake --build build --target test -v

# Test install rules
FROM env AS install_env
WORKDIR /home/sample
COPY --from=build /home/project/build/java/javanative-linux-x86-64/target/*.jar ./
RUN mvn org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
 -Dfile=javanative-linux-x86-64-1.0.jar
COPY --from=build /home/project/build/java/javanative-java/target/*.jar ./
RUN mvn org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
 -Dfile=javanative-java-1.0.jar

FROM install_env AS install_devel
COPY ci/samples .

FROM install_devel AS install_build
RUN mvn compile

FROM install_build AS install_test
RUN mvn test
