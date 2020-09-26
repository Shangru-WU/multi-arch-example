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

all: build
# ==============================================================================
# Includes

include build/lib/common.mk

.PHONY: build
build:
	CGO_ENABLED=0 go build -o bin/main cmd/main.go

.PHONY: run
run:
	go run cmd/main.go

.PHONY: docker.buildx.install
docker.buildx.install:
	@$(ROOT_DIR)/build/lib/docker-buildx.sh docker_buildx:multi_arch_support

.PHONY: image
image: docker.buildx.install
	VERSION=$(VERSION) $(ROOT_DIR)/build/lib/image-build.sh image_build:build

.PHONY: push
push: docker.buildx.install
	VERSION=$(VERSION) $(ROOT_DIR)/build/lib/image-build.sh image_build:push
