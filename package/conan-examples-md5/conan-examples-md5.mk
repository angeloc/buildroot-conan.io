################################################################################
#
# Conan examples md5
#
################################################################################

CONAN_EXAMPLES_MD5_VERSION = 6eaf6646bd1d321991428dbe016d8ba69c68fc78
CONAN_EXAMPLES_MD5_LICENSE = MIT
CONAN_EXAMPLES_MD5_LICENSE_FILES = LICENSE
CONAN_EXAMPLES_MD5_SITE = $(call github,conan-io,examples,$(CONAN_EXAMPLES_MD5_VERSION))
CONAN_EXAMPLES_MD5_SUBDIR = libraries/poco/md5
CONAN_EXAMPLES_MD5_SUPPORTS_IN_SOURCE_BUILD=NO

$(eval $(conan-package))
