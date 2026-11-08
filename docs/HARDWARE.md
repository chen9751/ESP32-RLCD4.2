# 硬件对照：ESP32-S3-RLCD-4.2

微雪 ESP32-S3-WROOM-1-N16R8：16 MB Flash、8 MB Octal PSRAM。屏幕是 **ST7305 单色反射式 LCD 400×300**，没有触摸控制器和背光；不要使用触摸 / TFT / PWM 背光配置。

| 功能 | 芯片 / 引脚 | 使用情况 |
| --- | --- | --- |
| 反射屏 SPI CLK / MOSI | GPIO11 / GPIO12 | 已声明 |
| ST7305 DC / CS / RESET | GPIO5 / GPIO40 / GPIO41 | 已声明 |
| I²C SDA / SCL | GPIO13 / GPIO14 | 共用总线 |
| SHTC3 | I²C 0x70 | 已配置温湿度 |
| ES7210 双麦 ADC | I²C + I²S DIN GPIO10 | 单通道送 HA，双麦阵列算法未验证 |
| ES8311 扬声 DAC | I²C + I²S DOUT GPIO8 | 可选包 |
| I²S BCLK / LRCLK / MCLK | GPIO9 / GPIO45 / GPIO16 | 已声明 |
| 功放使能 | GPIO46 | 可选包，按微雪示例处理；需真机验证 |
| 18650 电池 ADC | GPIO4，经 1:3 分压 | 已配置电压（V） |
| KEY 用户按键 | GPIO18，低有效 | 启动 Assist |
| BOOT 下载按键 | GPIO0，低有效 | 仅读状态，按住重启影响启动模式 |
| PCF85063A RTC | I²C | 暂未启用，当前时钟由 HA 同步 |
| TF 卡槽 | SPI | 暂未启用，不与显示共用 CS |

## 核心设计决定

1. 只用 ESP-IDF 框架及 octal 80 MHz PSRAM，屏幕依赖社区 `st7305_rlcd` 组件。
2. 屏幕刷新时间先设 30s，状态变化可主动刷新。后续观察残影、功耗、总线稳定性。
3. 电池采用 3 倍电压校正。**不把 2.5–4.2 V 简单线性转换为真实电量百分比**，这需要电池化学体系与负载条件校准。
4. 不在首版叠加 SD、RTC、BLE、Wi-Fi 扫描、深度睡眠，避免早期资源与总线问题。
5. 麦克风由 ES7210 转换后的 I²S 输入；双麦物理设计不等于 ESPHome 自动支持回声消除。
6. 功放 GPIO46 在 ESP32-S3 也属于启动相关引脚，应在真机确认上电行为。

## 来源

- 微雪硬件文档：https://docs.waveshare.com/ESP32-S3-RLCD-4.2
- 微雪 ESPHome 针对型号的教程：https://docs.waveshare.com/ESP32-ESPHome-Tutorials/Example-RLCD-Voice
- 官方开源示例：https://github.com/waveshareteam/ESP32-S3-RLCD-4.2
- ESPHome Devices 项目配置：https://devices.esphome.io/devices/waveshare-esp32-s3-rlcd-42/
- 社区 ST7305 驱动：https://github.com/kylehase/ESPHome-ST7305-RLCD
