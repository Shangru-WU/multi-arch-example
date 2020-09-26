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

FROM golang:1.14.9 AS builder
ARG TARGETPLATFORM
RUN echo "building for ${TARGETPLATFORM}"
ARG WORKDIR="/go/src/tkestack.io/multi-arch-example/"
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}
## cache dependancies if we won't change mod/sum
COPY go.mod go.sum ${WORKDIR}
RUN go mod download

COPY . ${WORKDIR}
RUN make build


#####################################
# 
#####################################

FROM alpine:3.12.0
## golang in alpine won't read /etc/hosts without /etc/nsswitch.conf
RUN echo "hosts: files dns" >> /etc/nsswitch.conf

COPY --from=builder /go/src/tkestack.io/multi-arch-example/bin/main /app/
ENTRYPOINT ["/app/main"]
