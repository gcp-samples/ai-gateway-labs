FROM golang:1.26 AS builder
COPY go.mod go.sum main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/aigw-test-service

FROM alpine:3
RUN apk add --no-cache ca-certificates
COPY --from=builder /bin/aigw-test-service aigw-test-service
COPY openapi.yaml openapi.yaml
COPY public public
CMD ["/aigw-test-service"]
