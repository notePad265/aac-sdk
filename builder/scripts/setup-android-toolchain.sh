#!/bin/bash
set -e

THISDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${THISDIR}/common.sh

# Default external values
: ${NDK_PACKAGE:="android-ndk-r16b"}
: ${NDK_SHA1SUM:="42aa43aae89a50d1c66c3f9fdecd676936da6128"}

# Extra options
ANDROID_ABI=${1}
API_LEVEL=${2}

#
# Param checks
#

if [ -z ${ANDROID_TOOLCHAIN} ]; then
	error "ANDROID_TOOLCHAIN is not set"
fi

if [ -z ${ANDROID_ABI} ] || [ -z ${API_LEVEL} ]; then
	error "Please specify ABI/API"
fi

# Android toolchain path
ANDROID_NDK="${ANDROID_TOOLCHAIN}/ndk"
ANDROID_SDK="${ANDROID_TOOLCHAIN}/sdk"

# Standard Android path
ANDROID_NDK_HOME="${ANDROID_NDK}/ndk-bundle/${NDK_PACKAGE}"

# OS detection
if [ $(uname) = "Darwin" ]; then
	HOST="darwin"
else
	HOST="linux"
fi

install() {
	filename=${1}
	checksum=${2}
	dest=${3}
	tmpdir=${ANDROID_TOOLCHAIN}
	tmpfile=${tmpdir}/${filename}

	if [ -e ${tmpfile} ] && [ ! "$(sha1sum ${tmpfile})" = "${checksum}" ]; then
		warn "SHA1 checksum is wrong, re-download NDK package..."
		rm ${tmpfile}
	fi
	if [ ! -e ${dest} ]; then
		note "Downloading file ${filename}"
		wget https://dl.google.com/android/repository/${filename} -P ${tmpdir}
		sha1sum ${tmpfile}
	fi
	mkdir -p ${dest}
	pushd ${dest}
	unzip -q ${tmpfile}
	popd
}

generate_toolchain() {
	case ${ANDROID_ABI} in
		x86)
			ARCH="x86"
			;;
		x86_64)
			ARCH="x86_64"
			;;
		armeabi-v7a)
			ARCH="arm"
			;;
		arm64-v8a)
			ARCH="arm64"
			;;
		*)
			error "Unknown ABI: ${ANDROID_ABI}"
	esac

	TOOLCHAIN="${ANDROID_NDK}/toolchains/${NDK_PACKAGE}/toolchain-${ANDROID_ABI}/android-${API_LEVEL}"

	if [ ! -d ${TOOLCHAIN} ]; then
		note "Generating Standalone Toolchain..."

		${ANDROID_NDK}/ndk-bundle/${NDK_PACKAGE}/build/tools/make_standalone_toolchain.py \
		--arch="${ARCH}" \
		--api="${API_LEVEL}" \
		--stl="libc++" \
		--force \
		--install-dir="${TOOLCHAIN}"
	fi
}

note "Checking Android toolchain installation (${ANDROID_ABI}/${API_LEVEL})..."

if [ ! -d ${ANDROID_NDK_HOME} ]; then
	note "Installing NDK (${NDK_PACKAGE})..."
	install ${NDK_PACKAGE}-${HOST}-x86_64.zip ${NDK_SHA1SUM} ${ANDROID_NDK}/ndk-bundle
fi
if [ ! -d ${ANDROID_SDK} ]; then
	note "Installing SDK Tools..."
	install sdk-tools-${HOST}-3859397.zip "7eab0ada7ff28487e1b340cc3d866e70bcb4286e" ${ANDROID_SDK}
fi

generate_toolchain