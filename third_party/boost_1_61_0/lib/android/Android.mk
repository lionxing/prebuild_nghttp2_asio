LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    		:= libboost_system
LOCAL_EXPORT_C_INCLUDES := ../../include
LOCAL_SRC_FILES 		:= $(TARGET_ARCH_ABI)/libboost_system-mt.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    		:= libboost_thread
LOCAL_EXPORT_C_INCLUDES := ../../include
LOCAL_SRC_FILES 		:= $(TARGET_ARCH_ABI)/libboost_thread-mt.a
include $(PREBUILT_STATIC_LIBRARY)
