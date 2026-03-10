# Multi-stage Dockerfile for evaluation-service (Go)
FROM golang:1.20-alpine AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags "-s -w" -o /evaluation-service ./

FROM alpine:3.18
RUN addgroup -S app && adduser -S -G app app
COPY --from=builder /evaluation-service /usr/local/bin/evaluation-service
USER app
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/evaluation-service"]
