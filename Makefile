# vim: noexpandtab ts=4

TARGET_OS ?= linux
TARGET_ARCH ?= x86_64

BUILD = build
PKG_DIR = $(BUILD)/pkg
SRC_DIR = $(BUILD)/src
ATF_DIR = $(BUILD)/artifacts

MUSL_GCC_REL = 2
MUSL_GCC_VER = 6.3.0
MUSL_GCC_FNAME = gcc-$(MUSL_GCC_VER)-$(TARGET_ARCH)-$(TARGET_OS)-musl.tar.gz
MUSL_GCC_PKG = $(PKG_DIR)/$(MUSL_GCC_FNAME)
MUSL_GCC_DIR = $(BUILD)/gcc-$(MUSL_GCC_VER)-$(TARGET_ARCH)-$(TARGET_OS)-musl
MUSL_GCC_URL = https://github.com/just-containers/musl-cross-make/releases/download/v$(MUSL_GCC_REL)/$(MUSL_GCC_FNAME)

MUSL_CC = $(MUSL_GCC_DIR)/bin/$(TARGET_ARCH)-$(TARGET_OS)-musl-cc

SU_EXEC_VER = 0.2
SU_EXEC_FNAME = v$(SU_EXEC_VER).tar.gz
SU_EXEC_PKG = $(PKG_DIR)/$(SU_EXEC_FNAME)
SU_EXEC_SRC = $(SRC_DIR)/su-exec-$(SU_EXEC_VER)
SU_EXEC_URL = https://github.com/ncopa/su-exec/archive/$(SU_EXEC_FNAME)

WGET = tools/wget -c -nv -N

BINARY = $(SU_EXEC_SRC)/su-exec-static
DISTRIB = $(ATF_DIR)/su-exec-$(SU_EXEC_VER)-$(TARGET_ARCH)-$(TARGET_OS)
CHECKSUM = $(DISTRIB).sha512
MANIFEST = $(ATF_DIR)/manifest.txt
ARTIFACTS = $(DISTRIB) $(CHECKSUM) $(MANIFEST)

.PHONY: all clean distclean

all: $(ARTIFACTS)

clean:
	[ -d $(SU_EXEC_SRC) ] && make -C $(SU_EXEC_SRC) clean
	rm -rf $(ARTIFACTS)

distclean:
	rm -rf $(BUILD)

$(CHECKSUM): $(DISTRIB)
	cd $(@D) && sha512sum $(<F) >$(@F)

$(MANIFEST): | $(ATF_DIR)
	echo "su-exec=$(SU_EXEC_VER)" >$@

$(DISTRIB): $(BINARY) | $(ATF_DIR)
	cp $< $@

$(BINARY): $(SU_EXEC_SRC) $(MUSL_CC)
	PATH=$(abspath $(MUSL_GCC_DIR))/bin:$(PATH) $(MAKE) -C $(SU_EXEC_SRC) CC=$(abspath $(MUSL_CC)) $(@F)

$(SU_EXEC_SRC): $(SU_EXEC_PKG) | $(SRC_DIR)
	tar xfz $< -C $(@D)
	touch -r $< $@

$(SU_EXEC_PKG): | $(PKG_DIR)
	$(WGET) -P $(@D) $(SU_EXEC_URL)

$(SRC_DIR) $(PKG_DIR) $(BIN_DIR) $(ATF_DIR):
	mkdir -p $@

$(MUSL_CC): $(MUSL_GCC_PKG)
	-mkdir -p $(MUSL_GCC_DIR)
	tar xfz $< -C $(MUSL_GCC_DIR)
	touch -r $< $@

$(MUSL_GCC_PKG): | $(PKG_DIR)
	$(WGET) -P $(@D) $(MUSL_GCC_URL)
