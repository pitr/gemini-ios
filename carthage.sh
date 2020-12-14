#!/usr/bin/env bash

set -euo pipefail

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)

echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e armv7 armv7s armv6 armv8' >> $xcconfig
echo 'EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))' >> $xcconfig
echo 'IPHONEOS_DEPLOYMENT_TARGET=11.4' >> $xcconfig
echo 'SWIFT_TREAT_WARNINGS_AS_ERRORS=NO' >> $xcconfig
echo 'GCC_TREAT_WARNINGS_AS_ERRORS=NO' >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"
cat $XCODE_XCCONFIG_FILE
carthage bootstrap --platform ios --color auto --cache-builds
