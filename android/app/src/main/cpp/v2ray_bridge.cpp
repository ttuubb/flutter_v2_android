#include <jni.h>
#include <string>
#include <android/log.h>

#define TAG "V2RayBridge"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// V2Ray核心库函数声明，由V2Ray核心提供
extern "C" {
    // 启动V2Ray
    extern int startV2Ray(const char* configPath);
    
    // 停止V2Ray
    extern int stopV2Ray();
    
    // 获取V2Ray版本
    extern const char* getV2RayVersion();
}

extern "C" JNIEXPORT jint JNICALL
Java_com_v2ray_ang_flutter_1v2_1android_v2ray_V2RayNative_startV2Ray(
        JNIEnv* env,
        jobject /* this */,
        jstring configPath) {
    
    LOGI("JNI: 启动V2Ray");
    
    const char* nativeConfigPath = env->GetStringUTFChars(configPath, 0);
    int result = startV2Ray(nativeConfigPath);
    env->ReleaseStringUTFChars(configPath, nativeConfigPath);
    
    LOGI("JNI: V2Ray启动结果: %d", result);
    return result;
}

extern "C" JNIEXPORT void JNICALL
Java_com_v2ray_ang_flutter_1v2_1android_v2ray_V2RayNative_stopV2Ray(
        JNIEnv* env,
        jobject /* this */) {
    
    LOGI("JNI: 停止V2Ray");
    stopV2Ray();
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_v2ray_ang_flutter_1v2_1android_v2ray_V2RayNative_getV2RayVersion(
        JNIEnv* env,
        jobject /* this */) {
    
    LOGI("JNI: 获取V2Ray版本");
    const char* version = getV2RayVersion();
    return env->NewStringUTF(version);
} 