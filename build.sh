#!/bin/sh
#
# Copyright (c) 2019, 2021 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

if [ -z "${FNFDK_VERSION}" ];  then
    FNFDK_VERSION=$(cat fnfdk.version)
fi

if [ -z "${GRAALVM_VERSION}" ];  then
    GRAALVM_VERSION=$(cat graalvm.version)
fi

generateImage() {
    local java_version="${1}"
    local graalvm_image_name=${2}
    local init_image_name=${3}
    local graalvm_image_and_tag="${graalvm_image_name}:java${java_version}-${GRAALVM_VERSION}"
    local fn_fdk_build_tag="${FNFDK_VERSION}"
    local fn_fdk_tag="${FNFDK_VERSION}"
    if [ ${java_version} -gt 8 ] 
    then
        fn_fdk_build_tag="jdk${java_version}-${FNFDK_VERSION}"
        fn_fdk_tag="jre${java_version}-${FNFDK_VERSION}"
    fi

    # Update pom.xml with current FDK version
    sed -i.bak -e "s|<fdk\\.version>.*</fdk\\.version>|<fdk.version>${FNFDK_VERSION}</fdk.version>|" pom.xml && rm pom.xml.bak

    # Update pom.xml with Java source/target
    cp pom.xml pom.build
    sed -i.bak \
        -e "s|<source>.*</source>|<source>${java_version}</source>|" \
        -e "s|<target>.*</target>|<target>${java_version}</target>|" \
        pom.build && rm pom.build.bak

    # Create Dockerfile with current FDK build tag (Java 11)
    cp Dockerfile Dockerfile.build
    sed -i.bak \
        -e "s|##FN_FDK_TAG##|${fn_fdk_tag}|" \
        -e "s|##FN_FDK_BUILD_TAG##|${fn_fdk_build_tag}|" \
        -e "s|##GRAALVM_IMAGE##|${graalvm_image_and_tag}|" \
        Dockerfile.build && rm Dockerfile.build.bak   

    # Build init image packaging created Dockerfile (Java 11)
    docker build -t ${init_image_name}:jdk${java_version}-${FNFDK_VERSION} -f Dockerfile-init-image .
    
    rm Dockerfile.build pom.build
}

# GraalVM Community Init Images
generateImage 11 "container-registry.oracle.com/graalvm/native-image" "fnproject/fn-java-graalvm-ce-init"
# TODO: enable when 17 FDK images available
# generateImage 17 "container-registry.oracle.com/graalvm/native-image" "fnproject/fn-java-graalvm-ce-init"

# GraalVM Enterprise Init Images
generateImage 8  "container-registry.oracle.com/graalvm/native-image-ee" "fnproject/fn-java-graalvm-ee-init"
generateImage 11 "container-registry.oracle.com/graalvm/native-image-ee" "fnproject/fn-java-graalvm-ee-init"
# TODO: enable when 17 FDK images available
# generateImage 17 "container-registry.oracle.com/graalvm/native-image-ee" "fnproject/fn-java-graalvm-ee-init"
