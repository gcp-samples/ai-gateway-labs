# Copyright 2026 Google LLC
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

FROM golang:1.26 AS builder
COPY go.mod go.sum main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/aigw-test-service

FROM alpine:3
RUN apk add --no-cache ca-certificates
COPY --from=builder /bin/aigw-test-service aigw-test-service
COPY openapi.yaml openapi.yaml
COPY public public
CMD ["/aigw-test-service"]
