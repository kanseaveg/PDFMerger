# PDF 合并工具

一款轻量级 macOS 原生 PDF 合并工具，使用 Swift + SwiftUI 开发，零第三方依赖。

## 功能

- 拖拽添加 PDF / PNG / JPEG 文件
- 拖拽调整文件合并顺序
- 图片自动转为 PDF 页面
- 一键合并导出为 PDF
- 原生 macOS 界面，流畅轻快

## 安装

### 方式一：下载预编译版本（推荐）

1. 前往 [Releases](../../releases) 页面，下载最新版 `PDF合并工具.app.zip`
2. 解压 zip 文件
3. **首次打开前**，在终端执行以下命令移除 macOS 隔离属性：
   ```bash
   xattr -cr ~/Downloads/PDF合并工具.app
   ```
4. 双击打开 `PDF合并工具.app`

> **为什么需要 xattr？** 从网络下载的未签名应用会被 macOS Gatekeeper 拦截。`xattr -cr` 命令移除隔离标记后即可正常使用。该应用不含任何恶意代码，你也可以选择从源码自行编译。

### 方式二：从源码编译

确保你的 Mac 已安装 Xcode Command Line Tools：

```bash
xcode-select --install  # 如果尚未安装
```

然后：

```bash
git clone https://github.com/kanseaveg/PDFMerger.git
cd PDFMerger
bash build.sh
open PDF合并工具.app
```

从源码编译的应用不会被 Gatekeeper 拦截。

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3/M4)

## 使用方法

1. 打开应用，将 PDF、PNG 或 JPEG 文件拖入窗口，或点击「添加文件」按钮
2. 拖拽列表中的文件行调整合并顺序
3. 点击「合并 PDF」按钮，选择保存位置
4. 完成！

## 许可证

MIT License
