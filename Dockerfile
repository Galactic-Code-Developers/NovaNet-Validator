FROM ubuntu:20.04
WORKDIR /novanet
RUN apt update && apt install -y build-essential git cmake curl jq
COPY . /novanet
RUN make build
CMD ["/novanet/novanet-cli", "start", "--validator"]
