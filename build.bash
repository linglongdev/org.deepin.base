#!/bin/bash
set -e
set -x

LOCAL_CONFIG=mkosi.local.conf

rm $LOCAL_CONFIG || true

ARCH=$1

apt_tree=mkosi.apt.deepin

case $ARCH in
amd64)
    LINGLONG_ARCH="x86_64"
    TRIPLET_LIST="x86_64-linux-gnu"
    ;;
arm64)
    LINGLONG_ARCH="arm64"
    TRIPLET_LIST="aarch64-linux-gnu"
    ;;
loongarch64)
    LINGLONG_ARCH="loongarch64"
    TRIPLET_LIST="loongarch64-linux-gnu"
    ;;
loong64)
    LINGLONG_ARCH="loong64"
    TRIPLET_LIST="loongarch64-linux-gnu"
    ;;
sw64)
    LINGLONG_ARCH="sw64"
    TRIPLET_LIST="sw_64-linux-gnu"
    apt_tree="mkosi.apt.uniontech"
    ;;
mips64)
    LINGLONG_ARCH="mips64"
    TRIPLET_LIST="mips64el-linux-gnuabi64"
    ;;

"") echo "enter an architecture, like ./build_base.sh amd64" && exit ;;
*) echo "unknow arch \"$ARCH\", supported arch: amd64, arm64, loongarch64, loong64" && exit ;;
esac

export LINGLONG_ARCH
export TRIPLET_LIST

rm -rf output || true

# 旧版本使用skeleton-tree新版本使用sandbox-tree
apt_tree_args_name=$(mkosi --help|grep sandbox &>/dev/null && echo --sandbox-tree || echo --skeleton-tree)

mkosi --force "$apt_tree_args_name" $apt_tree --output=image_binary
echo "[Content]" >> $LOCAL_CONFIG
echo "Packages=apt,elfutils,file,gcc,g++,gdb,gdbserver,cmake,make,automake,patchelf" >> $LOCAL_CONFIG
mkosi --force "$apt_tree_args_name" $apt_tree --output=image_develop

# 清理仓库中已存在的base
# shellcheck source=/dev/null
source version.bash

# 在项目目录生成linglong.yaml，用于ll-builder push
envsubst <templates/linglong.template.yaml >"linglong.yaml"

for module in binary develop; do
    # mkosi使用subuid，为避免权限问题，先制作tar格式的rootfs，再手动解压
    mkdir -p output/$module/files
    tar -xf output/image_$module -C output/$module/files
    # 生成linglong-triplet-list（记录架构信息）
    echo "$TRIPLET_LIST" >"output/$module/files/etc/linglong-triplet-list"
    # 生成packages.list(记录deb包列表信息)
    cat output/$module/files/var/lib/dpkg/status | awk '/^Package:/ {pkg=$2} /^Version:/ {print "Package: " pkg " " $2}' >"output/$module/files/packages.list"
    # 生成info.json(记录玲珑包信息)
    MODULE=$module envsubst <templates/info.template.json >"output/$module/info.json"
    # 生成appid.install(记录玲珑包文件列表)
    bash -c "cd output/$module/files && find | sed 's|^.||'" >"output/$module/$APPID.install"
    # 保存linglong.yaml(记录玲珑包构建信息)
    cp "linglong.yaml" "output/$module/"
done

# ll-builder list | grep "$APPID/$VERSION" | xargs ll-builder remove
# ll-builder import-dir output/binary
# ll-builder import-dir output/develop
