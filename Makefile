export CGO_ENABLED:=0

VERSION=$(shell ./scripts/git-version)
LD_FLAGS="-w -X github.com/coreos/matchbox/matchbox/version.Version=$(VERSION)"

REPO=github.com/coreos/matchbox
IMAGE_REPO=coreos/matchbox
QUAY_REPO=quay.io/coreos/matchbox

all: build

build: clean bin/matchbox bin/bootcmd

bin/matchbox:
	@go build -o bin/matchbox -v -ldflags $(LD_FLAGS) $(REPO)/cmd/matchbox

bin/bootcmd:
	@go build -o bin/bootcmd -v -ldflags $(LD_FLAGS) $(REPO)/cmd/bootcmd

test:
	@./scripts/test

.PHONY: aci
aci: clean build
	@sudo ./scripts/build-aci

.PHONY: docker-image
docker-image:
	@sudo docker build --rm=true -t $(IMAGE_REPO):$(VERSION) .
	@sudo docker tag $(IMAGE_REPO):$(VERSION) $(IMAGE_REPO):latest

.PHONY: docker-push
docker-push: docker-image
	@sudo docker tag $(IMAGE_REPO):$(VERSION) $(QUAY_REPO):latest
	@sudo docker tag $(IMAGE_REPO):$(VERSION) $(QUAY_REPO):$(VERSION)
	@sudo docker push $(QUAY_REPO):latest
	@sudo docker push $(QUAY_REPO):$(VERSION)

.PHONY: vendor
vendor:
	@glide update --strip-vendor
	@glide-vc --use-lock-file --no-tests --only-code

.PHONY: codegen
codegen: tools
	@./scripts/codegen

.PHONY: tools
tools: bin/protoc bin/protoc-gen-go

bin/protoc:
	@./scripts/get-protoc

bin/protoc-gen-go:
	@go build -o bin/protoc-gen-go $(REPO)/vendor/github.com/golang/protobuf/protoc-gen-go

clean:
	@rm -rf bin

clean-release:
	@rm -rf _output

release: \
	clean-release \
	_output/matchbox-linux-amd64.tar.gz \
	_output/matchbox-linux-arm.tar.gz \
	_output/matchbox-linux-arm64.tar.gz \
	_output/matchbox-darwin-amd64.tar.gz \

# matchbox

bin/linux-amd64/matchbox:
	GOOS=linux GOARCH=amd64 go build -o bin/linux-amd64/matchbox -ldflags $(LD_FLAGS) -a $(REPO)/cmd/matchbox

bin/linux-arm/matchbox:
	GOOS=linux GOARCH=arm go build -o bin/linux-arm/matchbox -ldflags $(LD_FLAGS) -a $(REPO)/cmd/matchbox

bin/linux-arm64/matchbox:
	GOOS=linux GOARCH=arm64 go build -o bin/linux-arm64/matchbox -ldflags $(LD_FLAGS) -a $(REPO)/cmd/matchbox

bin/darwin-amd64/matchbox:
	GOOS=darwin GOARCH=amd64 go build -o bin/darwin-amd64/matchbox -ldflags $(LD_FLAGS) -a $(REPO)/cmd/matchbox

# bootcmd

bin/linux-amd64/bootcmd:
	GOOS=linux GOARCH=amd64 go build -o bin/linux-amd64/bootcmd -ldflags $(LD_FLAGS) -a $(REPO)/cmd/bootcmd

bin/linux-arm/bootcmd:
	GOOS=linux GOARCH=arm go build -o bin/linux-arm/bootcmd -ldflags $(LD_FLAGS) -a $(REPO)/cmd/bootcmd

bin/linux-arm64/bootcmd:
	GOOS=linux GOARCH=arm64 go build -o bin/linux-arm64/bootcmd -ldflags $(LD_FLAGS) -a $(REPO)/cmd/bootcmd

bin/darwin-amd64/bootcmd:
	GOOS=darwin GOARCH=amd64 go build -o bin/darwin-amd64/bootcmd -ldflags $(LD_FLAGS) -a $(REPO)/cmd/bootcmd

_output/matchbox-%.tar.gz: NAME=matchbox-$(VERSION)-$*
_output/matchbox-%.tar.gz: DEST=_output/$(NAME)
_output/matchbox-%.tar.gz: bin/%/matchbox bin/%/bootcmd
	mkdir -p $(DEST)
	cp bin/$*/matchbox $(DEST)
	cp bin/$*/bootcmd $(DEST)
	./scripts/release-files $(DEST)
	tar zcvf $(DEST).tar.gz -C _output $(NAME)

.PHONY: all build clean test release
.SECONDARY: _output/matchbox-linux-amd64 _output/matchbox-darwin-amd64

