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
set -o xtrace

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
ROOT_DIR=${ROOT_DIR:-"$(cd ${SCRIPT_DIR}/../.. && pwd -P)"}

export DOCKER_CLI_EXPERIMENTAL=enabled

if [ -z ${VERSION} ]; then
	echo "Please provide VERSION"
	exit 1
fi

PLATFORMS=${PLATFORMS:-"linux_amd64 linux_arm64"}
REGISTRY_PREFIX=${REGISTRY_PREFIX:-"srwuk8s"}
IMAGE=${IMAGE:-"multi-arch-example"}
DES_REGISTRY=${REGISTRY_PREFIX}/${IMAGE}

function image_build:build() {
	for platform in ${PLATFORMS}; do
		os=${platform%_*}
		arch=${platform#*_}
		image_plat="${os}/${arch}"
		image_name="${DES_REGISTRY}-${arch}:${VERSION}"
		echo "===========> Building docker image ${image_name}"
		docker buildx build --platform ${image_plat} --load -t ${image_name} -f ${ROOT_DIR}/build/docker/Dockerfile ${ROOT_DIR}
	done
}

function image_build:push() {
	image_build:build
	## remove local manifest file if need
	# rm -rf ${HOME}/.docker/manifests/docker.io_${REGISTRY_PREFIX}_${IMAGE}-${VERSION}
	manifest_name="${DES_REGISTRY}:${VERSION}"

	for platform in ${PLATFORMS}; do
		os=${platform%_*}
		arch=${platform#*_}
		variant=""
		if [ ${arch} == "arm64" ]; then
			variant="--variant v8"
		fi

		image_name="${DES_REGISTRY}-${arch}:${VERSION}"
		docker push ${image_name}
		docker manifest create --amend ${manifest_name} ${image_name}
		docker manifest annotate ${manifest_name} ${image_name} \
			--os ${os} --arch ${arch} ${variant}
	done
	docker manifest push --purge ${manifest_name}
}

# Allows to call a function based on arguments passed to the script
#   Example: bash ./image-build.sh image_build:build
$*
