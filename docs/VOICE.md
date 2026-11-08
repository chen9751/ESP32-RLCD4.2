# ESPHome × Home Assistant Assist 语音接入

## 首版链路（无需决定唤醒词）

```text
KEY (GPIO18) 一次短按
    -> ES7210 / I²S PCM 16kHz
    -> ESPHome voice_assistant
    -> Home Assistant Assist Pipeline
    -> STT（如已部署的 Whisper / FunASR）-> 中文对话代理 -> HA 服务
    -> ESPHome 状态 / 识别文字等实体；无需扬声器或 TTS
```

- 按键一次启动，使用 Assist 静音检测自动结束该条语音录入。
- 若 HA 的 STT 尚不可用，ESP32 侧可以测试屏幕、传感器、I²C 扫描、网络与麦克风初始化，但不能完成语音控制。
- `Last Recognized Speech` 是服务端返回的 STT 文字；`Last Assist Reply` 依赖 HA 的 TTS 开始事件，**无 TTS 配置不保证能收到文本回复**。
- 默认不接入额外的 LLM / OpenClaw；以后可在 HA 中替换 conversation agent，ESPHome 端不用重做。
- 如果要持续待机唤醒，再采用可选的 microWakeWord 包；不能一边按键一边假装已经有中文唤醒。

## 本地唤醒词：待用户选择

ESPHome 的内置 `micro_wake_word` 支持英文模型，例如：

| 模型 ID | 读音 / 唤醒词 | 说明 |
| --- | --- | --- |
| `okay_nabu` | Okay Nabu | Home Assistant / Nabu 生态 |
| `hey_jarvis` | Hey Jarvis | 微雪 ESPHome 示例正在使用 |
| `hey_mycroft` | Hey Mycroft | 英文社区模型 |
| `alexa` | Alexa | 英文短唤醒词，可能更容易误触发 |

此外有实验模型如 `okay_computer` 和 `hey_home_assistant`；这些模型需要从对应仓库 JSON 路径指定且效果需测试。

**不要将这些英文模型等同于中文唤醒能力。** 自定义中文如“小智同学”需要另行收集数据、训练与评测 microWakeWord 模型；ESPHome 没有为本项目选定已验证可用的中文官方模型。

在决定模型后：
1. 在主 YAML 的 substitutions 添加 `wake_word_model: okay_nabu`（将其替换为所选 ID）。
2. 取消注释 `wake: !include packages/wake_word_optional.yaml`。
3. 执行 config / compile；新模型必须随固件编译下载，不是仅在 HA 设置里改名即可。
4. 真机验证误唤醒、远场识别、重复启停后的内存，以及是否与屏幕刷新和音频占用冲突。

## 后续测试清单

- [ ] ES7210 I²C 地址、16000Hz 采样、双麦通道映射
- [ ] KEY 按下到 Assist 开始监听、静音关闭、二次激活
- [ ] STT 中文准确度 / 端到端延迟（HA 服务端决定）
- [ ] 服务端意图控制是否使用预期 52 个暴露实体
- [ ] 录音传输中丢包 / HA 暂时断连恢复
- [ ] 文本回显方式：不使用 TTS 时如何取得 Assist 回复文字
- [ ] 英文唤醒模型远场表现 / 中文模型训练可行性
- [ ] 叠加 ES8311 输出后的 DMA、PSRAM 与总线冲突

## 权威参考

- ESPHome Assist：https://esphome.io/components/voice_assistant/
- ESPHome microWakeWord：https://esphome.io/components/micro_wake_word/
- ESPHome 模型目录：https://github.com/esphome/micro-wake-word-models
- 微雪针对本板的示例：https://docs.waveshare.com/ESP32-ESPHome-Tutorials/Example-RLCD-Voice
