#!/usr/bin/env bash
set -e
REPO="$(pwd)"
ROOT="$REPO/.."

# Publish tarball
PLATFORM_LINUX="linux-$VSCODE_ARCH"
[[ "$VSCODE_ARCH" == "ia32" ]] && DEB_ARCH="i386" || DEB_ARCH="amd64"
[[ "$VSCODE_ARCH" == "ia32" ]] && RPM_ARCH="i386" || RPM_ARCH="x86_64"
BUILDNAME="VSCode-$PLATFORM_LINUX"
BUILD="$ROOT/$BUILDNAME"
BUILD_VERSION="$(date +%s)"
[ -z "$VSCODE_QUALITY" ] && TARBALL_FILENAME="code-$BUILD_VERSION.tar.gz" || TARBALL_FILENAME="code-$VSCODE_QUALITY-$BUILD_VERSION.tar.gz"
TARBALL_PATH="$ROOT/$TARBALL_FILENAME"
PACKAGEJSON="$BUILD/resources/app/package.json"
VERSION=$(node -p "require(\"$PACKAGEJSON\").version")

rm -rf $ROOT/code-*.tar.*
(cd $ROOT && tar -czf $TARBALL_PATH $BUILDNAME)

node build/azure-pipelines/common/publish.js "$VSCODE_QUALITY" "$PLATFORM_LINUX" archive-unsigned "$TARBALL_FILENAME" "$VERSION" true "$TARBALL_PATH"

# Publish hockeyapp symbols
node build/azure-pipelines/common/symbols.js "$VSCODE_MIXIN_PASSWORD" "$VSCODE_HOCKEYAPP_TOKEN" "$VSCODE_ARCH" "$VSCODE_HOCKEYAPP_ID_LINUX64"

# Publish DEB
yarn gulp "vscode-linux-$VSCODE_ARCH-build-deb"
PLATFORM_DEB="linux-deb-$VSCODE_ARCH"
[[ "$VSCODE_ARCH" == "ia32" ]] && DEB_ARCH="i386" || DEB_ARCH="amd64"
DEB_FILENAME="$(ls $REPO/.build/linux/deb/$DEB_ARCH/deb/)"
DEB_PATH="$REPO/.build/linux/deb/$DEB_ARCH/deb/$DEB_FILENAME"

node build/azure-pipelines/common/publish.js "$VSCODE_QUALITY" "$PLATFORM_DEB" package "$DEB_FILENAME" "$VERSION" true "$DEB_PATH"

# Publish RPM
yarn gulp "vscode-linux-$VSCODE_ARCH-build-rpm"
PLATFORM_RPM="linux-rpm-$VSCODE_ARCH"
[[ "$VSCODE_ARCH" == "ia32" ]] && RPM_ARCH="i386" || RPM_ARCH="x86_64"
RPM_FILENAME="$(ls $REPO/.build/linux/rpm/$RPM_ARCH/ | grep .rpm)"
RPM_PATH="$REPO/.build/linux/rpm/$RPM_ARCH/$RPM_FILENAME"

node build/azure-pipelines/common/publish.js "$VSCODE_QUALITY" "$PLATFORM_RPM" package "$RPM_FILENAME" "$VERSION" true "$RPM_PATH"

# Publish Snap
yarn gulp "vscode-linux-$VSCODE_ARCH-prepare-snap"

# Pack snap tarball artifact, in order to preserve file perms
mkdir -p $REPO/.build/linux/snap-tarball
SNAP_TARBALL_PATH="$REPO/.build/linux/snap-tarball/snap-$VSCODE_ARCH.tar.gz"
rm -rf $SNAP_TARBALL_PATH
(cd .build/linux && tar -czf $SNAP_TARBALL_PATH snap)
