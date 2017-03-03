LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    		:= libcrypto
LOCAL_EXPORT_C_INCLUDES := ../../include
LOCAL_SRC_FILES 		:= $(TARGET_ARCH_ABI)/libcrypto.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    		:= libssl
LOCAL_EXPORT_C_INCLUDES := ../../include
LOCAL_SRC_FILES 		:= $(TARGET_ARCH_ABI)/libssl.a
include $(PREBUILT_STATIC_LIBRARY)
