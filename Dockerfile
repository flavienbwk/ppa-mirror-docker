FROM debian:buster-slim

RUN apt update && apt install gcc make perl wget ca-certificates --no-install-recommends -y

WORKDIR /app
