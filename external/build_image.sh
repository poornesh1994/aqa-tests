#!/usr/bin/env bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -o pipefail

source $(dirname "$0")/common_functions.sh
source $(dirname "$0")/dockerfile_functions.sh
buildArg=""

if [ $# -ne 8 ] && [ $# -ne 7 ]; then
	echo "The supported tests are ${supported_tests}"
	echo
	echo "usage: $0 test version vm os package build check_external_custom"
	echo "test    = ${supported_tests}"
	echo "version = ${supported_versions}"
	echo "vm      = ${supported_jvms}"
	echo "os      = ${supported_os}"
	echo "package = ${supported_packages}"
	echo "build   = ${supported_builds}"
	echo "buildArg" = "Optional: customized image"
	exit -1
fi
if [ $# -eq 8 ]; then
	buildArg="--build-arg IMAGE=$8"
fi
if [[ ${check_external_custom} -eq 0 ]]; then
	set_test $1
fi
set_version $2
set_vm $3
set_os $4
set_package $5
set_build $6


# Build the Docker image with the given repo, build, build type and tags.
function build_image() {
    local file=$1
    local test=$2
    local version=$3
    local vm=$4
    local os=$5
    local package=$6
    local build=$7
    local buildArg=$8
    

	echo "The test in the build_image() function is ${test}"
    # Used for tagging the image
    tags="adoptopenjdk-${test}-test:${version}-${package}-${os}-${vm}-${build}"

	echo "#####################################################"
	echo "INFO: docker build ${buildArg} --no-cache -t ${tags} -f ${file} $(realpath $(dirname "$0"))/"
	echo "#####################################################"
	docker build ${buildArg} --no-cache -t ${tags} -f ${file} $(realpath $(dirname "$0"))/
	if [ $? != 0 ]; then
		echo "ERROR: Docker build of image: ${tags} from ${file} failed."
		exit 1
	fi
}

# Handle making the directory for organizing the Dockerfiles
if [[ ${check_external_custom} -eq 1 ]]; then
	dir="$(realpath $(dirname "$0"))/external_custom/dockerfile/${version}/${package}/${os}"
else
	dir="$(realpath $(dirname "$0"))/${test}/dockerfile/${version}/${package}/${os}"
fi
mkdir -p ${dir}

# File Path to Dockerfile
file="${dir}/Dockerfile.${vm}.${build}"

# Generate Dockerfile
generate_dockerfile ${file} ${test} ${version} ${vm} ${os} ${package} ${build} ${check_external_custom}

# Check if Dockerfile exists
if [ ! -f ${file} ]; then
    echo "ERROR: Dockerfile generation for ${file} failed."
	exit 1
fi

# Build Dockerfile that was generated
build_image ${file} ${test} ${version} ${vm} ${os} ${package} ${build} "${buildArg}"
