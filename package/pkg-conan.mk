################################################################################
# Conan package infrastructure
#
# This file implements an infrastructure that eases development of
# package .mk files for Meson packages. It should be used for all
# packages that use Meson as their build system.
#
# See the Buildroot documentation for details on the usage of this
# infrastructure
#
################################################################################

#CONAN		= PYTHONNOUSERSITE=y $(HOST_DIR)/bin/conan
CONAN		= conan

################################################################################
# inner-conan-package -- defines how the configuration, compilation and
# installation of a Conan package should be done, implements a few hooks to
# tune the build process and calls the generic package infrastructure to
# generate the necessary make targets
#
#  argument 1 is the lowercase package name
#  argument 2 is the uppercase package name, including a HOST_ prefix
#             for host packages
#  argument 3 is the uppercase package name, without the HOST_ prefix
#             for host packages
#  argument 4 is the type (target or host)
################################################################################

define inner-conan-package

$(call inner-generic-package,$(1),$(2),$(3),$(4))

$(2)_CONF_ENV			?=
$(2)_CONF_OPTS			?=
$(2)_CONAN_ENV			?= CONAN_USER_HOME=$$(BASE_DIR)

CONAN_SETTING_COMPILER 			?= gcc
CONAN_SETTING_COMPILER_VERSION 		?=
CONAN_SETTING_ARCH 			?= $(BR2_ARCH)
CONAN_REMOTE				?=
CONAN_BUILD_POLICY			?= missing

# TODO (uilian): Use Conan privded by buildroot
# $(2)_DEPENDENCIES += host-python-conan

CONAN_OPTION_SHARED = $$(if $$(BR2_STATIC_LIBS),False,True)
CONAN_SETTING_BUILD_TYPE = $$(if $$(BR2_ENABLE_DEBUG),Debug,Release)

ifeq ($(BR2_x86_64),y)
CONAN_SETTING_ARCH = x86_64
else ifeq ($(BR2_x86_i686),y)
CONAN_SETTING_ARCH = x86
else ifeq ($(BR2_x86_i486),y)
CONAN_SETTING_ARCH = x86
else ifeq ($(BR2_x86_i586),y)
CONAN_SETTING_ARCH = x86
else ifeq ($(BR2_ARCH),arm)
CONAN_SETTING_ARCH = armv7
else ifeq ($(BR2_ARCH),armhf)
CONAN_SETTING_ARCH = armv7hf
else ifeq ($(call qstrip,$(BR2_ARCH)),powerpc64)
CONAN_SETTING_ARCH = ppc64
else ifeq ($(call qstrip,$(BR2_ARCH)),powerpc64le)
CONAN_SETTING_ARCH = ppc64le
endif

ifeq ($(BR2_ARM_CPU_ARMV4),y)
CONAN_SETTING_ARCH = armv4
else ifeq ($(BR2_ARM_CPU_ARMV5),y)
CONAN_SETTING_ARCH = armv5hf
else ifeq ($(BR2_ARM_CPU_ARMV6),y)
CONAN_SETTING_ARCH = armv6
else ifeq ($(BR2_ARM_CPU_ARMV7A),y)
CONAN_SETTING_ARCH = armv7
else ifeq ($(BR2_ARM_CPU_ARMV8A),y)
CONAN_SETTING_ARCH = armv8
endif

ifeq ($(CONAN_BUILD_POLICY_MISSING),y)
CONAN_BUILD_POLICY = missing
else ifeq ($(CONAN_BUILD_POLICY_OUTDATED),y)
CONAN_BUILD_POLICY = outdated
else ifeq ($(CONAN_BUILD_POLICY_CASCADE),y)
CONAN_BUILD_POLICY = cascade
else ifeq ($(CONAN_BUILD_POLICY_ALWAYS),y)
CONAN_BUILD_POLICY = always
else ifeq ($(CONAN_BUILD_POLICY_NEVER),y)
CONAN_BUILD_POLICY = never
endif

# Check if package reference contains shared option


ifneq ($$(CONAN_REMOTE_NAME),"")
CONAN_REMOTE = -r $$(CONAN_REMOTE_NAME)
endif

$(2)_MAKE			?= $$(MAKE)
$(2)_INSTALL_OPTS		?= install

$(3)_SUPPORTS_IN_SOURCE_BUILD 	?= YES

ifeq ($$($(3)_SUPPORTS_IN_SOURCE_BUILD),YES)
$(2)_BUILDDIR			= $$($(2)_SRCDIR)
else
$(2)_BUILDDIR			= $$($(2)_SRCDIR)/buildroot-build
endif

#
# Build step. Only define it if not already defined by the package .mk
# file.
#
ifndef $(2)_BUILD_CMDS
ifeq ($(4),target)
define $(2)_CONAN_CONFIGURE_CMDS
	$$($$(PKG)_CONF_ENV) $$(BR2_CMAKE) $$($$(PKG)_SRCDIR) \
		-DCMAKE_TOOLCHAIN_FILE="$$(HOST_DIR)/share/buildroot/toolchainfile.cmake" \
		-DCMAKE_INSTALL_PREFIX="/usr" \
		-DCMAKE_COLOR_MAKEFILE=OFF \
		-DBUILD_DOC=OFF \
		-DBUILD_DOCS=OFF \
		-DBUILD_EXAMPLE=OFF \
		-DBUILD_EXAMPLES=OFF \
		-DBUILD_TEST=OFF \
		-DBUILD_TESTS=OFF \
		-DBUILD_TESTING=OFF \
		-DBUILD_SHARED_LIBS=$$(if $$(BR2_STATIC_LIBS),OFF,ON) \
		$$(CMAKE_QUIET) \
		$$($$(PKG)_CONF_OPTS)
endef

define $(2)_CONFIGURE_CMDS
	mkdir -p $$($$(PKG)_BUILDDIR) && \
	cd $$($$(PKG)_BUILDDIR) && \
	$$(TARGET_MAKE_ENV) $$(CONAN_ENV) $$($$(PKG)_CONAN_ENV) \
	    CC=$$(TARGET_CC) CXX=$$(TARGET_CXX) \
		$$(CONAN) install .. $$(CONAN_OPTS) $$($$(PKG)_CONAN_OPTS) \
		$$($$(PKG)_REFERENCE) \
		-s build_type=$$(CONAN_SETTING_BUILD_TYPE) \
		-s arch=$$(CONAN_SETTING_ARCH) \
		-s compiler=$$(CONAN_SETTING_COMPILER) \
		-s compiler.libcxx=libstdc++11 \
		-g deploy \
		--build $$(CONAN_BUILD_POLICY) && \
		$$($(2)_CONAN_CONFIGURE_CMDS)
endef
endif
endif

ifndef $(2)_BUILD_CMDS
ifeq ($(4),target)
define $(2)_BUILD_CMDS
	$$(TARGET_MAKE_ENV) $$($$(PKG)_MAKE_ENV) $$($$(PKG)_MAKE) $$($$(PKG)_MAKE_OPTS) -C $$($$(PKG)_BUILDDIR)
endef
else
define $(2)_BUILD_CMDS
	$$(HOST_MAKE_ENV) $$($$(PKG)_MAKE_ENV) $$($$(PKG)_MAKE) $$($$(PKG)_MAKE_OPTS) -C $$($$(PKG)_BUILDDIR)
endef
endif
endif

#
# Target installation step. Only define it if not already defined by
# the package .mk file.
#
ifndef $(2)_INSTALL_TARGET_CMDS
define $(2)_INSTALL_TARGET_CMDS
	cp -av $$($$(PKG)_BUILDDIR)/bin/. $$(TARGET_DIR)/usr/bin
	cp -av $$($$(PKG)_BUILDDIR)/*/lib/*.so* $$(TARGET_DIR)/usr/lib || true
endef
endif
# Call the generic package infrastructure to generate the necessary
# make targets
$(call inner-generic-package,$(1),$(2),$(3),$(4))

endef

################################################################################
# conan-package -- the target generator macro for Conan packages
################################################################################

conan-package = $(call inner-conan-package,$(pkgname),$(call UPPERCASE,$(pkgname)),$(call UPPERCASE,$(pkgname)),target)
host-conan-package = $(call inner-conan-package,host-$(pkgname),$(call UPPERCASE,host-$(pkgname)),$(call UPPERCASE,$(pkgname)),host)
