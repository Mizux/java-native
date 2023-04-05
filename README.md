Github-CI:
[![Build Status][github_linux_status]][github_linux_link]
[![Build Status][github_macos_status]][github_macos_link]
[![Build Status][github_windows_status]][github_windows_link]
[![Build Status][github_amd64_docker_status]][github_amd64_docker_link]

[github_linux_status]: https://github.com/Mizux/java-native/actions/workflows/amd64_linux.yml/badge.svg
[github_linux_link]: https://github.com/Mizux/java-native/actions/workflows/amd64_linux.yml
[github_macos_status]: https://github.com/Mizux/java-native/actions/workflows/amd64_macos.yml/badge.svg
[github_macos_link]: https://github.com/Mizux/java-native/actions/workflows/amd64_macos.yml
[github_windows_status]: https://github.com/Mizux/java-native/actions/workflows/amd64_windows.yml/badge.svg
[github_windows_link]: https://github.com/Mizux/java-native/actions/workflows/amd64_windows.yml
[github_amd64_docker_status]: https://github.com/Mizux/java-native/actions/workflows/amd64_docker.yml/badge.svg
[github_amd64_docker_link]: https://github.com/Mizux/java-native/actions/workflows/amd64_docker.yml

# Introduction
<nav for="project"> |
<a href="#requirement">Requirement</a> |
<a href="#codemap">Codemap</a> |
<a href="#dependencies">Dependencies</a> |
<a href="#build-process">Build</a> |
<a href="ci/README.md">CI</a> |
<a href="#appendices">Appendices</a> |
<a href="#license">License</a> |
</nav>

This is an example of how to create a Modern [CMake](https://cmake.org/) C++/Java Project.

This project aim to explain how you build a Java 1.8 native (for win32-x86-64,
linux-x86-64 and darwin-x86-64) maven multiple package using [`mvn`](http://maven.apache.org/)
and few [POM.xml](http://maven.apache.org/pom.html).  
e.g. You have a cross platform C++ library and a JNI wrapper on it thanks to SWIG.<br>
Then you want to provide a cross-platform Maven package to consume it in a
Maven project...

This project should run on:

* MacOS (darwin-aarch64, darwin-x86-64)
* GNU/Linux (linux-aarch64, linux-x86-64)
* Windows (win32-x86-64)

## Requirement
You'll need:

* "CMake >= 3.18".
* "Java SDK >= 1.8" and "Maven >= 3.6".

Please verify you also have the `JAVA_HOME` environment variable set otherwise CMake
and Maven won't be able to find your Java SDK.

## Codemap
The project layout is as follow:

* [CMakeLists.txt](CMakeLists.txt) Top-level for [CMake](https://cmake.org/cmake/help/latest/) based build.
* [cmake](cmake) Subsidiary CMake files.
  * [java.cmake](cmake/java.cmake) All internall Java CMake stuff.

* [ci](ci) Root directory for continuous integration.

* [Foo](Foo) Root directory for `Foo` library.
  * [CMakeLists.txt](Foo/CMakeLists.txt) for `Foo`.
  * [include](Foo/include) public folder.
    * [foo](Foo/include/foo)
      * [Foo.hpp](Foo/include/foo/Foo.hpp)
  * [src](Foo/src) private folder.
    * [src/Foo.cpp](Foo/src/Foo.cpp)
  * [java](Foo/java)
    * [CMakeLists.txt](Foo/java/CMakeLists.txt) for `Foo` Java.
    * [foo.i](Foo/java/foo.i) SWIG Java wrapper.
* [Bar](Bar) Root directory for `Bar` library.
  * [CMakeLists.txt](Bar/CMakeLists.txt) for `Bar`.
  * [include](Bar/include) public folder.
    * [bar](Bar/include/bar)
      * [Bar.hpp](Bar/include/bar/Bar.hpp)
  * [src](Bar/src) private folder.
    * [src/Bar.cpp](Bar/src/Bar.cpp)
  * [java](Bar/java)
    * [CMakeLists.txt](Bar/java/CMakeLists.txt) for `Bar` Java.
    * [bar.i](Bar/java/bar.i) SWIG Java wrapper.
* [FooBar](FooBar) Root directory for `FooBar` library.
  * [CMakeLists.txt](FooBar/CMakeLists.txt) for `FooBar`.
  * [include](FooBar/include) public folder.
    * [foobar](FooBar/include/foobar)
      * [FooBar.hpp](FooBar/include/foobar/FooBar.hpp)
  * [src](FooBar/src) private folder.
    * [src/FooBar.cpp](FooBar/src/FooBar.cpp)
  * [java](FooBar/java)
    * [CMakeLists.txt](FooBar/java/CMakeLists.txt) for `FooBar` Java.
    * [foobar.i](FooBar/java/foobar.i) SWIG Java wrapper.

* [java](java) Root directory for Java template files
  * [base.i](java/base.i) Generic SWIG stuff (e.g. fixing int64 java typemaps).
  * [pom-native.xml.in](java/) POM template to build the native project.
  * [Loader.java](java/Loader.java) Unpack and load the correct native libraries.
  * [pom-local.xml.in](java/pom-local.xml.in) POM template to build the "pure" Java project.
  * [Test.java](java/Test.java) Test source code to verify the Java wrapper is working.
  * [pom-test.xml.in](java/pom-test.xml.in) POM template to build the test project.

## Dependencies
To complexify a little, the CMake project is composed of three libraries (Foo, Bar and FooBar)
with the following dependencies:  
```sh
Foo:
Bar:
FooBar: PUBLIC Foo PRIVATE Bar
```

## Build Process
To Create a native dependent package we will split it in two parts:

* A bunch of `org.mizux.javanative:javanative-{platform}` maven packages for each
supported platform targeted and containing the native libraries.
* A generic maven package `org.mizux.javanative:javanative-java` depending on each native
packages and containing the Java code.

[`platform` names](https://github.com/java-native-access/jna/blob/cc1acdac02e4d0dda93ba01bbe3a3435b8933dab/test/com/sun/jna/PlatformTest.java#L31-L100) come from the JNA project (Java Native Access) which will be use to find at runtime on which platform the code is currently running.

### Local Package

The pipeline for `linux-x86-64` should be as follow:  
note: The pipeline will be similar for other architecture,
don't hesitate to look at the CI log! ![Local Pipeline](docs/local_pipeline.svg)
![Legend](docs/legend.svg)

#### Building local native Package

disclaimer: In this git repository, we use `CMake` and `SWIG`.  
Thus we have the C++ shared library `libFoo.so` and the SWIG generated Java wrapper `Foo.java`.  
note: For a C++ CMake cross-platform project sample, take a look at [Mizux/cmake-cpp](https://github.com/Mizux/cmake-cpp).   
note: For a C++/Swig CMake cross-platform project sample, take a look at [Mizux/cmake-swig](https://github.com/Mizux/cmake-swig). 

So first let's create the local `org.mizux.javanative:javanative-{platform}.jar`
maven package.

Here some dev-note concerning this `POM.xml`.
* This package is a native package only containing native libraries.

Then you can generate the package and install it locally using:
```bash
mvn package
mvn install
```
note: this will automatically trigger the `mvn compile` phase.

If everything good the package (located in
`<buildir>/java/org.mizux.javanative-<platform>/target/`) should have this layout:
```
{...}/target/javanative-<platform>-1.0.jar:
\- <platform>
   \-libFoo.so.1.0
   \-libjnijavanative.so
...
```
note: `<platform>` could be `linux-x86-64`, `darwin-x86-64` or `win32-x86-64`.

tips: since maven package are just zip archive you can use `unzip -l <package>.jar`
to study their layout.

#### Building local Package

So now, let's create the local `org.mizux.javanative:javanative-java.jar` maven
package which will depend on our previous native package.

Here some dev-note concerning this `POM.xml`.
* Add runtime dependency on each native package(s) availabe:
  ```xml
  <dependency>
    <groupId>org.mizux.javanative</groupId>
    <artifactId>javanative-linux-x86-64</artifactId>
    <version>[1.0,)</version>
    <type>jar</type>
    <scope>runtime</scope>
  </dependency>
  ```
  - Add dependency to jna so we can find at runtime the current `<platform>`:
  ```xml
  <dependency>
    <groupId>net.java.dev.jna</groupId>
    <artifactId>jna-platform</artifactId>
    <version>5.13.0</version>
  </dependency>
  ```

Then you can generate the package using:
```bash
mvn package
mvn install
```

If everything good the package (located in
`<buildir>/java/org.mizux.javanative/target/`) should have this layout:
```
{...}/target/javanative-java-1.0.jar:
\- org/
   \- mizux/
      \- javanative/
         \- Loader$PathConsumer.class
         \- Loader$1.class
         \- Loader.class
         \- foo/
            \- GlobalsJNI.class
            \- StringJaggedArray.class
            \- IntPair.class
            \- StringVector.class
            \- Foo.class
            \- PairVector.class
            \- PairJaggedArray.class
            \- Globals.class
...
```

#### Testing local Package

We can test everything is working by using the `org.mizux.javanative.test:javanative-test` project.

First you can build it using:
```
cmake --build build
```
note: `javanative-test` depends on `javanative-java` which is locally installed in the local maven cache
(`~/.m2/repository/org/mizux/javanative/...`).

Then you can run it using:
```sh
cmake --build build --target test
```
or manually using:
```
cd <builddir>/java/org.mizux.javanative.test
mvn exec:java -Dexec.mainClass="org.mizux.javanative.Test"
```

## Appendices
Few links on the subject...

### Resources
Project layout:
* The Pitchfork Layout Revision 1 (cxx-pflR1)

CMake:
* https://llvm.org/docs/CMakePrimer.html
* https://cliutils.gitlab.io/modern-cmake/
* https://cgold.readthedocs.io/en/latest/

Java:
* [POM.xml reference](http://maven.apache.org/pom.html)
* [Maven Central POM requirement](https://central.sonatype.org/pages/requirements.html)
* [Javadoc Plugin](https://maven.apache.org/plugins/maven-javadoc-plugin/)
* [Java Source Plugin](https://maven.apache.org/plugins/maven-source-plugin/)
* [Java Native Access Project](https://github.com/java-native-access/jna)

### Misc
Image has been generated using [plantuml](http://plantuml.com/):
```bash
plantuml -Tsvg docs/{file}.dot
```
So you can find the dot source files in [docs](docs).

## License
Apache 2. See the LICENSE file for details.

## Disclaimer
This is not an official Google product, it is just code that happens to be
owned by Google.

