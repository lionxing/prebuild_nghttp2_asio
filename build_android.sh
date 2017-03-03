#!/bin/bash

set -e

echo "check android-ndk"
echo -n "android-ndk root path ?> "
read INPUT
if [ -z "${INPUT}" ]; then
	echo 'not exist android-ndk: '${INPUT}
	exit 1
fi
echo 'exist android-ndk: '${INPUT}
NDK_ROOT=${INPUT}

NGHTTP2_VERNUM="1.20.0"
NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
NGHTTP2="${PWD}/nghttp2"
THIRD_PARTY="${PWD}/third_party"


echo "Cleaning up"
rm -rf ${NGHTTP2}/android/


if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	curl -LO https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERNUM}/${NGHTTP2_VERSION}.tar.gz
else
	echo "Using ${NGHTTP2_VERSION}.tar.gz"
fi


echo "Unpacking nghttp2"
tar xfz "${NGHTTP2_VERSION}.tar.gz"


echo 'build toolchain armeabi-v7a'

TOOLCHAIN="${NGHTTP2}/android/toolchain/armeabi-v7a"

cd ${NDK_ROOT}/build/tools
./make-standalone-toolchain.sh \
	--system=darwin-x86_64 \
	--toolchain=arm-linux-androideabi-4.9 \
	--arch=arm \
	--stl=gnustl \
	--platform=android-19 \
	--ndk-dir=${NDK_ROOT} \
	--install-dir=${TOOLCHAIN}


echo 'build armeabi-v7a'

PREFIX="${NGHTTP2}/android/armeabi-v7a"
HOST=arm-linux-androideabi
PATH=$TOOLCHAIN/arm-linux-androideabi/bin:$PATH

cd ${NGHTTP2}/../${NGHTTP2_VERSION}
./Configure \
	--disable-shared \
	--disable-app \
	--disable-threads \
	--enable-lib-only \
	--enable-asio-lib \
	--prefix=$PREFIX \
	--host=${HOST} \
	CC="${TOOLCHAIN}/bin/${HOST}-gcc" \
	CXX="${TOOLCHAIN}/bin/${HOST}-g++" \
	LD="${TOOLCHAIN}/bin/${HOST}-ld" \
	AR="${TOOLCHAIN}/bin/${HOST}-ar" \
	RANLIB="${TOOLCHAIN}/bin/${HOST}-ranlib" \
	STRIP="${TOOLCHAIN}/bin/${HOST}-strip" \
	CFLAGS="-march=armv7-a" \
	CXXFLAGS="-march=armv7-a -fPIE -fno-strict-aliasing -std=c++11" \
	LDFLAGS="-march=armv7-a -fPIE -pie" \
	OPENSSL_CFLAGS="-I${THIRD_PARTY}/openssl_1_0_2j/include" \
    OPENSSL_LIBS="-L${THIRD_PARTY}/openssl_1_0_2j/lib/android/armeabi-v7a" \
    BOOST_CPPFLAGS="-I${THIRD_PARTY}/boost_1_61_0/include" \
    BOOST_LDFLAGS="-L${THIRD_PARTY}/boost_1_61_0/lib/android/armeabi-v7a"

make -j8
make install
make clean

echo 'build toolchain x86'

TOOLCHAIN="${NGHTTP2}/android/toolchain/x86"

cd ${NDK_ROOT}/build/tools
./make-standalone-toolchain.sh \
	--system=darwin-x86_64 \
	--toolchain=x86-4.9 \
	--arch=x86 \
	--stl=gnustl \
	--platform=android-19 \
	--ndk-dir=${NDK_ROOT} \
	--install-dir=${TOOLCHAIN}


echo 'build x86'

PREFIX="${NGHTTP2}/android/x86"
HOST=i686-linux-android
PATH=$TOOLCHAIN/x86/bin:$PATH

cd ${NGHTTP2}/../${NGHTTP2_VERSION}
./Configure \
	--disable-shared \
	--disable-app \
	--disable-threads \
	--enable-lib-only \
	--enable-asio-lib \
	--prefix=$PREFIX \
	--host=${HOST} \
	CC="${TOOLCHAIN}/bin/${HOST}-gcc" \
	CXX="${TOOLCHAIN}/bin/${HOST}-g++" \
	LD="${TOOLCHAIN}/bin/${HOST}-ld" \
	AR="${TOOLCHAIN}/bin/${HOST}-ar" \
	RANLIB="${TOOLCHAIN}/bin/${HOST}-ranlib" \
	STRIP="${TOOLCHAIN}/bin/${HOST}-strip" \
	CXXFLAGS="-fPIE -fno-strict-aliasing -std=c++11" \
	LDFLAGS="-fPIE -pie" \
	OPENSSL_CFLAGS="-I${THIRD_PARTY}/openssl_1_0_2j/include" \
    OPENSSL_LIBS="-L${THIRD_PARTY}/openssl_1_0_2j/libs/android/x86" \
	BOOST_CPPFLAGS="-I${THIRD_PARTY}/boost_1_61_0/include" \
    BOOST_LDFLAGS="-L${THIRD_PARTY}/boost_1_61_0/lib/android/x86"

make -j8
make install
make clean

echo "Cleaning up"
rm -rf "${NGHTTP2}/../${NGHTTP2_VERSION}"
rm -rf "${NGHTTP2}/../${NGHTTP2_VERSION}.tar.gz"

echo "Done"
