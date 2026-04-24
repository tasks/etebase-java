package com.etebase.client.internal;

public final class NativeLoader {
    private NativeLoader() {}

    public static void load() {
        System.loadLibrary("etebase_jni");
    }
}
