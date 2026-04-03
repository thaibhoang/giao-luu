# syntax=docker/dockerfile:1

FROM golang:1.22-bookworm AS build
ARG VERSION=dev
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags "-s -w -X main.Version=${VERSION}" -o /out/scraper ./cmd/scraper

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=build /out/scraper /scraper
USER nonroot:nonroot
ENTRYPOINT ["/scraper"]
