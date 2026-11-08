# USB 配网、HA 配对和 OTA 更新（默认方案）

项目默认采用 **Improv Serial over ESP32-S3 USB Serial/JTAG**，不再预编译 Wi-Fi SSID / 密码，也不提供无密码热点。Hey Jarvis 在设备端运行。

## 凭据分工

| 内容 | 从哪里输入 | 保存位置 |
| --- | --- | --- |
| 家庭 Wi-Fi SSID/密码 | 第一次烧录后，用电脑 USB Improv 客户端输入 | ESP32 持久 Wi-Fi 存储 |
| ESPHome Native API 32 字节 Base64 密钥 | 首次编译前，在本机 `secrets.yaml` 生成 | ESP32 固件 + 本机私有配置，HA 配对时输入相同密钥 |
| OTA 更新 | 自动复用上述 API 密钥（`ota.encryption`） | 不需要独立 OTA 密码 |
| HA Long-Lived Access Token | **不需要** | 不写入设备或仓库 |

**重要：USB Improv 只负责 Wi-Fi 配网，不替代 API 加密密钥的安全初始化。** ESPHome API 可支持运行时设定 key，但 Home Assistant 自动提供该 key 的完整体验仍应以实际版本核实；目前默认走明确、可重复的编译时 key 路线。

## 一、第一次通过 USB 安装

在 macOS 电脑（或者能直连 ESP32 USB 的设备）执行：

```sh
git clone https://github.com/chen9751/ESP32-RLCD4.2.git
cd ESP32-RLCD4.2
cp secrets.example.yaml secrets.yaml
python3 -c 'import base64,secrets; print(base64.b64encode(secrets.token_bytes(32)).decode())'
```

把命令输出的随机 Base64 字符串**只**填入本地 `secrets.yaml` 的 `api_encryption_key`。不要把密钥粘进 GitHub、Issue、聊天或截图。USB 配网**不要求**在这里填写 Wi-Fi。

安装 ESPHome 2026.10.2 或兼容版本：

```sh
python3 -m pip install esphome==2026.10.2
esphome config esp32-rlcd42.yaml
esphome compile esp32-rlcd42.yaml
esphome run esp32-rlcd42.yaml
```

首次安装时，选择 USB 串口端口，不要选 OTA。ESP32-S3 使用 ESP-IDF 和原生 USB Serial/JTAG；需使用**数据线**，不是仅供电线。macOS 中通过 `ls /dev/cu.usbmodem*` 查看串口，具体名字每台机器不同。若安装模式进不去，按微雪说明使用 BOOT/RESET 组合进入下载模式。

## 二、用 USB 输入 Wi-Fi

烧录成功后，保持 USB 连接，退出占用串口的 `esphome logs`（一个串口同一时间通常只有一个客户端可以读取）。

使用兼容 Improv Serial 的客户端（例如带此能力的 ESP Web Tools 配网页面）：

1. 选择实际出现的 ESP32 USB Serial/JTAG 端口。
2. 连接设备并选择你的 **2.4 GHz Wi-Fi** SSID、输入 Wi-Fi 密码。
3. 等待设备报告连接成功及 IP 地址；USB 本身不负责给 ESP32 提供网络。
4. 把设备 IP / mDNS 名称记下来，供 HA 首次添加设备。

**兼容性注意：** 浏览器 Web Serial 需要相应浏览器及安全来源支持；macOS 可尝试 Chrome 或 Edge。Safari、iOS 浏览器未必能通过 Web Serial 完成。应选明确支持 **Improv Serial** 的网页/工具，而不是普通的 ESPHome 固件下载页面。不要将真实密码输入来源不明的网页；USB Improv 使用串口明文发送凭据，只在可信电脑和连接环境中使用。

## 三、连接 Home Assistant

在 HA → 设置 → 设备与服务 → 添加集成 → **ESPHome** 中，选择自动发现或填 IP。按提示输入本机 `secrets.yaml` 中的同一个 `api_encryption_key`。Native API 默认使用 TCP 6053。此过程无需 HA Long-Lived Access Token。HA 里配置包含有效中文 STT 和 conversation agent 的 Assist pipeline；是否启用 TTS 由产品需要决定。

## 四、之后如何修改 Wi-Fi / 固件

- **改 Wi-Fi**：USB 接入后使用 Improv Serial 客户端重新设置。也可以通过先接回原网络、再用 ESPHome Wi-Fi 配置操作；本项目推荐 USB 方法。
- **更新固件**：在已联网且 API 密钥一致时运行 `esphome run esp32-rlcd42.yaml`，选择网络设备，使用加密 OTA。
- **注意不要轻易变更 API key**。若改变了本地密钥却未同步设备、HA 集成和 OTA，可能造成无法远程更新，只能 USB 恢复。务必备份私有 `secrets.yaml` 至安全位置。
- **全量擦除 Flash / NVS** 会丢失设备里运行时保存的 Wi-Fi 配置信息；需再次 USB 配网。普通 OTA 通常保留 NVS 内容。
- **无 Wi-Fi 的状态**：本项目 `wifi.reboot_timeout: 0s`，等待 USB 输入凭据，不因无法连接 Wi-Fi 而反复重启。屏幕和传感器仍能尝试运行（HA 时间和 Assist 需联网）。

## 五、故障回退

1. USB 端口不存在：检查数据线、供电和原生 USB 接口；按说明重新进入 ROM 下载模式。
2. 设备刷入成功但 Improv 找不到：检查 `logger.hardware_uart: USB_SERIAL_JTAG`、USB 端口是否被日志工具占用；用串口日志排查。
3. 无法连接 Wi-Fi：确认是 2.4 GHz、密码与 AP 安全协议兼容，在串口日志确认失败原因。
4. Wi-Fi 已连接但 HA 发现不到：检查两端 IP、VLAN、防火墙 TCP 6053；手动添加 ESPHome IP。
5. HA 密钥错误：使用**编译此设备固件时**的相同 API key；不要生成一个新 key 直接覆盖现有配置。
6. OTA 不通：USB 串口烧录新固件恢复，不应为了方便而在正式固件中开启未认证 OTA。

## 为什么不直接启用 HA 运行时设置 key？

这是一项 ESPHome 正在支持的较新机制。文档已说明 API `encryption` 在未预置 `key` 时可以运行时配置，但 Home Assistant 端的自动密钥初始化能力/固件采纳流程应经过实际版本测试，不能默认已全面可用。因此这个个人项目首先选择固定于**本地私有文件**中的设备专属 key：少一套未知的配对流程，安全可控，且有 USB 恢复手段。

参考文档：
- https://esphome.io/components/improv_serial/
- https://esphome.io/components/wifi/
- https://esphome.io/components/logger/
- https://esphome.io/components/api/
- https://esphome.io/components/ota/esphome/
- https://esphome.io/components/provisioning/
