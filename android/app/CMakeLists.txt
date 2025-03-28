cmake_minimum_required(VERSION 3.4.1)

# 设置项目名称
project(v2ray_android)

# 添加自定义库目录
set(LIBS_DIR ${CMAKE_SOURCE_DIR}/src/main/jniLibs)

# 添加V2Ray核心库作为导入库
add_library(v2raycore SHARED IMPORTED)
set_target_properties(v2raycore PROPERTIES IMPORTED_LOCATION ${LIBS_DIR}/${ANDROID_ABI}/libv2raycore.so)

# 添加V2Ray桥接库作为导入库
add_library(v2ray SHARED IMPORTED)
set_target_properties(v2ray PROPERTIES IMPORTED_LOCATION ${LIBS_DIR}/${ANDROID_ABI}/libv2ray.so)

# 创建V2Ray桥接库
add_library(v2ray_bridge SHARED
            src/main/cpp/v2ray_bridge.cpp)

# 设置包含目录
target_include_directories(v2ray_bridge PRIVATE
            src/main/cpp)

# 链接库
target_link_libraries(v2ray_bridge
            v2ray
            v2raycore
            android
            log) 