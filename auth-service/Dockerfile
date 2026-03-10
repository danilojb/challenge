# Recreated multi-stage Dockerfile for auth-service (Go)
FROM golang:1.20-alpine AS builder
WORKDIR /src

# Install tools needed to build and fetch modules, and CA certs for final image
RUN apk add --no-cache git build-base ca-certificates

# Cache Go modules
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build a small static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags "-s -w" -o /auth-service ./

FROM alpine:3.18
RUN addgroup -S app && adduser -S -G app app

# Copy the built binary and CA certs from builder
COPY --from=builder /auth-service /usr/local/bin/auth-service
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER app
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/auth-service"]
