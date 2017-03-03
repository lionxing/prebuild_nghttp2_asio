#!/bin/bash

set -e

usage ()
{
	echo "usage: $0 [iOS SDK version (defaults to latest)] [tvOS SDK version (defaults to latest)]"
	exit 127
}

if [ "$1" == "-h" ]; then
	usage
fi

if [ -z $1 ]; then
	IOS_SDK_VERSION="" #"9.1"
	IOS_MIN_SDK_VERSION="9.0"
else
	IOS_SDK_VERSION=$1
fi


# --- Edit this to update version ---
NGHTTP2_VERNUM="1.20.0"

NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
DEVELOPER=`xcode-select -print-path`

NGHTTP2="${PWD}/nghttp2"
THIRD_PARTY="${PWD}/third_party"

buildIOS()
{
	ARCH=$1
	BITCODE=$2

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        PLATFORM="iPhoneSimulator"
	else
        PLATFORM="iPhoneOS"
	fi

	if [[ "${BITCODE}" == "nobitcode" ]]; then
			CC_BITCODE_FLAG=""
	else
			CC_BITCODE_FLAG="-fembed-bitcode"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
  export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
  export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
  export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"

  export OPENSSL_CFLAGS="-I${THIRD_PARTY}/openssl_1_0_2j/include"
  export OPENSSL_LIBS="-L${THIRD_PARTY}/openssl_1_0_2j/lib/ios"
  export BOOST_CPPFLAGS="-I${THIRD_PARTY}/boost_1_61_0/include"
  export BOOST_LDFLAGS="-L${THIRD_PARTY}/boost_1_61_0/lib/ios"

	echo "Building ${NGHTTP2_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
	if [[ "${ARCH}" == "arm64" ]]; then
			./configure --disable-shared --disable-app --disable-threads --enable-lib-only --enable-asio-lib --prefix="${NGHTTP2}/ios/${ARCH}" --host="arm-apple-darwin" &> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	else
			./configure --disable-shared --disable-app --disable-threads --enable-lib-only --enable-asio-lib --prefix="${NGHTTP2}/ios/${ARCH}" --host="${ARCH}-apple-darwin" &> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	fi

	make -j8 >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make install >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	popd > /dev/null
}


echo "Cleaning up"
rm -rf "${NGHTTP2}/ios"
rm -rf "/tmp/${NGHTTP2_VERSION}-*"
rm -rf "/tmp/${NGHTTP2_VERSION}-*.log"

mkdir -p "${NGHTTP2}/ios/lib"


if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	curl -LO https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERNUM}/${NGHTTP2_VERSION}.tar.gz
else
	echo "Using ${NGHTTP2_VERSION}.tar.gz"
fi


echo "Unpacking nghttp2"
tar xfz "${NGHTTP2_VERSION}.tar.gz"


echo "Building iOS libraries (bitcode)"
buildIOS "armv7" "bitcode"
buildIOS "arm64" "bitcode"

lipo \
	"${NGHTTP2}/ios/armv7/lib/libnghttp2.a" \
	"${NGHTTP2}/ios/arm64/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/ios/lib/libnghttp2.a"

lipo \
	"${NGHTTP2}/ios/armv7/lib/libnghttp2_asio.a" \
	"${NGHTTP2}/ios/arm64/lib/libnghttp2_asio.a" \
	-create -output "${NGHTTP2}/ios/lib/libnghttp2_asio.a"


echo "Cleaning up"
rm -rf /tmp/${NGHTTP2_VERSION}-*
rm -rf "${NGHTTP2}/../${NGHTTP2_VERSION}"
rm -rf "${NGHTTP2}/../${NGHTTP2_VERSION}.tar.gz"

echo "Done"
