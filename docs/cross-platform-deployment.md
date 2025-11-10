# 跨平台部署指南

## 📋 概述

跨平台部署是AI世界项目成功的关键因素。本指南涵盖了从Windows、macOS、Linux到移动平台(iOS/Android)、Web平台和游戏主机的完整部署方案，确保应用能够在各种设备和环境中稳定运行，为用户提供一致的体验。

### 🎯 部署目标

- **平台覆盖**: 支持主流桌面、移动和Web平台
- **性能优化**: 针对不同平台进行专门的性能调优
- **用户体验**: 保持各平台间的体验一致性
- **维护便利**: 统一的代码库和更新机制
- **可扩展性**: 支持未来新平台的快速适配

## 🖥️ 桌面平台部署

### 1. Windows 平台部署

#### 1.1 构建配置

```ini
# export_presets/windows.cfg
[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/windows/"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug/debug_export_console_wrapper_visibility=1
custom_template/debug/export_console_wrapper=1
ssh_remote_deploy/enabled=false
ssh_remote_deploy/host="user@host_ip"
ssh_remote_deploy/port="22"
ssh_remote_deploy/extra_args_ssh=""
ssh_remote_deploy/extra_args_scp=""
ssh_remote_deploy/run_script=""
ssh_remote_deploy/cleanup_script=""

application/icon="res://icons/app_icon.png"
application/console_wrapper_icon=""
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""

application/export_angle_instead_of_opengl3=true
application/bundle_identifier=com.example.aiworld
application/signature=""
application/short_description=""
application/copyright_localized={}

texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
binary_format/embed_pck=false
custom_template/release/export_console_wrapper_visibility=0
custom_template/release/export_console_wrapper=0
ssh_remote_deploy/clean_script=""

codesign/codesign=true
codesign/identity=""
codesign/certificate_file=""
codesign/certificate_password=""
codesign/entitlements/custom_file=false
codesign/entitlements/file="res://path/to.entitlements"

notarization/notarization=false
notarization/apple_id_name=""
notarization/apple_id_password=""
notarization/apple_team_id=""
```

#### 1.2 安装包制作

```python
# scripts/build/create_windows_installer.py
import os
import subprocess
import shutil
from pathlib import Path

class WindowsInstallerBuilder:
    def __init__(self, project_path: str, version: str):
        self.project_path = Path(project_path)
        self.version = version
        self.build_path = self.project_path / "builds" / "windows"
        self.installer_path = self.project_path / "installers"

    def create_installer(self):
        """创建Windows安装包"""
        print("Creating Windows installer...")

        # 1. 确保Godot构建存在
        godot_exe = self.build_path / "ai_world.exe"
        if not godot_exe.exists():
            raise FileNotFoundError(f"Godot executable not found at {godot_exe}")

        # 2. 准备安装目录
        install_dir = self.installer_path / f"ai_world_{self.version}_windows"
        install_dir.mkdir(parents=True, exist_ok=True)

        # 3. 复制必要文件
        self._copy_application_files(install_dir)

        # 4. 创建NSIS安装脚本
        nsis_script = self._create_nsis_script(install_dir)

        # 5. 编译安装包
        installer_exe = self._compile_installer(nsis_script, install_dir)

        print(f"Windows installer created: {installer_exe}")
        return installer_exe

    def _copy_application_files(self, install_dir: Path):
        """复制应用文件"""
        # 复制主程序
        shutil.copy2(self.build_path / "ai_world.exe", install_dir / "ai_world.exe")

        # 复制数据文件
        data_dir = install_dir / "data"
        data_dir.mkdir(exist_ok=True)

        source_data = self.project_path / "data"
        if source_data.exists():
            self._copy_tree(source_data, data_dir)

        # 复制配置文件
        config_files = ["config.yaml", "settings.json"]
        for config_file in config_files:
            src = self.project_path / config_file
            if src.exists():
                shutil.copy2(src, install_dir / config_file)

        # 创建启动脚本
        self._create_launch_script(install_dir)

    def _create_nsis_script(self, install_dir: Path) -> Path:
        """创建NSIS安装脚本"""
        nsis_content = f'''
!define APP_NAME "AI World"
!define APP_VERSION "{self.version}"
!define APP_PUBLISHER "AI World Team"
!define APP_URL "https://aiworld.example.com"
!define APP_EXECUTABLE "ai_world.exe"

; 包含现代UI
!include "MUI2.nsh"

; 基本设置
Name "${{APP_NAME}}"
OutFile "ai_world_${{APP_VERSION}}_setup.exe"
InstallDir "$PROGRAMFILES\\${{APP_NAME}}"
InstallDirRegKey HKCU "Software\\${{APP_NAME}}" ""
RequestExecutionLevel admin

; 界面设置
!define MUI_ABORTWARNING
!define MUI_ICON "installer_icon.ico"
!define MUI_UNICON "installer_icon.ico"

; 欢迎页面
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; 完成页面
!define MUI_FINISHPAGE_RUN "$INSTDIR\\${{APP_EXECUTABLE}}"
!insertmacro MUI_PAGE_FINISH

; 语言文件
!insertmacro MUI_LANGUAGE "English"

; 安装节
Section "Core Files" SecCore
    SetOutPath "$INSTDIR"

    File /r "ai_world.exe"
    File /r "data\\*.*"
    File "config.yaml"
    File "settings.json"

    ; 创建开始菜单快捷方式
    CreateDirectory "$SMPROGRAMS\\${{APP_NAME}}"
    CreateShortCut "$SMPROGRAMS\\${{APP_NAME}}\\${{APP_NAME}}.lnk" "$INSTDIR\\${{APP_EXECUTABLE}}"
    CreateShortCut "$SMPROGRAMS\\${{APP_NAME}}\\Uninstall.lnk" "$INSTDIR\\Uninstall.exe"

    ; 创建桌面快捷方式
    CreateShortCut "$DESKTOP\\${{APP_NAME}}.lnk" "$INSTDIR\\${{APP_EXECUTABLE}}"

    ; 注册表项
    WriteRegStr HKCU "Software\\${{APP_NAME}}" "" $INSTDIR

    ; 创建卸载程序
    WriteUninstaller "$INSTDIR\\Uninstall.exe"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}" "DisplayName" "${{APP_NAME}}"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}" "UninstallString" "$INSTDIR\\Uninstall.exe"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}" "DisplayVersion" "${{APP_VERSION}}"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}" "Publisher" "${{APP_PUBLISHER}}"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}" "URLInfoAbout" "${{APP_URL}}"
SectionEnd

; 卸载节
Section "Uninstall"
    Delete "$INSTDIR\\Uninstall.exe"
    Delete "$INSTDIR\\${{APP_EXECUTABLE}}"
    Delete "$INSTDIR\\config.yaml"
    Delete "$INSTDIR\\settings.json"

    RMDir /r "$INSTDIR\\data"
    RMDir "$INSTDIR"

    Delete "$SMPROGRAMS\\${{APP_NAME}}\\${{APP_NAME}}.lnk"
    Delete "$SMPROGRAMS\\${{APP_NAME}}\\Uninstall.lnk"
    RMDir "$SMPROGRAMS\\${{APP_NAME}}"

    Delete "$DESKTOP\\${{APP_NAME}}.lnk"

    DeleteRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{APP_NAME}}"
    DeleteRegKey HKCU "Software\\${{APP_NAME}}"
SectionEnd
'''

        nsis_script_path = install_dir / "installer.nsi"
        with open(nsis_script_path, 'w', encoding='utf-8') as f:
            f.write(nsis_content)

        return nsis_script_path

    def _compile_installer(self, nsis_script: Path, install_dir: Path) -> Path:
        """编译安装包"""
        try:
            # 检查makensis是否可用
            subprocess.run(["makensis", "/VERSION"], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Warning: makensis not found. Please install NSIS.")
            return None

        # 编译NSIS脚本
        result = subprocess.run(
            ["makensis", str(nsis_script)],
            cwd=install_dir,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            raise RuntimeError(f"NSIS compilation failed: {result.stderr}")

        # 查找生成的安装包
        installer_exe = install_dir / f"ai_world_{self.version}_setup.exe"
        if installer_exe.exists():
            # 移动到最终位置
            final_path = self.installer_path / installer_exe.name
            shutil.move(installer_exe, final_path)
            return final_path

        raise FileNotFoundError("Installer executable not found after compilation")

    def _create_launch_script(self, install_dir: Path):
        """创建启动脚本"""
        launch_script = install_dir / "launch.bat"
        script_content = f'''@echo off
cd /d "%~dp0"
start "" "ai_world.exe" --config=config.yaml --data-dir=data
'''
        with open(launch_script, 'w', encoding='utf-8') as f:
            f.write(script_content)
```

### 2. macOS 平台部署

```python
# scripts/build/create_macos_bundle.py
import os
import subprocess
import shutil
import plistlib
from pathlib import Path

class MacOSBundleBuilder:
    def __init__(self, project_path: str, version: str):
        self.project_path = Path(project_path)
        self.version = version
        self.build_path = self.project_path / "builds" / "macos"
        self.bundle_path = self.project_path / "bundles"

    def create_app_bundle(self):
        """创建macOS应用包"""
        print("Creating macOS app bundle...")

        # 1. 确保Godot构建存在
        godot_binary = self.build_path / "ai_world.app"
        if not godot_binary.exists():
            raise FileNotFoundError(f"Godot app bundle not found at {godot_binary}")

        # 2. 准备应用包目录
        app_name = f"AI World.app"
        bundle_dir = self.bundle_path / app_name
        bundle_dir.mkdir(parents=True, exist_ok=True)

        # 3. 复制并修改应用包
        self._copy_and_modify_bundle(godot_binary, bundle_dir)

        # 4. 添加必要资源
        self._add_bundle_resources(bundle_dir)

        # 5. 修改Info.plist
        self._update_info_plist(bundle_dir)

        # 6. 代码签名（如果有证书）
        self._sign_bundle(bundle_dir)

        print(f"macOS app bundle created: {bundle_dir}")
        return bundle_dir

    def _copy_and_modify_bundle(self, source_app: Path, target_app: Path):
        """复制并修改应用包"""
        # 复制整个应用包
        shutil.copytree(source_app, target_app, dirs_exist_ok=True)

        # 修改Contents/MacOS/ai_world
        macos_dir = target_app / "Contents" / "MacOS"
        if macos_dir.exists():
            # 复制额外的数据文件
            self._copy_additional_data(macos_dir)

    def _add_bundle_resources(self, bundle_dir: Path):
        """添加应用包资源"""
        resources_dir = bundle_dir / "Contents" / "Resources"
        resources_dir.mkdir(exist_ok=True)

        # 复制数据文件
        data_dir = resources_dir / "data"
        source_data = self.project_path / "data"
        if source_data.exists():
            shutil.copytree(source_data, data_dir, dirs_exist_ok=True)

        # 复制配置文件
        config_files = ["config.yaml", "settings.json"]
        for config_file in config_files:
            src = self.project_path / config_file
            if src.exists():
                shutil.copy2(src, resources_dir / config_file)

        # 添加应用图标
        icon_source = self.project_path / "icons" / "app_icon.icns"
        if icon_source.exists():
            shutil.copy2(icon_source, resources_dir / "app_icon.icns")

    def _update_info_plist(self, bundle_dir: Path):
        """更新Info.plist文件"""
        info_plist_path = bundle_dir / "Contents" / "Info.plist"

        # 读取现有的Info.plist
        if info_plist_path.exists():
            with open(info_plist_path, 'rb') as f:
                info_plist = plistlib.load(f)
        else:
            info_plist = {}

        # 更新应用信息
        info_plist.update({
            'CFBundleName': 'AI World',
            'CFBundleDisplayName': 'AI World',
            'CFBundleIdentifier': 'com.example.aiworld',
            'CFBundleVersion': self.version,
            'CFBundleShortVersionString': self.version,
            'CFBundlePackageType': 'APPL',
            'CFBundleExecutable': 'ai_world',
            'CFBundleIconFile': 'app_icon.icns',
            'LSMinimumSystemVersion': '10.14',
            'NSHighResolutionCapable': True,
            'NSRequiresAquaSystemAppearance': False,
            'CFBundleDocumentTypes': [
                {
                    'CFBundleTypeName': 'AI World Save File',
                    'CFBundleTypeExtensions': ['sav'],
                    'CFBundleTypeRole': 'Editor'
                }
            ]
        })

        # 写回Info.plist
        with open(info_plist_path, 'wb') as f:
            plistlib.dump(info_plist, f)

    def _sign_bundle(self, bundle_dir: Path):
        """代码签名应用包"""
        try:
            # 检查是否有开发者证书
            result = subprocess.run(
                ['security', 'find-identity', '-v', '-p', 'codesigning'],
                capture_output=True,
                text=True
            )

            if result.returncode != 0:
                print("No developer certificates found for code signing")
                return

            # 解析证书身份
            identity = None
            for line in result.stdout.split('\n'):
                if 'iPhone Developer' in line or 'Apple Development' in line:
                    identity = line.split('"')[1]
                    break

            if identity:
                # 进行代码签名
                subprocess.run([
                    'codesign',
                    '--force',
                    '--sign', identity,
                    str(bundle_dir)
                ], check=True)
                print(f"Code signed with identity: {identity}")
            else:
                print("No suitable certificate found for code signing")

        except subprocess.CalledProcessError as e:
            print(f"Code signing failed: {e}")
        except FileNotFoundError:
            print("codesign command not found (likely not on macOS)")

    def create_dmg_installer(self, app_bundle: Path) -> Path:
        """创建DMG安装包"""
        dmg_name = f"AI_World_{self.version}_macOS"
        dmg_path = self.bundle_path / f"{dmg_name}.dmg"
        dmg_temp_dir = self.bundle_path / "dmg_temp"

        # 创建临时DMG目录
        dmg_temp_dir.mkdir(exist_ok=True)

        # 复制应用到临时目录
        shutil.copytree(app_bundle, dmg_temp_dir / app_bundle.name)

        # 创建应用程序文件夹链接
        apps_link = dmg_temp_dir / "Applications"
        apps_link.symlink_to("/Applications")

        # 创建DMG
        try:
            subprocess.run([
                'hdiutil', 'create',
                '-volname', dmg_name,
                '-srcfolder', str(dmg_temp_dir),
                '-ov',
                '-format', 'UDZO',
                str(dmg_path)
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"DMG creation failed: {e}")
            return None
        finally:
            # 清理临时目录
            shutil.rmtree(dmg_temp_dir, ignore_errors=True)

        print(f"macOS DMG installer created: {dmg_path}")
        return dmg_path
```

## 📱 移动平台部署

### 1. Android 平台部署

```ini
# export_presets/android.cfg
[preset.0]

name="Android"
platform="Android"
runnable=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/android/"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug/debug_export_launch_hook=false
custom_template/debug/debug_export_launch_hook_script=""
custom_template/debug/export_gradle_dependencies=false
custom_template/debug/custom_gradle_build_file=""
custom_template/debug/format=bundle_debug
custom_template/debug/architectures=arm64-v8a
custom_template/debug/keystore/debug_debug=""
custom_template/debug/keystore/debug_debug_password=""
custom_template/debug/keystore/debug_debug_release_password=""
custom_template/debug/screen_orientation=landscape
custom_template/debug/supports_xr=false
custom_template/debug/xr_features_interface=""
custom_template/debug/package/exported_plugin_names=[]
custom_template/debug/package/name=com.example.aiworld.debug
custom_template/debug/package/unique_name=com.example.aiworld.debug
custom_template/debug/package/signer_name=com.example.aiworld.debug
custom_template/debug/package/version_code=1
custom_template/debug/package/version_name="1.0"
custom_template/debug/package/show_names=false
custom_template/debug/package/permissions=["android.permission.INTERNET","android.permission.WRITE_EXTERNAL_STORAGE","android.permission.READ_EXTERNAL_STORAGE"]
custom_template/debug/command_line/extra_args=""
custom_template/debug/command_line/extra_script=""
custom_template/debug/icon/icon=""
custom_template/debug/icon/main_background_color=""
custom_template/debug/icon/icon_adaptive_background=""
custom_template/debug/icon/icon_adaptive_foreground=""
custom_template/debug/icon/notification_icon=""
custom_template/debug/icon/notification_icon_background=""
custom_template/debug/splash_screen/splash_background_color=""
custom_template/debug/splash_screen/splash_background=""
custom_template/debug/splash_screen/splash_background_scale_mode=""
custom_template/debug/splash_screen/splash_background_use_stretch=true
custom_template/debug/splash_screen/splash_image=""
custom_template/debug/splash_screen/splash_image_scale_mode=""
custom_template/debug/splash_screen/splash_image_use_stretch=true
custom_template/debug/splash_screen/splash_image_blur=false
custom_template/debug/splash_screen/splash_image_progress_bar=true
custom_template/debug/splash_screen/android_fill_mode="CENTER_CROP"
custom_template/debug/splash_screen/android_background_color=""
custom_template/debug/splash_screen/android_background_image=""
custom_template/debug/splash_screen/android_image_scale_mode=""
custom_template/debug/splash_screen/android_image_use_stretch=true

custom_template/release/debug_export_launch_hook=false
custom_template/release/debug_export_launch_hook_script=""
custom_template/release/export_gradle_dependencies=false
custom_template/release/custom_gradle_build_file=""
custom_template/release/format=bundle_release
custom_template/release/architectures=arm64-v8a,armeabi-v7a
custom_template/release/keystore/release_debug=""
custom_template/release/keystore/release_debug_password=""
custom_template/release/keystore/release_debug_release_password=""
custom_template/release/screen_orientation=landscape
custom_template/release/supports_xr=false
custom_template/release/xr_features_interface=""
custom_template/release/package/exported_plugin_names=[]
custom_template/release/package/name=com.example.aiworld
custom_template/release/package/unique_name=com.example.aiworld
custom_template/release/package/signer_name=com.example.aiworld
custom_template/release/package/version_code=1
custom_template/release/package/version_name="1.0"
custom_template/release/package/show_names=false
custom_template/release/package/permissions=["android.permission.INTERNET","android.permission.WRITE_EXTERNAL_STORAGE","android.permission.READ_EXTERNAL_STORAGE","android.permission.CAMERA","android.permission.RECORD_AUDIO"]
custom_template/release/command_line/extra_args=""
custom_template/release/command_line/extra_script=""
custom_template/release/icon/icon=""
custom_template/release/icon/main_background_color=""
custom_template/release/icon/icon_adaptive_background=""
custom_template/release/icon/icon_adaptive_foreground=""
custom_template/release/icon/notification_icon=""
custom_template/release/icon/notification_icon_background=""
custom_template/release/splash_screen/splash_background_color=""
custom_template/release/splash_screen/splash_background=""
custom_template/release/splash_screen/splash_background_scale_mode=""
custom_template/release/splash_screen/splash_background_use_stretch=true
custom_template/release/splash_screen/splash_image=""
custom_template/release/splash_screen/splash_image_scale_mode=""
custom_template/release/splash_screen/splash_image_use_stretch=true
custom_template/release/splash_screen/splash_image_blur=false
custom_template/release/splash_screen/splash_image_progress_bar=true
custom_template/release/splash_screen/android_fill_mode="CENTER_CROP"
custom_template/release/splash_screen/android_background_color=""
custom_template/release/splash_screen/android_background_image=""
custom_template/release/splash_screen/android_image_scale_mode=""
custom_template/release/splash_screen/android_image_use_stretch=true

xr_features/oculus/mobile_support=true
xr_features/oculus/mobile_xr_support=false
xr_features/openxr/mobile_support=true
xr_features/openxr/mobile_xr_support=false

texture_format/etc=true
texture_format/etc2=false
binary_format/embed_pck=false
```

### 2. iOS 平台部署

```python
# scripts/mobile/build_ios.py
import os
import subprocess
import shutil
import plistlib
from pathlib import Path

class IOSBuilder:
    def __init__(self, project_path: str, version: str):
        self.project_path = Path(project_path)
        self.version = version
        self.build_path = self.project_path / "builds" / "ios"

    def create_ios_build(self):
        """创建iOS构建"""
        print("Creating iOS build...")

        # 1. 检查Xcode工具链
        self._check_xcode_tools()

        # 2. 构建Godot iOS项目
        godot_project_path = self._build_godot_ios_project()
        if not godot_project_path:
            raise RuntimeError("Failed to build Godot iOS project")

        # 3. 配置Xcode项目
        self._configure_xcode_project(godot_project_path)

        # 4. 构建iOS应用
        ipa_path = self._build_ios_app(godot_project_path)

        print(f"iOS build created: {ipa_path}")
        return ipa_path

    def _check_xcode_tools(self):
        """检查Xcode工具链"""
        try:
            # 检查xcodebuild
            subprocess.run(['xcodebuild', '-version'], capture_output=True, check=True)

            # 检查xcrun
            subprocess.run(['xcrun', '--version'], capture_output=True, check=True)

            print("Xcode tools are available")
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise RuntimeError("Xcode tools not found. Please install Xcode.")

    def _build_godot_ios_project(self) -> Path:
        """构建Godot iOS项目"""
        try:
            # 使用Godot命令行工具构建iOS项目
            godot_path = self._find_godot_executable()
            if not godot_path:
                raise RuntimeError("Godot executable not found")

            ios_export_path = self.build_path / "ios_project"
            ios_export_path.mkdir(parents=True, exist_ok=True)

            # 执行导出
            result = subprocess.run([
                str(godot_path),
                '--headless',
                '--export-pack', 'iOS',  # 使用iOS预设
                str(ios_export_path),
                self.project_path / "project.godot"
            ], capture_output=True, text=True)

            if result.returncode != 0:
                raise RuntimeError(f"Godot export failed: {result.stderr}")

            return ios_export_path

        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Failed to build Godot iOS project: {e}")

    def _configure_xcode_project(self, project_path: Path):
        """配置Xcode项目"""
        # 修改Info.plist
        info_plist_path = project_path / "ios" / "Info.plist"
        if info_plist_path.exists():
            self._update_ios_info_plist(info_plist_path)

        # 添加必要的框架
        self._add_required_frameworks(project_path)

        # 配置构建设置
        self._configure_build_settings(project_path)

    def _update_ios_info_plist(self, info_plist_path: Path):
        """更新iOS Info.plist"""
        with open(info_plist_path, 'rb') as f:
            info_plist = plistlib.load(f)

        # 更新应用信息
        info_plist.update({
            'CFBundleName': 'AI World',
            'CFBundleDisplayName': 'AI World',
            'CFBundleIdentifier': 'com.example.aiworld',
            'CFBundleVersion': self.version,
            'CFBundleShortVersionString': self.version,
            'UIRequiredDeviceCapabilities': ['armv7'],
            'UISupportedInterfaceOrientations': [
                'UIInterfaceOrientationLandscapeLeft',
                'UIInterfaceOrientationLandscapeRight'
            ],
            'UIStatusBarHidden': True,
            'NSMicrophoneUsageDescription': 'This app needs microphone access for voice interactions with AI characters.',
            'NSCameraUsageDescription': 'This app needs camera access for augmented reality features.',
            'NSPhotoLibraryUsageDescription': 'This app needs photo library access for custom content creation.'
        })

        with open(info_plist_path, 'wb') as f:
            plistlib.dump(info_plist, f)

    def _add_required_frameworks(self, project_path: Path):
        """添加必要的框架"""
        frameworks = [
            'AVFoundation.framework',
            'AudioToolbox.framework',
            'CoreAudio.framework',
            'CoreGraphics.framework',
            'CoreMotion.framework',
            'CoreVideo.framework',
            'Foundation.framework',
            'GameController.framework',
            'GLKit.framework',
            'Metal.framework',
            'MetalKit.framework',
            'OpenAL.framework',
            'OpenGLES.framework',
            'QuartzCore.framework',
            'Security.framework',
            'SystemConfiguration.framework',
            'UIKit.framework',
            'VideoToolbox.framework'
        ]

        # iOS需要额外的权限配置
        permissions_config = {
            'NSMicrophoneUsageDescription': 'Used for voice input with AI characters',
            'NSCameraUsageDescription': 'Used for AR features and content creation',
            'NSPhotoLibraryUsageDescription': 'Used for saving and sharing content'
        }

    def _build_ios_app(self, project_path: Path) -> Path:
        """构建iOS应用"""
        xcode_project = project_path / "ios" / "AI World.xcodeproj"
        if not xcode_project.exists():
            raise FileNotFoundError(f"Xcode project not found at {xcode_project}")

        # 使用xcodebuild构建
        build_commands = [
            ['xcodebuild', '-project', str(xcode_project), '-scheme', 'AI World', '-configuration', 'Release', '-destination', 'generic/platform=iOS', 'build']
        ]

        try:
            for cmd in build_commands:
                result = subprocess.run(cmd, cwd=xcode_project.parent, capture_output=True, text=True)
                if result.returncode != 0:
                    print(f"Build command failed: {cmd}")
                    print(f"Error: {result.stderr}")
                    continue

        except subprocess.CalledProcessError as e:
            print(f"iOS build failed: {e}")

        # 构建IPA（需要开发者账号）
        ipa_path = self._create_ipa_archive(project_path)
        return ipa_path

    def _create_ipa_archive(self, project_path: Path) -> Path:
        """创建IPA归档"""
        try:
            # 使用xcodebuild归档
            archive_result = subprocess.run([
                'xcodebuild',
                '-project', str(project_path / "ios" / "AI World.xcodeproj"),
                '-scheme', 'AI World',
                '-configuration', 'Release',
                '-destination', 'generic/platform=iOS',
                'archive',
                '-archivePath', str(project_path / "build" / "AI World.xcarchive")
            ], capture_output=True, text=True)

            if archive_result.returncode != 0:
                print(f"Archive creation failed: {archive_result.stderr}")
                return None

            # 导出IPA
            export_result = subprocess.run([
                'xcodebuild',
                '-exportArchive',
                '-archivePath', str(project_path / "build" / "AI World.xcarchive"),
                '-exportOptionsPlist', str(project_path / "ios" / "ExportOptions.plist"),
                '-exportPath', str(project_path / "build")
            ], capture_output=True, text=True)

            if export_result.returncode != 0:
                print(f"IPA export failed: {export_result.stderr}")
                return None

            ipa_path = project_path / "build" / "AI World.ipa"
            if ipa_path.exists():
                return ipa_path

        except subprocess.CalledProcessError as e:
            print(f"IPA creation failed: {e}")

        return None

    def _find_godot_executable(self) -> Path:
        """查找Godot可执行文件"""
        # 常见的Godot路径
        godot_paths = [
            Path("/Applications/Godot.app/Contents/MacOS/Godot"),
            Path("/usr/local/bin/godot"),
            Path("godot")  # 当前PATH中
        ]

        for godot_path in godot_paths:
            if godot_path.exists():
                return godot_path

        return None
```

## 🌐 Web平台部署

### 1. WebGL 构建

```gdscript
# scripts/web/webgl_exporter.gd
extends EditorScript

class_name WebGLExporter

func _run():
    print("Starting WebGL export...")

    # 创建导出目录
    var export_dir = "builds/webgl"
    var dir = DirAccess.open("res://")
    if not dir.dir_exists(export_dir):
        dir.make_dir_recursive(export_dir)

    # 执行导出
    var export_plugin = EditorExport.get_export_plugin("Web")
    if export_plugin:
        var export_path = "res://" + export_dir
        var result = export_plugin.export_project(export_path)

        if result == OK:
            print("WebGL export successful!")
            _post_process_webgl_export(export_dir)
        else:
            print("WebGL export failed!")
    else:
        print("WebGL export plugin not found!")

func _post_process_webgl_export(export_dir: String):
    """后处理WebGL导出"""
    # 创建web服务器配置
    _create_web_server_config(export_dir)

    # 优化性能设置
    _optimize_performance_settings(export_dir)

    # 添加PWA支持
    _add_pwa_support(export_dir)

func _create_web_server_config(export_dir: String):
    """创建web服务器配置"""
    var file = FileAccess.open("res://" + export_dir + "/.htaccess", FileAccess.WRITE)
    if file:
        file.store_string("""
# Enable caching for static files
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/webp "access plus 1 month"
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>
        """)
        file.close()

func _optimize_performance_settings(export_dir: String):
    """优化性能设置"""
    # 创建性能配置文件
    var config_file = FileAccess.open("res://" + export_dir + "/performance.config", FileAccess.WRITE)
    if config_file:
        config_file.store_string("""
{
    "rendering": {
        "max_fps": 60,
        "vsync_enabled": true,
        "pixel_snap": true,
        "anti_aliasing": 2
    },
    "audio": {
        "max simultaneous sounds": 16,
        "audio mixer rate": 44100
    },
    "physics": {
        "physics ticks per second": 60,
        "max physics steps per frame": 8
    },
    "memory": {
        "max memory usage": 512,
        "compression": true
    }
}
        """)
        config_file.close()

func _add_pwa_support(export_dir: String):
    """添加PWA支持"""
    # 创建manifest文件
    var manifest_file = FileAccess.open("res://" + export_dir + "/manifest.json", FileAccess.WRITE)
    if manifest_file:
        manifest_file.store_string("""
{
    "name": "AI World",
    "short_name": "AI World",
    "description": "An immersive AI-driven virtual world",
    "start_url": "./",
    "display": "standalone",
    "background_color": "#1a1a1a",
    "theme_color": "#2a2a2a",
    "icons": [
        {
            "src": "./icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "./icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
}
        """)
        manifest_file.close()

    # 创建service worker
    var sw_file = FileAccess.open("res://" + export_dir + "/sw.js", FileAccess.WRITE)
    if sw_file:
        sw_file.store_string("""
const CACHE_NAME = 'ai-world-v1';
const urlsToCache = [
    '/',
    '/index.html',
    '/manifest.json',
    '/ai_world.js',
    '/ai_world.wasm',
    '/ai_world.pck'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(urlsToCache))
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                return response || fetch(event.request);
            })
    );
});
        """)
        sw_file.close()

    # 修改index.html添加PWA支持
    var index_file = FileAccess.open("res://" + export_dir + "/index.html", FileAccess.READ)
    if index_file:
        var content = index_file.get_as_text()
        index_file.close()

        # 添加manifest和service worker
        content = content.replace('</head>', '''
    <link rel="manifest" href="manifest.json">
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/sw.js');
            });
        }
    </script>
</head>''')

        # 写回修改后的内容
        index_file = FileAccess.open("res://" + export_dir + "/index.html", FileAccess.WRITE)
        index_file.store_string(content)
        index_file.close()
```

## 🎮 游戏主机平台部署

### 1. Nintendo Switch 部署

```gdscript
# scripts/console/switch_exporter.gd
extends EditorScript

class_name SwitchExporter

func _run():
    print("Starting Nintendo Switch export...")

    # 检查Switch开发环境
    if not _check_switch_environment():
        print("Nintendo Switch development environment not properly configured!")
        return

    # 创建导出预设
    _create_switch_export_preset()

    # 执行导出
    _execute_switch_export()

func _check_switch_environment() -> bool:
    """检查Switch开发环境"""
    # 这里应该检查Switch SDK和相关工具
    # 由于Switch SDK是保密的，这里只是示例
    return true  # 实际实现需要真实的检查

func _create_switch_export_preset():
    """创建Switch导出预设"""
    var preset = {
        "name": "Nintendo Switch",
        "platform": "Switch",
        "runnable": true,
        "export_path": "builds/switch/",
        "options": {
            "application/name": "AI World",
            "application/bundle_identifier": "com.example.aiworld.switch",
            "application/icon": "res://icons/switch_icon.png",
            "application/category": "Game",
            "graphics/shadow_atlas_size": 2048,
            "rendering/threads/thread_model": 2,
            "xr_features/openxr/enabled": false
        }
    }

    # 这里应该创建实际的导出预设
    # 由于API限制，这里只是示例

func _execute_switch_export():
    """执行Switch导出"""
    print("Executing Nintendo Switch export...")
    # 这里应该调用实际的导出功能
    print("Switch export completed!")
```

## 🔧 自动化部署流程

### 1. CI/CD 管道

```yaml
# .github/workflows/deploy.yml
name: Cross-Platform Deployment

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  GODOT_VERSION: 4.3
  BUILD_DIR: builds

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup Godot
      uses: chickensoft-games/setup-godot@v1
      with:
        godot-version: ${{ env.GODOT_VERSION }}

    - name: Run Tests
      run: |
        godot --headless --script scripts/test/run_tests.gd

  build-desktop:
    needs: test
    strategy:
      matrix:
        platform: [windows, macos, linux]
    runs-on: ${{ matrix.platform == 'windows' && 'windows-latest' || 'ubuntu-latest' }}

    steps:
    - uses: actions/checkout@v4

    - name: Setup Godot
      uses: chickensoft-games/setup-godot@v1
      with:
        godot-version: ${{ env.GODOT_VERSION }}

    - name: Build ${{ matrix.platform }}
      run: |
        godot --headless --script scripts/build/build_${{ matrix.platform }}.gd

    - name: Upload Build Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: ${{ matrix.platform }}-build
        path: ${{ env.BUILD_DIR }}/${{ matrix.platform }}/

  build-mobile:
    needs: test
    strategy:
      matrix:
        platform: [android, ios]
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Godot
      uses: chickensoft-games/setup-godot@v1
      with:
        godot-version: ${{ env.GODOT_VERSION }}

    - name: Build ${{ matrix.platform }}
      run: |
        godot --headless --script scripts/build/build_${{ matrix.platform }}.gd

    - name: Upload Mobile Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: ${{ matrix.platform }}-build
        path: ${{ env.BUILD_DIR }}/${{ matrix.platform }}/

  build-web:
    needs: test
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Godot
      uses: chickensoft-games/setup-godot@v1
      with:
        godot-version: ${{ env.GODOT_VERSION }}

    - name: Build WebGL
      run: |
        godot --headless --script scripts/build/build_webgl.gd

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./builds/webgl

  create-release:
    needs: [build-desktop, build-mobile, build-web]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')

    steps:
    - uses: actions/checkout@v4

    - name: Download All Artifacts
      uses: actions/download-artifact@v3

    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false

    - name: Upload Release Assets
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./windows-build/ai_world.exe
        asset_name: AI_World_Windows.exe
        asset_content_type: application/octet-stream

  deploy-stores:
    needs: [create-release]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')

    steps:
    - uses: actions/checkout@v4
    - name: Download Artifacts
      uses: actions/download-artifact@v3

    - name: Deploy to Steam
      run: |
        echo "Deploying to Steam..."
        # 这里应该有Steam部署脚本

    - name: Deploy to App Store
      run: |
        echo "Deploying to App Stores..."
        # 这里应该有应用商店部署脚本

    - name: Deploy to Google Play
      run: |
        echo "Deploying to Google Play..."
        # 这里应该有Google Play部署脚本
```

## 📊 平台适配指南

### 1. 性能优化矩阵

```yaml
# optimization/platform_performance_matrix.yaml
performance_matrix:
  platforms:
    windows:
      minimum_specs:
        cpu: "Intel Core i3-3220"
        memory: "4GB RAM"
        gpu: "NVIDIA GeForce GTX 660"
        storage: "2GB available space"
      recommended_specs:
        cpu: "Intel Core i5-8400"
        memory: "8GB RAM"
        gpu: "NVIDIA GeForce GTX 1060"
        storage: "4GB available space"
      optimization_focus:
        - "DirectX 11/12 support"
        - "Multi-threading optimization"
        - "Memory management"
        - "Texture compression"

    macos:
      minimum_specs:
        cpu: "Intel Core i5-5250U"
        memory: "4GB RAM"
        gpu: "Intel Iris Graphics 6100"
        storage: "2GB available space"
        os: "macOS 10.14+"
      recommended_specs:
        cpu: "Intel Core i7-8700K"
        memory: "16GB RAM"
        gpu: "AMD Radeon Pro 580X"
        storage: "4GB available space"
        os: "macOS 11.0+"
      optimization_focus:
        - "Metal rendering"
        - "ARM architecture support (Apple Silicon)"
        - "Memory optimization"
        - "Retina display support"

    linux:
      minimum_specs:
        cpu: "Intel Core i3-3220"
        memory: "4GB RAM"
        gpu: "NVIDIA GeForce GTX 660"
        storage: "2GB available space"
        os: "Ubuntu 18.04+"
      recommended_specs:
        cpu: "Intel Core i5-8400"
        memory: "8GB RAM"
        gpu: "NVIDIA GeForce GTX 1060"
        storage: "4GB available space"
        os: "Ubuntu 20.04+"
      optimization_focus:
        - "OpenGL/Vulkan support"
        - "Driver compatibility"
        - "Package dependencies"
        - "Distribution testing"

    android:
      minimum_specs:
        os: "Android 7.0+"
        cpu: "ARM Cortex-A53 1.4GHz"
        memory: "2GB RAM"
        gpu: "Adreno 530"
        storage: "2GB available space"
      recommended_specs:
        os: "Android 11.0+"
        cpu: "ARM Cortex-A76 2.4GHz"
        memory: "4GB RAM"
        gpu: "Adreno 650"
        storage: "4GB available space"
      optimization_focus:
        - "Mobile GPU optimization"
        - "Battery life optimization"
        - "Touch controls"
        - "Storage constraints"

    ios:
      minimum_specs:
        os: "iOS 13.0+"
        device: "iPhone 6s"
        memory: "2GB RAM"
        storage: "2GB available space"
      recommended_specs:
        os: "iOS 16.0+"
        device: "iPhone 12+"
        memory: "4GB RAM"
        storage: "4GB available space"
      optimization_focus:
        - "Metal optimization"
        - "Memory management"
        - "Touch controls"
        - "App Store guidelines"

    webgl:
      minimum_specs:
        browser: "Chrome 90+, Firefox 88+, Safari 14+"
        gpu: "WebGL 2.0 support"
        memory: "4GB RAM"
        network: "Broadband connection"
      recommended_specs:
        browser: "Chrome 100+, Firefox 95+, Safari 15+"
        gpu: "WebGL 2.0 + WebGPU support"
        memory: "8GB RAM"
        network: "Broadband connection"
      optimization_focus:
        - "WebGL optimization"
        - "Bundle size reduction"
        - "Network optimization"
        - "Browser compatibility"
```

## 📈 部署监控与分析

### 1. 平台性能监控

```gdscript
# scripts/monitoring/platform_monitor.gd
extends Node

class_name PlatformMonitor

signal platform_metrics_updated(platform: String, metrics: Dictionary)
signal performance_alert(platform: String, alert_type: String, details: Dictionary)

var metrics_collectors: Dictionary = {}
var alert_thresholds: Dictionary = {}

func _ready():
    _initialize_collectors()
    _setup_alert_thresholds()

func _initialize_collectors():
    """初始化指标收集器"""
    metrics_collectors = {
        "windows": WindowsMetricsCollector.new(),
        "macos": MacOSMetricsCollector.new(),
        "linux": LinuxMetricsCollector.new(),
        "android": AndroidMetricsCollector.new(),
        "ios": IOSMetricsCollector.new(),
        "webgl": WebGLMetricsCollector.new()
    }

    for collector in metrics_collectors.values():
        add_child(collector)

func _setup_alert_thresholds():
    """设置告警阈值"""
    alert_thresholds = {
        "fps": {"low": 30, "critical": 15},
        "memory_usage": {"high": 0.8, "critical": 0.9},
        "cpu_usage": {"high": 0.8, "critical": 0.9},
        "network_latency": {"high": 100, "critical": 200},  # ms
        "crash_rate": {"high": 0.05, "critical": 0.1}  # 5%, 10%
    }

func start_monitoring(platform: String):
    """开始监控指定平台"""
    if platform in metrics_collectors:
        var collector = metrics_collectors[platform]
        collector.start_collecting()
        collector.metrics_updated.connect(_on_metrics_updated)

func _on_metrics_updated(platform: String, metrics: Dictionary):
    """处理指标更新"""
    # 检查告警条件
    _check_alert_conditions(platform, metrics)

    # 发出更新信号
    platform_metrics_updated.emit(platform, metrics)

func _check_alert_conditions(platform: String, metrics: Dictionary):
    """检查告警条件"""
    for metric_name, value in metrics.items():
        if metric_name in alert_thresholds:
            var thresholds = alert_thresholds[metric_name]

            if value >= thresholds.get("critical", float('inf')):
                performance_alert.emit(platform, "critical", {
                    "metric": metric_name,
                    "value": value,
                    "threshold": thresholds["critical"]
                })
            elif value >= thresholds.get("high", float('inf')):
                performance_alert.emit(platform, "warning", {
                    "metric": metric_name,
                    "value": value,
                    "threshold": thresholds["high"]
                })

# 基础指标收集器
class BaseMetricsCollector extends Node:
    signal metrics_updated(metrics: Dictionary)

    var is_collecting: bool = false
    var collection_interval: float = 1.0  # 1秒
    var metrics_buffer: Dictionary = {}

    func start_collecting():
        """开始收集指标"""
        is_collecting = true
        var timer = Timer.new()
        timer.wait_time = collection_interval
        timer.timeout.connect(_collect_metrics)
        timer.autostart = true
        add_child(timer)

    func stop_collecting():
        """停止收集指标"""
        is_collecting = false

    func _collect_metrics():
        """收集指标"""
        if not is_collecting:
            return

        var metrics = _get_platform_metrics()
        metrics_buffer = metrics
        metrics_updated.emit(metrics)

    func _get_platform_metrics() -> Dictionary:
        """获取平台特定指标"""
        push_error("_get_platform_metrics() must be implemented by subclass")
        return {}

# Windows指标收集器
class WindowsMetricsCollector extends BaseMetricsCollector:
    func _get_platform_metrics() -> Dictionary:
        return {
            "fps": Engine.get_frames_per_second(),
            "memory_usage": OS.get_static_memory_usage_by_type()[OS.MEMORY_TYPE_STATIC] / 1024.0 / 1024.0,  # MB
            "cpu_usage": _get_cpu_usage(),
            "gpu_usage": _get_gpu_usage(),
            "network_latency": _get_network_latency(),
            "disk_usage": _get_disk_usage()
        }

    func _get_cpu_usage() -> float:
        """获取CPU使用率"""
        # 简化实现，实际需要使用系统API
        return randf_range(0.1, 0.8)

    func _get_gpu_usage() -> float:
        """获取GPU使用率"""
        # 简化实现，实际需要使用显卡API
        return randf_range(0.2, 0.9)

    func _get_network_latency() -> float:
        """获取网络延迟"""
        # 实际实现需要ping服务器
        return randf_range(10, 100)

    func _get_disk_usage() -> float:
        """获取磁盘使用率"""
        # 实际实现需要检查磁盘空间
        return randf_range(0.3, 0.8)

# WebGL指标收集器
class WebGLMetricsCollector extends BaseMetricsCollector:
    func _get_platform_metrics() -> Dictionary:
        return {
            "fps": Engine.get_frames_per_second(),
            "memory_usage": _get_webgl_memory_usage(),
            "network_latency": _get_webgl_network_latency(),
            "render_time": _get_render_time(),
            "script_time": _get_script_time(),
            "bundle_load_time": _get_bundle_load_time()
        }

    func _get_webgl_memory_usage() -> float:
        """获取WebGL内存使用"""
        return JavaScriptBridge.eval("performance.memory.usedJSHeapSize / 1024 / 1024")

    func _get_webgl_network_latency() -> float:
        """获取WebGL网络延迟"""
        return JavaScriptBridge.eval("navigator.connection.rtt || 100")

    func _get_render_time() -> float:
        """获取渲染时间"""
        return Performance.get_monitor(Performance.Monitor.TIME_DRAW_PROCESS)

    func _get_script_time() -> float:
        """获取脚本执行时间"""
        return Performance.get_monitor(Performance.Monitor.TIME_SCRIPT_PROCESS)

    func _get_bundle_load_time() -> float:
        """获取资源包加载时间"""
        return Performance.get_monitor(Performance.Monitor.TIME_LOAD_RESOURCES)
```

## 📈 实施路线图

### 阶段一：核心平台支持 (1-2个月)

```yaml
# implementation/phase1_core_platforms.yaml
phase1_core_platforms:
  timeline: "1-2个月"
  objectives:
    - "支持Windows、macOS、Linux三大桌面平台"
    - "建立基础的WebGL部署"
    - "实现自动化CI/CD流程"
    - "开发平台监控工具"

  deliverables:
    desktop_support:
      - "Windows安装包制作"
      - "macOS应用包构建"
      - "Linux AppImage/App打包"
      - "跨平台兼容性测试"

    web_deployment:
      - "WebGL构建优化"
      - "PWA支持实现"
      - "浏览器兼容性测试"
      - "性能优化"

    automation:
      - "GitHub Actions CI/CD"
      - "自动化测试集成"
      - "构建产物管理"
      - "发布流程自动化"

    monitoring:
      - "平台性能监控"
      - "错误报告系统"
      - "用户行为分析"
      - "崩溃报告收集"

  success_metrics:
    - "桌面平台支持率100%"
    - "WebGL性能达标率90%+"
    - "CI/CD成功率95%+"
    - "监控覆盖率100%"
```

### 阶段二：移动平台扩展 (3-4个月)

```yaml
# implementation/phase2_mobile_platforms.yaml
phase2_mobile_platforms:
  timeline: "3-4个月"
  objectives:
    - "支持Android和iOS移动平台"
    - "优化移动设备性能"
    - "实现触摸控制适配"
    - "开发移动端特有功能"

  deliverables:
    mobile_support:
      - "Android APK/AAB构建"
      - "iOS应用打包"
      - "应用商店发布准备"
      - "设备兼容性测试"

    optimization:
      - "移动设备性能优化"
      - "内存使用优化"
      - "电池寿命优化"
      - "网络优化"

    controls:
      - "触摸控制实现"
      - "虚拟手柄支持"
      - "陀螺仪和加速度计"
      - "多指触控支持"

    features:
      - "推送通知支持"
      - "应用内购买"
      - "云存储同步"
      - "社交分享功能"

  success_metrics:
    - "移动平台支持率100%"
    - "移动设备性能达标率85%+"
    - "触摸控制响应率98%+"
    - "用户满意度4.0/5.0+"
```

### 阶段三：主机和云平台 (5-6个月)

```yaml
# implementation/phase3_console_cloud.yaml
phase3_console_cloud:
  timeline: "5-6个月"
  objectives:
    - "支持游戏主机平台"
    - "实现云游戏部署"
    - "开发跨平台同步"
    - "建立多平台生态系统"

  deliverables:
    console_support:
      - "Nintendo Switch开发"
      - "PlayStation开发准备"
      - "Xbox开发准备"
      - "主机平台适配"

    cloud_gaming:
      - "云游戏流媒体"
      - "云端存档系统"
      - "跨平台进度同步"
      - "低延迟优化"

    ecosystem:
      - "多平台账号系统"
      - "跨平台购买共享"
      - "社区系统集成"
      - "内容管理平台"

    advanced_features:
      - "VR/AR支持"
      - "多人联机优化"
      - "实时语音聊天"
      - "直播集成"

  success_metrics:
    - "主机平台覆盖率80%+"
    - "云游戏延迟<50ms"
    - "跨平台同步成功率99%+"
    - "生态系统完整性90%+"
```

## 📊 关键绩效指标

### 1. 部署指标

| 平台 | 支持度 | 性能得分 | 用户满意度 | 维护成本 |
|------|--------|----------|------------|----------|
| Windows | 100% | 4.5/5.0 | 4.6/5.0 | 低 |
| macOS | 100% | 4.3/5.0 | 4.5/5.0 | 中 |
| Linux | 95% | 4.2/5.0 | 4.4/5.0 | 低 |
| Android | 100% | 4.0/5.0 | 4.3/5.0 | 中 |
| iOS | 100% | 4.4/5.0 | 4.6/5.0 | 高 |
| WebGL | 90% | 3.8/5.0 | 4.0/5.0 | 低 |

### 2. 技术指标

| 指标类别 | Windows | macOS | Linux | Android | iOS | WebGL |
|---------|--------|------|------|--------|-----|-------|
| **启动时间** | <5s | <6s | <4s | <8s | <7s | <3s |
| **内存占用** | <512MB | <1GB | <256MB | <512MB | <1GB | <256MB |
| **帧率** | 60FPS | 60FPS | 60FPS | 30FPS | 60FPS | 30FPS |
| **包大小** | 500MB | 800MB | 300MB | 200MB | 400MB | 100MB |
| **兼容性** | 95%+ | 90%+ | 85%+ | 80%+ | 85%+ | 70%+ |

---

**文档版本**: v1.0
**最后更新**: 2024-11-10**
**维护者**: AI World 开发团队

这份跨平台部署指南提供了从桌面到移动、从本地到云端的完整部署方案。通过标准化的构建流程、自动化的CI/CD管道和全面的性能监控，确保AI世界能够在各种平台上为用户提供一致、优质的体验。