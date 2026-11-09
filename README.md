# ESP32-RLCD4.2

面向微雪 **ESP32-S3-RLCD-4.2**（400×300 ST7305 反射式单色屏）的 ESPHome / Home Assistant Assist 项目。

> 状态：**初始开发框架**。已按微雪文档整理配置，但在真机上烧录和测试前，不应视为生产固件。

## 设计目标

- ESPHome 原生 Wi-Fi / 加密 API / OTA，连接 Home Assistant。
- ST7305 反射式屏显示时间、温湿度、电池电压与语音状态。
- SHTC3、GPIO4 电池电压、KEY / BOOT 按键。
- ES7210 双麦克风阵列的 I²S 输入，Hey Jarvis 唤醒或者 KEY 按键启动一次 Assist 语音输入。
- 默认运行 microWakeWord 的 **Hey Jarvis** 英文唤醒模型；ES8311 扬声器为可选功能，默认不播放语音。
- Home Assistant 负责 STT、意图识别、设备控制。**设备端不运行 Whisper**。

## 配置入口

`esp32-rlcd42.yaml` 为默认入口：

| 路径 | 作用 |
| --- | --- |
| `packages/core.yaml` | ESP32-S3 / PSRAM / Wi-Fi / API / OTA |
| `packages/buses.yaml` | I²C / SPI 硬件总线 |
| `packages/display.yaml` | ST7305 驱动、单色状态页、字体 |
| `packages/sensors.yaml` | 温湿度、电池电压、HA 时间 |
| `packages/buttons.yaml` | KEY 一键发起 Assist，BOOT 按键状态 |
| `packages/voice_ptt.yaml` | ES7210 麦克风与 Assist 按键模式 |
| `packages/speaker_optional.yaml` | 可选 ES8311 扬声器（默认不加载） |
| `packages/wake_word_optional.yaml` | Hey Jarvis 本地唤醒模型（默认加载） |
| `docs/HARDWARE.md` | 硬件映射、限制与资料来源 |
| `docs/VOICE.md` | HA Assist 接入、唤醒词选项、待验证事项 |

默认配置是 **Hey Jarvis 本地待机唤醒 + KEY 按键备用触发**，Assist 语音录入使用静音检测自动结束，不默认合成语音。

## macOS 本地首次编译（**不烧录**）

在 Mac 的终端执行：

```sh
mkdir -p ~/Documents/Codex
cd ~/Documents/Codex
git clone https://github.com/chen9751/ESP32-RLCD4.2.git
cd ESP32-RLCD4.2
bash scripts/compile-macos.sh
```

脚本要求 **Python 3.12+**（如缺失：`brew install python@3.12`）；将自动建立 `.venv`、安装固定的 ESPHome 2026.10.2、生成本地私有 `secrets.yaml`（仅第一次）、执行 `esphome config` 与 `esphome compile`。**不会执行烧录**，不会请求 Wi-Fi 密码。

如果目录已经克隆过：`cd ~/Documents/Codex/ESP32-RLCD4.2 && git pull --ff-only && bash scripts/compile-macos.sh`。

请保存本机 `secrets.yaml` 的安全备份；这把 API key 是以后 HA 配对和加密 OTA 的必要信息，不能将它提交到 GitHub。出现编译错误时，记录终端从 `ERROR` 开始的相关输出，分享前检查是否包含私密内容。

## 快速开始：USB 配网

**不在 YAML/固件中填写 Wi-Fi SSID 与密码。** 首次 USB 烧录后，由 ESPHome `improv_serial` 通过 ESP32-S3 原生 USB Serial/JTAG 接收 Wi-Fi 配置；不启用 BLE 配网、开放热点和 Captive Portal。

1. 安装 ESPHome 2026.10.2（或兼容版本），复制 `secrets.example.yaml` → `secrets.yaml`。
2. 在本机生成设备专属的 32 字节 Base64 API key，把它填写到 **Git 忽略的** `secrets.yaml`；不要提交 GitHub。
3. 执行 `esphome config esp32-rlcd42.yaml`，再 `esphome compile esp32-rlcd42.yaml`。
4. 首次 USB 烧录：`esphome run esp32-rlcd42.yaml`，选择实际的串口端口。
5. 保持 USB 连接、关闭占用端口的日志程序，使用兼容 Improv Serial 的客户端输入 **2.4GHz Wi-Fi** SSID/密码。
6. Wi-Fi 联通后，在 HA 中添加 ESPHome 集成，输入设备 IP 及上述相同的 API key。为 Assist 配置有效的中文 STT 与对话代理。
7. 此后可以通过**加密 OTA** 上传更新；不需要独立 OTA 密码。唤醒词是 **Hey Jarvis**，KEY(GPIO18) 作为手动备用入口。

完整配置和故障恢复见 [USB 配网及 HA 配对](docs/PROVISIONING.md)。ST7305 驱动来自社区；配置校验、固件编译和真机运行结果仍待核验。

### 可选功能

如需扬声器，在主入口的 `packages:` 下添加：

```yaml
  speaker: !include packages/speaker_optional.yaml
```

这仅启用扬声器输出链路；是否采用 TTS / media_player、音频反馈的具体交互仍需真机验证。本地唤醒词已经选为 `hey_jarvis`，默认编译启用。若要替换模型，修改主配置中的 `wake_word_model`；见 `docs/VOICE.md`。建议先在真机完成微麦克风和待机内存测试。

## 现实限制

- ST7305 不是触摸屏，不是彩色 SPI/TFT，不支持背光调光。
- LCD 字体为轻量 ASCII，中文转写存入 HA 的文本实体，但暂不直接绘制中文；后续可添加中文字体及裁剪字库。
- 电池电压采用 GPIO4 ×3，还未使用百分比预测：锂电池百分比不是简单线性电压映射。
- PCF85063 RTC、TF 卡、深度睡眠、声学回声消除尚未集成。
- 当前仓库配置基于微雪资料和 ESPHome 文档；尚无真机编译、麦克风音质、功放开关、屏幕刷新性能验证结果。
- 项目不含 API 密钥、Wi-Fi 密码、固件镜像或第三方模型二进制。

## 参考

- 微雪设备资料：https://docs.waveshare.com/ESP32-S3-RLCD-4.2
- 微雪 ESPHome 教程：https://docs.waveshare.com/ESP32-ESPHome-Tutorials/Example-RLCD-Voice
- ESPHome 设备目录：https://devices.esphome.io/devices/waveshare-esp32-s3-rlcd-42/
- ST7305 外部组件：https://github.com/kylehase/ESPHome-ST7305-RLCD
- ESPHome Voice Assistant：https://esphome.io/components/voice_assistant/
- ESPHome microWakeWord：https://esphome.io/components/micro_wake_word/

## 凭据与首次配网

请阅读 [USB 配网及 HA 配对](docs/PROVISIONING.md)。USB Improv 输入 Wi-Fi，`secrets.yaml` 仅存本地专属 API key，OTA 复用相同 key 加密；不向 GitHub 提交真实密钥。
