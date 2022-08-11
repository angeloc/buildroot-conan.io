################################################################################
#
# Conan examples folly
#
################################################################################

CONAN_EXAMPLES_FOLLY_VERSION = 6eaf6646bd1d321991428dbe016d8ba69c68fc78
CONAN_EXAMPLES_FOLLY_LICENSE = MIT
CONAN_EXAMPLES_FOLLY_LICENSE_FILES = LICENSE
CONAN_EXAMPLES_FOLLY_SITE = $(call github,conan-io,examples,$(CONAN_EXAMPLES_FOLLY_VERSION))
CONAN_EXAMPLES_FOLLY_SUBDIR = libraries/folly/basic
CONAN_EXAMPLES_FOLLY_SUPPORTS_IN_SOURCE_BUILD=NO

$(eval $(conan-package))
