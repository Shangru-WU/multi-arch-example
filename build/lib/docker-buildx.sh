#!/usr/bin/env bash

# Tencent is pleased to support the open source community by making TKEStack
# available.
#
# Copyright (C) 2012-2019 Tencent. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at
#
# https://opensource.org/licenses/Apache-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

DOCKER_SUPPORTED_API_VERSION="1.40"
DOCKER_SUPPORTED_VERSION="19.03"

BUILDX_VERSION=${BUILDX_VERSION:-"v0.4.2"}
ARCH=${ARCH:-"amd64"}
BUILDX_BIN="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${ARCH}"

function error() {
	echo "ERROR: $*"
	exit 1
}

function _version() {
	printf '%02d' $(echo "$1" | tr . ' ' | sed -e 's/ 0*/ /g') 2>/dev/null
}

function docker_buildx:check_docker_version() {
	if ! command -v docker >/dev/null 2>&1; then
		error "Can't find docker. Please install docker with version >= ${DOCKER_SUPPORTED_VERSION}."
	fi

	local -r docker_api_version="$(docker version | grep -E 'API version: {1,6}[0-9]' | head -n1 | awk '{print $3} END { if (NR==0) print 0}')"
	if [[ "$(_version "${docker_api_version}")" < "$(_version "${DOCKER_SUPPORTED_API_VERSION}")" ]]; then
		docker -v
		error "Unsupported docker version. Docker API version need >= ${DOCKER_SUPPORTED_API_VERSION} (Or docker version >= ${DOCKER_SUPPORTED_VERSION})."
	fi
}

function docker_buildx:install() {
	export DOCKER_CLI_EXPERIMENTAL=enabled
	docker_buildx:check_docker_version
	local -r buildx_err="$(docker buildx version >/dev/null 2>&1 && echo 0 || echo 1)"
	if [[ ${buildx_err} -eq 0 ]]; then
		# docker buildx is installed
		return 0
	fi

	echo "Downloading docker buildx"
	wget -c ${BUILDX_BIN} -O ./docker-buildx
	mkdir -p ~/.docker/cli-plugins/
	mv ./docker-buildx ~/.docker/cli-plugins/
	chmod a+x ~/.docker/cli-plugins/docker-buildx
	docker buildx version
	echo "docker buildx is installed"
}

function docker_buildx:multi_arch_support() {
	# Install docker buildx if need
	docker_buildx:install

	# Check kernel version.
	local -r kernel_version="$(uname -r)"
	if [[ "$(_version "${kernel_version}")" < "$(_version '4.8')" ]]; then
		echo "Unsupported kernel version ${kernel_version}. Kernel version need >= 4.8."
		exit 1
	fi

	local -r platform="$(uname)"
	if [[ ${platform} != "Linux" ]]; then
		# docker desktop for mac already supports multi-arch building
		return 0
	fi

	# QEMU
	if [[ ! -e '/proc/sys/fs/binfmt_misc/qemu-aarch64' ]]; then
		if [[ ! -e '/usr/bin/qemu-aarch64-static' ]]; then
			# Install QEMU multi-architecture support for docker buildx.
			docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
			systemctl restart docker
			DOCKER_CLI_EXPERIMENTAL=enabled docker buildx ls
		fi
	fi
}

# Allows to call a function based on arguments passed to the script
#   Example: bash ./docker-buildx.sh docker_buildx:install
$*
