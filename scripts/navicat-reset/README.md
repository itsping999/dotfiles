# Navicat Reset Scripts

用于清理 Navicat Premium 的本地注册状态。脚本会删除本地注册/试用相关数据，执行前关闭 Navicat，并确认目标是 Navicat Premium。

macOS：

```bash
bash ./scripts/navicat-reset/navicat-reset-macos.sh
```

Windows：

```cmd
scripts\navicat-reset\navicat-reset-windows.bat
```

macOS 脚本处理应用支持目录、偏好设置和登录钥匙串中的匹配项；Windows 脚本处理当前用户注册表中的匹配项。两个脚本都不会触碰其他 Navicat 版本或无关软件。执行后重新启动 Navicat 验证结果。
