ifndef MIX_APP_PATH
	MIX_APP_PATH=$(shell pwd)
endif

PRIV_DIR = $(MIX_APP_PATH)/priv
NIF_SO = $(PRIV_DIR)/adbc_nif.so
ADBC_SRC = $(shell pwd)/3rd_party/apache-arrow-adbc
ADBC_C_SRC = $(shell pwd)/3rd_party/apache-arrow-adbc/c
ADBC_DRIVER_COMMON_LIB = $(PRIV_DIR)/libadbc_driver_common.dylib
C_SRC = $(shell pwd)/c_src
ifdef CMAKE_TOOLCHAIN_FILE
	CMAKE_CONFIGURE_FLAGS=-D CMAKE_TOOLCHAIN_FILE="$(CMAKE_TOOLCHAIN_FILE)"
endif

CMAKE_BUILD_TYPE ?= Release
DEFAULT_JOBS ?= 1
CMAKE_ADBC_BUILD_DIR = $(MIX_APP_PATH)/cmake_adbc
CMAKE_ADBC_OPTIONS ?= ""
CMAKE_ADBC_NIF_BUILD_DIR = $(MIX_APP_PATH)/cmake_adbc_nif
CMAKE_ADBC_NIF_OPTIONS ?= ""
MAKE_BUILD_FLAGS ?= -j$(DEFAULT_JOBS)

.DEFAULT_GLOBAL := build

build: $(NIF_SO)
	@echo > /dev/null

adbc:
	@ mkdir -p "$(PRIV_DIR)"
	@ if [ ! -f "$(ADBC_DRIVER_COMMON_LIB)" ]; then \
		mkdir -p "$(CMAKE_ADBC_BUILD_DIR)" && \
		cd "$(CMAKE_ADBC_BUILD_DIR)" && \
		cmake --no-warn-unused-cli \
			-DADBC_BUILD_SHARED="YES" \
			-DADBC_DRIVER_MANAGER="YES" \
			-DADBC_DRIVER_POSTGRESQL="NO" \
			-DADBC_DRIVER_SQLITE="YES" \
			-DADBC_DRIVER_FLIGHTSQL="NO" \
			-DADBC_DRIVER_SNOWFLAKE="NO" \
			-DADBC_BUILD_STATIC="NO" \
			-DADBC_BUILD_TESTS="NO" \
			-DADBC_USE_ASAN="NO" \
			-DADBC_USE_UBSAN="NO" \
			-DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DCMAKE_INSTALL_PREFIX="${PRIV_DIR}" \
			$(CMAKE_CONFIGURE_FLAGS) $(CMAKE_ADBC_OPTIONS) "$(ADBC_C_SRC)" && \
    	cmake --build . --target install -j ; \
	fi

$(NIF_SO): adbc
	@ mkdir -p "$(PRIV_DIR)"
	@ if [ ! -f "$(NIF_SO)" ]; then \
		mkdir -p "$(CMAKE_ADBC_NIF_BUILD_DIR)" && \
		cd "$(CMAKE_ADBC_NIF_BUILD_DIR)" && \
		cmake --no-warn-unused-cli \
			-D CMAKE_BUILD_TYPE="$(CMAKE_BUILD_TYPE)" \
			-D C_SRC="$(C_SRC)" \
			-D ADBC_SRC="$(ADBC_SRC)" \
			-D MIX_APP_PATH="$(MIX_APP_PATH)" \
			-D PRIV_DIR="$(PRIV_DIR)" \
			-D ERTS_INCLUDE_DIR="$(ERTS_INCLUDE_DIR)" \
			$(CMAKE_CONFIGURE_FLAGS) $(CMAKE_ADBC_NIF_OPTIONS) "$(shell pwd)" && \
		make "$(MAKE_BUILD_FLAGS)" && \
		cp "$(CMAKE_ADBC_NIF_BUILD_DIR)/adbc_nif.so" "$(NIF_SO)" ; \
	fi