#include <jni.h>
#include <string>

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_democ_MainActivity_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}
//extern "C"
//JNIEXPORT jbyteArray JNICALL
//Java_com_example_democ_MainActivity_curve25519_1donna(JNIEnv *env, jobject thiz) {
//    // TODO: implement curve25519_donna()
//}