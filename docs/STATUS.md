# 开发进度与验收清单（2026-11-10）

此文档按 **源码状态** 和 **实际验证** 分开记录。文件已提交 GitHub ≠ ESPHome 配置可编译 ≠ 实机功能已可用。

## 已在 GitHub 提交的源码

- [x] 主 YAML 与 packages 分层；16MB Flash、Octal 8MB PSRAM、ESP-IDF
- [x] 微雪 GPIO / I²C / SPI、ST7305 社区外部显示组件
- [x] SHTC3 温湿度、ADC 电池电压、时钟 UI、BOOT/KEY
- [x] ES7210 I²S 麦克风与 HA Voice Assistant 事件处理
- [x] Hey Jarvis microWakeWord 默认模型；KEY 按键后停止本地监听并触发 Assist
- [x] USB Improv Serial，默认不编译 Wi-Fi SSID/密码
- [x] 本地设备专属 API key，Native API 加密，OTA 复用此 key 做加密更新
- [x] 机密信息示例、.gitignore、CI YAML 校验工作流
- [x] 初次安装 / HA 配对 / USB 故障恢复文档

## 编译入口

- 本机：`bash scripts/compile-macos.sh`（仅创建本地私密 API key + 配置校验 + 编译，不烧录）
- GitHub Actions：`.github/workflows/validate.yml` 已配置 `config` + `compile` 两步；需要查看实际运行状态才能确认是否通过
- **2026-11-10 00:33:50 +0800**：用户 Mac 本机 ESPHome 2026.10.2 日志报告 `INFO Successfully compiled program.`，`firmware.factory.bin` / `firmware.ota.bin` / `firmware.elf` 已生成；config_hash=`0xe456f572`，固件镜像总量约 1,185,319 B，DIRAM 静态使用 114,991 B。此条为**用户提供的本机日志**，不是独立的真机验证。

## 目前尚未得到的证据

- [x] GitHub Actions 早期版本 `config` 和 `compile` 已运行成功；最新版工作流结果须单独核对
- [x] 用户 Mac 本机 ESPHome 2026.10.2 完整 `compile` 成功（包含 ST7305 外部驱动）；尚未烧录
- [ ] 真机 USB Serial/JTAG 端口正确枚举及 Improv Serial 客户端成功配网
- [ ] 断电重启后 Wi-Fi 账号能自动恢复，USB 可重复更改网络
- [ ] API 加密配对及网络加密 OTA 上传
- [ ] 400×300 ST7305 屏幕图文更新正常
- [ ] SHTC3 温湿度、电池 GPIO4 ADC、KEY 按键实际响应
- [ ] ES7210 麦克风采样率/通道/增益，长时间音频稳定性
- [ ] Hey Jarvis 误唤醒、不同距离唤醒、Assist 结束后可重复监听
- [ ] HA Assist 可用中文 STT，执行灯控、反馈文本
- [ ] Wi-Fi 断线、HA 离线、冷启动、长时间待机后恢复
- [ ] 峰值内部 RAM / DMA / PSRAM / 堆碎片、屏幕刷新与推理任务冲突

## 推荐分阶段验收

### Phase 1：构建与 USB 配网（下一步优先）

1. 本机配置校验和完整固件编译 **已通过**；可开始真机步骤。最新版 GitHub Actions 构建另行核对。
2. 保留本地 `secrets.yaml` 中的设备专属 API key 安全备份，禁止提交 Git。
3. 首次 USB 烧录，Improv Serial 输 Wi-Fi，保持重启后连接。
4. HA ESPHome 配对，检查连通性，并测试加密 OTA。

**退出条件**：不用把 Wi-Fi 密码编进固件，USB 配网可重复，API 与 OTA 都安全可用。

### Phase 2：显示/传感器/按键

屏幕测试 + 30 秒刷新，SHTC3、ADC、HA 时间，KEY/BOOT。先测设备基础硬件，不依赖 HA STT。

### Phase 3：语音链路

验证 ES7210 → Hey Jarvis → HA STT → 中文 Assist → HA 操作，确保 KEY 可随时作为备用入口；测成功率与误唤醒。HA 语音服务自身必须先可用。

### Phase 4：可靠性与体验

断网重连、连续唤醒、24 小时运行、OTA 回退、安全恢复；再决定是否加入 ES8311 扬声器、中文显示、RTC、低功耗策略和电池百分比校准。

## 重要工程边界

- 不把成功写入 GitHub 误认为配置/编译/真机通过。
- 不默认加入 BLE Improv；优先保留语音推理的可用内存。
- USB Improv 本身不替代 API key；此项目第一次仍需要私有 `secrets.yaml` 中的 API key。
- 真机未测试之前，不保证 USB 端口行为、音频配置与 ST7305 驱动兼容。
- 对已经运行旧固件的设备，升级到强制加密 OTA 需要遵守 ESPHome 官方迁移步骤；首次 USB 全新烧录可直接开启。

## 关键资料

- https://docs.waveshare.com/ESP32-ESPHome-Tutorials/Example-RLCD-Voice
- https://esphome.io/components/improv_serial/
- https://esphome.io/components/api/
- https://esphome.io/components/ota/esphome/
- https://esphome.io/components/micro_wake_word/
