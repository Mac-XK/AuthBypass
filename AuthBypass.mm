//
//  AuthBypass.mm
//  绕过江湖验证的卡密校验，让菜单直接能用
//

#import <objc/runtime.h>
#import <dlfcn.h>

// 这个变量定义在 libLibJiangHu.a 里面，1 = 验证通过
extern int abcdefg;

#pragma mark - Hook

static IMP orig_isAuthMenuPassed = NULL;

// 直接返回 YES，不走原来的验证判断
static BOOL hooked_isAuthMenuPassed(id self, SEL _cmd) {
    return YES;
}

#pragma mark - 入口

static void __attribute__((constructor(90))) _auth_bypass_init_() {
    // 把验证标志位直接设成通过
    abcdefg = 1;

    // hook isAuthMenuPassed，兜底用的
    // 防止某些地方直接调这个方法而不是读变量
    Class cls = objc_getClass("MenuLoad");
    if (cls) {
        SEL sel = @selector(isAuthMenuPassed);
        Method method = class_getClassMethod(cls, sel);
        if (method) {
            orig_isAuthMenuPassed = method_getImplementation(method);
            method_setImplementation(method, (IMP)hooked_isAuthMenuPassed);
        }
    }

    // 后台盯着这个变量，库里有心跳可能会把它重置回 0
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        while (true) {
            if (abcdefg != 1) {
                abcdefg = 1;
            }
            usleep(3000 * 1000);
        }
    });
}
