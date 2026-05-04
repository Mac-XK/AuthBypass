TARGET := iphone:clang:15.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AuthBypass

AuthBypass_FILES = AuthBypass.mm
AuthBypass_CFLAGS = -fobjc-arc
AuthBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
