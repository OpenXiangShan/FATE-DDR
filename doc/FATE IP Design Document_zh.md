# FATE 设计文档

## 概述

FATE（FPGA-based Frequency-Adaptive Timing-Accurate DDR PHY Emulator）是一款基于 FPGA 的 DDR PHY 仿真器，用于在处理器硅前性能评估中精准复现 CPU 与内存子系统之间的时序关系。FATE 是一个跨时钟域设计，分为低频域（HostMC 侧）和高频域（TargetPHY 侧），通过异步 FIFO 进行命令与数据的传输。本设计已在 AMD Virtex UltraScale+ VU19P FPGA 上实现并验证，为方便用户理解与使用，下文将展开各模块的详细设计说明。

> 命名说明: FATE 即 FAMSE，FAMSE 即 FATE。源码中大量使用 famsev2 等模块名，这是项目早期内部代号 FAMSE 的遗留。FATE 是论文发表时确定并公开使用的名称，两者指向同一设计，不影响理解与使用。

## 顶层结构

FATE 顶层模块为 famsev2_top，内部划分为以下功能模块：

| 模块名称 | 时钟域 | 主要功能 |
| :----: | :----: | :----: |
| `cmd_buffer` | `dfi_clk` / `mig_clk` | DFI 命令跨时钟域缓存 |
| `wrdata_buffer` | `dfi_clk` / `mig_clk` | 写数据跨时钟域缓存与位宽转换|
| `rddata_buffer` | `dfi_clk` / `mig_clk` | 读数据跨时钟域缓存与位宽转换|
| `famsev2_ctrl` | `mig_clk` | 核心调度状态机，命令仲裁与维护操作定时 |
| `mig_phy_driver` | `mig_clk` | 将内部命令转换为 MIG PHY 控制信号格式 |
| `mig_phy_odt` | `mig_clk` |生成 MIG PHY 的 ODT 信号 |

此外，另有 `async_fifo`、`sync_fifo`、`delay_n` 等通用基础模块，供上述功能模块复用。

### 信号流概览

#### 命令通路：
HostMC DFI 命令 → `cmd_buffer` → 异步 FIFO → 同步 FIFO → `famsev2_ctrl` → `mig_phy_driver` → MIG PHY

#### 写数据通路：
HostMC DFI 写数据（256 bit）→ `wrdata_buffer` 异步 FIFO → 拼接为 512 bit → 同步 FIFO → MIG PHY

#### 读数据通路：
MIG PHY 读数据（512 bit）→ `rddata_buffer` 同步 FIFO → 拆分为 256 bit → 异步 FIFO → HostMC DFI

## 模块详细说明

### famsev2_top
**文件**：`famsev2_top.v`
**功能**：FATE 顶层模块，例化所有子模块并完成互连。对外暴露 DFI 接口（HostMC 侧）和 MIG PHY 接口（TargetPHY 侧）。

### 主要接口：

**DFI 时钟与命令**：`dfi_clk`, `dfi_*` 命令信号，`dfi_wrdata`, `dfi_rddata` 等

**MIG 时钟与命令**：`mig_clk`, `mc_*` 命令信号，`mig_wrdata`, `mig_rddata` 等

**控制与状态**：`rst_n`, `calDone`（MIG 校准完成）

### 关键实现点：

内部例化 `cmd_buffer`, `famsev2_ctrl`, `mig_phy_driver`, `wrdata_buffer`, `rddata_buffer`, `mig_phy_odt`。

维护一个写数据就绪计数器 `wrdata_ready_cnt`，用于在写数据缓存非空时才向调度器发出写请求。

提供大量调试信号，并例化 ILA 核（可选）用于在线调试。

---

### cmd_buffer

**文件**：`cmd_buffer.v`

**功能**：解析来自 HostMC 的 DFI 命令，提取 ACT、RD、WR 操作，并经过跨时钟域 FIFO 传递至调度器。

**命令解析规则**（仅 phase 0 / slot0）：

| DFI 组合 | 识别命令 |
|-----------|----------|
| `cs_n == 0` 且 `act_n == 0` | ACT |
| `cs_n == 0`, `act_n == 1`, `ras_n == 1`, `cas_n == 0`, `we_n == 1` | RD |
| `cs_n == 0`, `act_n == 1`, `ras_n == 1`, `cas_n == 0`, `we_n == 0` | WR |

**数据通路**：

DFI 命令 → 异步 FIFO（`dfi_clk` → `mig_clk`）→ 同步 FIFO（`mig_clk`）→ `cmd_info_to_ctrl` → `famsev2_ctrl`

**关键时序约束**：

- 异步 FIFO 读使能受 `async_rd_gap` 计数器限制，两次读操作至少间隔两个 `mig_clk` 周期，避免慢写快读导致的数据不稳定。
- 同步 FIFO 读使能要求 `cmd_info_to_ctrl` 已空闲（即前一个命令已被控制器取走）。
- 输出 `debug_cmd_fifo_empty` 用于观察命令 FIFO 状态。

---

### famsev2_ctrl

**文件**：`famsev2_ctrl.v`

**功能**：FATE 的核心调度状态机，负责命令仲裁、维护操作定时与命令转换。

**状态机**：

| 状态 | 说明 |
|------|------|
| `STA_RET` | 复位状态 |
| `STA_IDL` | 空闲，等待命令或维护请求 |
| `ACT_CMD` / `ACT_WAT` | 执行 ACT 命令 |
| `RDA_CMD` / `RDA_WAT` | 执行读（自动预充电） |
| `WRA_CMD` / `WRA_WAT` | 执行写（自动预充电） |
| `REF_CMD` / `REF_WAT` | 执行刷新 |
| `ZQS_CMD` / `ZQS_WAT` | 执行 ZQ 校准 |
| `VAT_CMD` / `VAT_WAT` | 执行 VTT 激活 |
| `VRD_CMD` / `VRD_WAT` | 执行 VTT 读 |

**维护操作定时**：

- VTT：约 `1 us`
- REF：约 `6 us`
- ZQS：约 `60 ms`

以上通过三个看门狗计数器 `vtt_watch_dog`, `ref_watch_dog`, `zqs_watch_dog` 实现，溢出后触发对应命令。

**关键逻辑**：

- HostMC 发出的 ACT 不直接转发，而是记录目标 Rank/BG/BA 与行地址（`ActivatedRowMem`）。
- RD/WR 请求转化为 `ACT → RD/WR → PRE` 序列（自动预充电），保持行默认关闭。
- 写命令仅在写数据就绪时才有效（`fm_wrReq && wrdata_ready_cnt > 0`），由顶层传递。
- VTT 读产生的无效数据通过 `rddata_ignore` 信号告知读数据缓冲区丢弃。
- 优先级：维护命令（REF/ZQS/VTT）高于普通读写，确保及时响应。
- 输出多种调试状态信号，供 ILA 观测。

---

### mig_phy_driver

**文件**：`mig_phy_driver.v`

**功能**：将调度器输出的内部命令（`actReq`, `rdaReq`, `wraReq`, `refReq`, `zqsReq` 等）转换为 MIG PHY 所需的多周期控制信号格式。

**主要输出**：

- `mc_CS_n[15:0]`：片选（仅使用 slot0）
- `mc_ADR[135:0]`：地址/命令编码
- `mc_BA[15:0]`, `mc_BG[15:0]`：Bank 地址
- `mc_ACT_n[7:0]`：激活命令
- `mc_CKE[15:0]`：固定为全 `1`
- `mcCasSlot`, `mcCasSlot2`：固定为 `0`
- `winRank`, `mcRdCAS`, `mcWrCAS`：读写 CAS 指示

**实现方式**：

纯组合逻辑，根据命令优先级选择对应字段，并按照 MIG 要求的每 8 位一组重复模式生成信号。

---

### wrdata_buffer

**文件**：`wrdata_buffer.v`

**功能**：将 HostMC 的 256 位 DFI 写数据转换为 MIG PHY 需要的 512 位突发数据。

**数据通路**：

`dfi_wrdata` (256 bit) → 异步 FIFO → 两个 256 位拼接成 512 位 → 同步 FIFO → `mig_wrdata` (512 bit)

**关键实现**：

- 使用 `wrtick_lo` 和 `wrtick_hi` 标志管理两个半拍的接收。
- 写掩码 `dfi_wrdata_mask` (32 bit) 扩展为 64 bit，输出时取反以适配 MIG 极性。
- 输出 `wrdata_filling` 表示数据正在填充，供顶层计数。

---

### rddata_buffer

**文件**：`rddata_buffer.v`

**功能**：将 MIG PHY 返回的 512 位读数据拆分为两个 256 位，并过滤 VTT 产生的无效数据。

**数据通路**：

`mig_rddata` (512 bit) → 同步 FIFO → 拆分为低 256 位和高 256 位 → 异步 FIFO → `dfi_rddata` (256 bit)

**关键实现**：

- `rddata_ignore` 信号用于丢弃 VTT 读数据。
- `RD_ERROR` 信号在 DFI 期望数据但异步 FIFO 为空时置位，用于检测时序违例。
- 提供丰富的调试信号，如 `debug_sync_fifo_*`, `debug_async_fifo_*`。

---

### async_fifo

**文件**：`async_fifo.v`

**功能**：异步 FIFO，用于跨时钟域的数据/命令传输。

**特点**：

- 格雷码指针同步
- 两级同步触发器消除亚稳态
- 组合读数据输出
- 可配置数据宽度 `DATA_WIDTH` 和深度 `DEPTH`

**端口**：

- 写时钟域：`wr_clk`, `wr_rst_n`, `wr_en`, `wr_data`, `full`, `wr_ack`
- 读时钟域：`rd_clk`, `rd_rst_n`, `rd_en`, `rd_data`, `empty`, `rd_valid`

---

### sync_fifo

**文件**：`sync_fifo.v`

**功能**：同步 FIFO，用于同一时钟域内的数据缓冲。

**特点**：

- 二进制读写指针
- 读写数据寄存输出
- 可配置数据宽度 `DATA_WIDTH` 和深度 `DEPTH`

**端口**：

- `clk`, `rst_n`
- 写端口：`wr_en`, `wr_data`, `full`, `wr_ack`
- 读端口：`rd_en`, `rd_data`, `empty`, `rd_valid`

---

### delay_n

**文件**：`delay_n.v`

**功能**：可变延迟线，可配置延迟级数 `N`。

**用途**：用于对齐写使能或读使能等控制信号。

**实现**：移位寄存器链，当 `N=0` 时直通，`N>=2` 时从移位寄存器中抽取延迟后的信号。

---

### mig_phy_odt

**文件**：`mig_phy_odt.v`

**功能**：简化的 ODT 波形生成器，用于替代 Xilinx 官方 `ddr4_v2_2_8_cal_mc_odt`。

**特点**：

- 仅在写 CAS 时产生固定宽度的 ODT 脉冲
- 使用 24 位移位寄存器支持脉冲重叠
- 只使用 ODT pin0，pin1 固定为 `0`

**端口**：`clk`, `rst_n`, `winWrite`, `mc_ODT[15:0]`

## 预设时序参数

以下参数定义在 famsev2_ctrl.v 中，需根据 TargetPHY 频率与 DDR 规范进行调整。这些数值是基于 DDR4-1600、DFI 1:4、mig_clk = 200 MHz 的假设，其中包含许多宽松估计，存在优化空间。以下数值均以mig clk计数。


| 参数名 | 数值 | 说明 |
| :-----: | :----: | :----: |
| `WAIT_CNT_ACT` | 4 | ACT 命令等待时间 |
| `WAIT_CNT_RDA` | 18 | 读+自动预充电等待时间 |
| `WAIT_CNT_WRA` | 13 | 写+自动预充电等待时间 |
| `WAIT_CNT_REF` | 70 | 刷新等待时间 |
| `WAIT_CNT_ZQS` | 32 | ZQ 校准等待时间 |
| `WAIT_CNT_VAT` | 9 | VTT 激活等待时间 |
| `WAIT_CNT_VRD` | 10 | VTT 读等待时间 |
| `VTT_WATCH_DOG` | 187 | VTT 触发周期（约 1 μs） |
| `REF_WATCH_DOG` | 600 | REF 触发周期（约 6 μs） |
| `ZQS_WATCH_DOG` | 60000 | ZQS 触发周期（约 60 ms） |

## 调试与验证

FATE 内部包含多个 ILA 调试 IP（如 `ila_ctrl`, `ila_famse_top`, `ila_afifo` 等），可观测关键信号：

- 状态机状态（`debug_*_cmd`, `debug_*_wat`）

- 内部命令请求（`fm_*`）

- FIFO 空满与读写使能

- 读数据错误标志（`RD_ERROR`）

### 验证建议：

- 使用简单 `dfi_master` 或 `AXI Master` + 商业 MC 进行模块级仿真；

- 验证时序精确性（与商业 PHY 对比周期数）;

- 集成到完整 SoC（如香山处理器 + 商业 MC）进行全系统测试。

## 总结

FATE 设计实现了 DDR PHY 仿真器的核心功能：命令解析与缓存、调度仲裁、维护操作定时、数据宽度转换和 ODT 控制。其低资源开销和标准 DFI 接口使其易于集成到各种 FPGA 硅前评估平台。源代码清晰简单、注释丰富，适合作为学术研究与工业原型的基础。
