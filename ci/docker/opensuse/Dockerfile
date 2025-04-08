# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/r/opensuse/tumbleweed
FROM opensuse/tumbleweed AS env

# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN zypper refresh \
&& zypper install -y git patch gcc gcc-c++ cmake \
&& zypper clean -a
ENV CC=gcc CXX=g++
CMD [ "/usr/bin/bash" ]

# Install swig
RUN zypper update -y \
&& zypper install -y swig \
&& zypper clean -a

# Java install
RUN zypper update -y \
&& zypper install -y java-17-openjdk-devel maven \
&& zypper clean -a
ENV JAVA_HOME=/usr/lib64/jvm/java-17-openjdk

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
RUN CTEST_OUTPUT_ON_FAILURE=1 cmake --build build --target test -v

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
