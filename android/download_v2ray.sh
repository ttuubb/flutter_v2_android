#!/bin/bash

# 脚本参数
V2RAY_VERSION="v4.45.2"
BASE_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}"
APP_PATH="$(pwd)/app"
JNI_LIBS_PATH="${APP_PATH}/src/main/jniLibs"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -v, --version  指定V2Ray版本（默认：${V2RAY_VERSION}）"
    echo "  -c, --clean    清理临时文件"
    exit 0
}

# 清理临时文件
clean_temp_files() {
    echo "清理临时文件..."
    rm -rf v2ray.zip
    rm -rf v2ray-temp
    echo "完成！"
    exit 0
}

# 处理参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            ;;
        -v|--version)
            V2RAY_VERSION="$2"
            BASE_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}"
            shift
            shift
            ;;
        -c|--clean)
            clean_temp_files
            ;;
        *)
            echo "未知选项: $1"
            show_help
            ;;
    esac
done

# 创建目录
mkdir -p "${JNI_LIBS_PATH}/arm64-v8a"
mkdir -p "${JNI_LIBS_PATH}/armeabi-v7a"
mkdir -p "${JNI_LIBS_PATH}/x86"
mkdir -p "${JNI_LIBS_PATH}/x86_64"

# 下载平台对应的库文件
download_and_extract() {
    local platform=$1
    local abi=$2
    local filename="v2ray-linux-${platform}.zip"
    local url="${BASE_URL}/${filename}"
    
    echo "下载 $filename..."
    curl -L -o "v2ray.zip" "$url" || { echo "下载失败！"; exit 1; }
    
    echo "解压文件..."
    mkdir -p "v2ray-temp"
    unzip -o "v2ray.zip" -d "v2ray-temp" || { echo "解压失败！"; exit 1; }
    
    echo "复制库文件到 ${abi} 目录..."
    cp "v2ray-temp/v2ray" "${JNI_LIBS_PATH}/${abi}/libv2ray.so" || { echo "复制失败！"; exit 1; }
    cp "v2ray-temp/geoip.dat" "${APP_PATH}/src/main/assets/geoip.dat" || { echo "复制GeoIP失败！"; exit 1; }
    cp "v2ray-temp/geosite.dat" "${APP_PATH}/src/main/assets/geosite.dat" || { echo "复制GeoSite失败！"; exit 1; }
    cp "v2ray-temp/v2ctl" "${JNI_LIBS_PATH}/${abi}/libv2rayctl.so" || { echo "复制V2Ctl失败！"; exit 1; }
    
    # 清理临时文件
    rm -rf "v2ray.zip"
    rm -rf "v2ray-temp"
}

# 创建资源目录
mkdir -p "${APP_PATH}/src/main/assets"

# 下载不同平台的V2Ray
echo "开始下载V2Ray核心库（版本：${V2RAY_VERSION}）..."

download_and_extract "arm64-v8a" "arm64-v8a"
download_and_extract "arm" "armeabi-v7a"
download_and_extract "386" "x86"
download_and_extract "amd64" "x86_64"

echo "所有文件下载并复制完成！" 