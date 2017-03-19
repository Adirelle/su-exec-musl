# vim: noexpandtab ts=4

TARGET_ARCH ?= x86_64

BUILD = build
PKG_DIR = $(BUILD)/pkg
SRC_DIR = $(BUILD)/src
ROOT_DIR = $(BUILD)/root-$(TARGET_ARCH)

MUSL_GCC_REL = 2
MUSL_GCC_VER = 6.3.0
MUSL_GCC_PKG = $(PKG_DIR)/gcc-$(MUSL_GCC_VER)-$(TARGET_ARCH)-linux-musl.tar.gz 
MUSL_GCC_DIR = $(BUILD)/gcc-$(MUSL_GCC_VER)-$(TARGET_ARCH)-linux-musl
MUSL_GCC_BIN = $(MUSL_GCC_DIR)/$(TARGET_ARCH)-linux-musl-gcc
MUSL_GCC_URL = https://github.com/just-containers/musl-cross-make/releases/download/v$(MUSL_GCC_REL)/gcc-$(MUSL_GCC_VER)-$(TARGET_ARCH)-linux-musl.tar.gz

MAKE_VER = 4.2.1
MAKE_PKG = $(PKG_DIR)/make-$(MAKE_VER).tar.bz2 
MAKE_SRC = $(SRC_DIR)/make-$(MAKE_VER)
MAKE_URL = http://ftp.gnu.org/gnu/make/make-$(MAKE_VER).tar.bz2
MAKE_BIN = $(MAKE_SRC)/make

SU_EXEC_VER = 0.2
SU_EXEC_PKG = $(PKG_DIR)/su-exec-v$(SU_EXEC_VER).tar.gz
SU_EXEC_SRC = $(SRC_DIR)/su-exec-$(SU_EXEC_VER)
SU_EXEC_URL = https://github.com/ncopa/su-exec/archive/v$(SU_EXEC_VER).tar.gz

WGET = wget --timestamping

BINARY = $(SU_EXEC_SRC)/su-exec-static
PACKAGE = $(BUILD)/artifacts/su-exec-$(SU_EXEC_VER)-$(TARGET_ARCH)-linux-musl.tar.bz2

.PHONY: all clean distclean

all: $(PACKAGE)

clean:
	[ -d $(SU_EXEC_SRC) ] && make -C $(SU_EXEC_SRC) clean
	rm -rf $(ROOT_DIR) $(PACKAGE)

distclean:
	rm -f $(BUILD)

$(PACKAGE): $(ROOT_DIR)/bin/su-exec
	mkdir -p $(@D)
	tar cfz $@ -C $(ROOT_DIR) --owner=0 --group=0 . 

$(ROOT_DIR)/bin/su-exec: $(BINARY)
	mkdir -p $(ROOT_DIR)/bin
	cp $< $@ 
	chmod 4555 $@

$(BINARY): $(SU_EXEC_SRC) $(MAKE_BIN) $(MUSL_GCC_BIN)
	PATH=$(abspath $(MUSL_GCC_DIR))/bin:$(abspath $(MAKE_SRC)):$(PATH) $(MAKE_BIN) -C $(SU_EXEC_SRC) CC=$(TARGET_ARCH)-linux-musl-cc $(@F)

$(MAKE_BIN): $(MAKE_SRC)
	cd $(MAKE_SRC) && ./configure
	make -C $(MAKE_SRC) make

$(MUSL_GCC_BIN): $(MUSL_GCC_PKG)
	-mkdir -p $(MUSL_GCC_DIR)
	tar xfz $< -C $(MUSL_GCC_DIR)
	touch -r $< $@

$(MUSL_GCC_PKG): | $(PKG_DIR)
	$(WGET) $(MUSL_GCC_URL) -O $(MUSL_GCC_PKG)

$(MAKE_SRC): $(MAKE_PKG) | $(SRC_DIR)
	tar xfj $< -C $(@D)
	touch -r $< $@

$(MAKE_PKG): | $(PKG_DIR)
	$(WGET) $(MAKE_URL) -O $(MAKE_PKG)

$(SU_EXEC_SRC): $(SU_EXEC_PKG) | $(SRC_DIR)
	tar xfz $< -C $(@D)
	touch -r $< $@

$(SU_EXEC_PKG): | $(PKG_DIR)
	$(WGET) $(SU_EXEC_URL) -O $(SU_EXEC_PKG)

$(SRC_DIR) $(PKG_DIR) $(BIN_DIR):
	mkdir -p $@
