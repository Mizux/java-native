# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/almalinux
FROM almalinux:latest AS env

# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget openssl-devel cmake \
&& dnf -y group install "Development Tools" \
&& dnf clean all \
&& rm -rf /var/cache/dnf
CMD [ "/usr/bin/bash" ]

# Install SWIG 4.3.0
RUN dnf -y update \
&& dnf -y install pcre2-devel \
&& dnf clean all \
&& rm -rf /var/cache/dnf \
&& wget -q "https://downloads.sourceforge.net/project/swig/swig/swig-4.3.0/swig-4.3.0.tar.gz" \
&& tar xvf swig-4.3.0.tar.gz \
&& rm swig-4.3.0.tar.gz \
&& cd swig-4.3.0 \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.3.0

# Install Java
RUN dnf -y update \
&& dnf -y install java-21-openjdk  java-21-openjdk-devel maven \
&& dnf clean all \
&& rm -rf /var/cache/dnf
RUN alternatives --set java /usr/lib/jvm/java-21-openjdk/bin/java
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# Add the library src to our build env
FROM env AS devel
WORKDIR /home/project
COPY . .

ARG CMAKE_BUILD_PARALLEL_LEVEL
ENV CMAKE_BUILD_PARALLEL_LEVEL=${CMAKE_BUILD_PARALLEL_LEVEL:-4}

FROM devel AS build
RUN cmake --version
RUN cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN CTEST_OUTPUT_ON_FAILURE=1 cmake --build build --target test -v

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
COPY ci/sample .

FROM install_devel AS install_build
RUN mvn compile

FROM install_build AS install_test
RUN mvn test
