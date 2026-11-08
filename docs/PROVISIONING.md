# Wi-Fi、Home Assistant 与 OTA 凭据配置

> 项目默认选择 **Hey Jarvis 本地唤醒**。GitHub 中只有公开配置模板，不包含真实密码、API key、HA token。

## 先厘清三个凭据

| 凭据 | 谁使用 | 当前配置 | 是否写到 GitHub |
| --- | --- | --- | --- |
| Wi-Fi SSID / 密码 | ESP32 连接 2.4 GHz WLAN | `wifi.ssid/password` | **否** |
| ESPHome Native API 加密密钥 | ESP32 与 Home Assistant 的 ESPHome 集成 | `api.encryption.key` | **否** |
| OTA 密码 | ESPHome 为设备部署固件 | `ota.esphome.password` | **否** |
| HA Long-Lived Access Token | 仅 HA REST API 等其他开发模式 | 本项目 **不需要** | **绝不添加** |

ESPHome Native API 是 ESP32 的服务，由 HA 连接设备（默认 TCP 6053）。加密 key 是双方共享的 32 字节 Base64 密钥；不是 HA 的令牌。HA 添加设备时，输入这个密钥或者由 ESPHome Device Builder 自动传递。

## 方案 A：在 ESPHome Device Builder / 本地 CLI 中存入 secrets.yaml（推荐）

首次 USB 烧录最稳定；设备只保存所需的联网凭据，密钥不出现在仓库里。

1. 克隆本仓库；复制 `secrets.example.yaml` 为同目录下的 `secrets.yaml`。
2. 填写 2.4 GHz Wi-Fi SSID 和密码（设备不能直接使用只有 5 GHz 的 SSID）。
3. 生成 32 字节随机 Base64 API key：`python3 -c 'import base64,secrets; print(base64.b64encode(secrets.token_bytes(32)).decode())'`。
4. 自己设置强 OTA 密码（首版使用密码认证）和备用热点密码（至少 8 字符）。
5. 先 `esphome config esp32-rlcd42.yaml`，再 `esphome compile esp32-rlcd42.yaml`。
6. 首次通过 USB 执行 `esphome run esp32-rlcd42.yaml`。以后可经 Wi-Fi OTA。
7. 在 HA → 设置 → 设备与服务 → 添加集成 → ESPHome，输入设备 IP（或者选择自动发现的设备）；要求加密密钥时使用上述 `api_encryption_key`。
8. 在 HA 中为该设备选择 Assist pipeline（包含可用的 STT、中文 conversation agent）。唤醒词无需在 HA 端再部署一次。

**注意**：如果 ESPHome Device Builder 位于 HA 虚拟机，它的 `secrets.yaml` 文件路径由该 add-on 容器管理；GitHub checkout 的文件不会自动同步过去。应将项目和私有 secrets 放到同一个 ESPHome 配置目录。

## 方案 B：首次烧录通用固件 → USB Improv Serial 配 Wi-Fi

ESPHome 支持 `improv_serial:`（需要 `logger:`），可通过 USB 支持的 Improv 客户端（例如 ESP Web Tools）输入 Wi-Fi，而不是预编译 Wi-Fi 密码。

建议单独维护一份 **provisioning** 固件；其 `wifi` 不能强制依赖 `!secret wifi_ssid/password`。还需要规划 API key 的初始化：当前主配置要求显式 `api_encryption_key`，**USB 配网本身不会自动生成/交换这个 key**。实际交付流程可以在烧录时预置每台设备独有 API key，或后续采用安全的设备配对机制。

优点是现场换路由器便捷。缺点是增加一套首次配置固件或配置变体，对现阶段一台设备的项目没有明显收益。

## 方案 C：设备找不到原 Wi-Fi → 备用 AP + captive portal

当前主配置已包含 `wifi.ap` 和 `captive_portal`。断开原 Wi-Fi 且达到回退条件后，设备可发出 `RLCD42 Recovery` 接入点，在热点的配置页面输入新的 WLAN 凭据。

- 备用 AP **有独立密码**，不要公开分享。
- 这属于网络恢复，不负责换/同步 ESPHome API 加密 key。
- 若 API key 变更，必须让设备固件与 HA 集成重新使用同一个 key。
- 实机要测试热点启动、连接和恢复流程，避免发生预期之外的网络开放。

## 不优先：BLE Improv

ESPHome 2026.10 起使用 `improv_ble` 组件名称。它可以用蓝牙配 Wi-Fi，但 BLE 堆栈占用明显内存；ESPHome 官方特别警告 Voice Assistant + BLE 组合可能不稳定。当前 ESP32-S3 要同时运行 Hey Jarvis、I²S 录音、屏幕和 Wi-Fi，因此不默认加载 BLE。

## OTA 安全后续优化

现在 `ota.esphome.password` 认证上传；ESPHome 2026.9+ 推荐加密 OTA：在 `ota:` 的 esphome 平台配置 `encryption:`，沿用设备的 API 密钥。加密 OTA 不仅认证，还能避免 OTA 传输暴露固件中的 Wi-Fi/API 凭据。**不要同时配置 OTA 密码和 encryption。**

首次烧录前可以直接采用加密 OTA。已有设备从密码制迁移时必须按 ESPHome 官方两阶段升级流程来做，不能直接删除密码就尝试加密更新。本项目当前先保留密码方式，待 config / compile / 真机验证后再决定是否迁移。

参考：
- https://esphome.io/components/api/
- https://esphome.io/components/improv_serial/
- https://esphome.io/components/improv_ble/
- https://esphome.io/components/provisioning/
- https://esphome.io/components/ota/esphome/
- https://esphome.io/guides/security_best_practices/
