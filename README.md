# AuthBypass

搞了个小工具，用来绕过江湖验证（`libLibJiangHu.a`）的卡密校验。

之前别人项目里用了这套验证，后来服务器到期了懒得续费，菜单直接打不开了。研究了一下发现验证逻辑其实挺简单的，核心就是一个全局变量控制开关，所以写了这个 tweak 直接把它跳过去。

## 怎么回事

江湖验证的流程大概是这样：

```
启动 app → 拿设备 UDID → 请求验证服务器 → 返回结果写到 abcdefg 变量里 → 菜单才能用
```

这个 tweak 做的事情很简单粗暴：
- 直接把 `abcdefg` 写成 1（验证通过的状态）
- hook 掉 `isAuthMenuPassed` 让它永远返回 YES
- 开个后台线程盯着，防止库里的心跳把状态重置回去

## 关于这个验证库

逆了一下 `.a` 文件，大概摸清了结构：

- 用了 Hikari 混淆编译的，IDA 看起来一坨，但不影响从外面 hook
- 通信走的 HTTPS + AES 加密，不过我们根本不需要管通信层
- 里面有个 NSTimer 做心跳，验证失败会把状态清掉
- `abcdefg` 是个全局符号，没 strip 掉，直接 extern 就能访问

说白了就是验证做得再花哨，最后还是要写一个变量来告诉业务层"我验证过了"，把这个变量钉死就完事了。

## 用法

**直接丢进项目编译（最省事）：**

把 `AuthBypass.mm` 拖进你的 Xcode 工程，确保它参与编译就行。不需要改任何其他代码，constructor 会自动执行。

**Theos 编译成 tweak：**

```bash
export THEOS=~/theos
make
make package
make install
```

**编译成 dylib 注入：**

```bash
clang++ -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -shared -o AuthBypass.dylib \
  -framework Foundation \
  -framework UIKit \
  -lobjc \
  AuthBypass.mm
```

## 注意事项

- `AuthBypass.plist` 里的 Bundle ID 记得改成你自己的目标 app
- constructor 优先级设的 90，比一般的 constructor 早执行，确保在验证库跑起来之前就把值改好
- 如果你的目标不是江湖验证，思路是一样的：找到控制验证状态的变量或方法，从外面改掉就行

## 文件说明

```
AuthBypass.mm       → 核心代码，就几十行
AuthBypass.h        → 头文件
AuthBypass.plist    → 注入过滤器，填目标 app 的 bundle id
Makefile            → theos 编译用的
control             → deb 包信息
```

## 碎碎念

ObjC 天生对逆向友好，方法名没法混淆（混淆了 runtime 就废了），所以不管验证库怎么加固，只要业务层是 ObjC 写的，hook 起来都很轻松。

这个库虽然用了 Hikari 的 BCF 和指令替换，反编译出来确实看不太懂，但完全不需要看懂它内部逻辑——从外面绕过就够了。

## 声明

学习逆向用的，别拿去干坏事。
