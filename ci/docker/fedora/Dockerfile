# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/fedora
FROM fedora:latest AS env

# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget \
&& dnf -y install @development-tools \
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
ENV JAVA_HOME=/usr/lib/jvm/java-openjdk

# Add the library src to our build env
FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake --version
RUN cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DSKIP_GPG=ON
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
