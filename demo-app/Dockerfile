FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /demo-app .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates
COPY --from=build /demo-app /demo-app
USER 65534:65534
ENTRYPOINT ["/demo-app"]
