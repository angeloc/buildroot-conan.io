include $(sort $(wildcard $(BR2_EXTERNAL_CONAN_PATH)/package/*/*.mk))

enable-conan:
	grep pkg-conan.mk package/Makefile.in || \
		echo "include $(BR2_EXTERNAL_CONAN_PATH)/package/pkg-conan.mk" >> package/Makefile.in
