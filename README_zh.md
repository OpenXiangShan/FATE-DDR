# FATE: FPGA-based Frequency-Adaptive Timing-Accurate DDR PHY Emulator

> 英文版详见[README.md](./README.md).

[TOC]

## 概述

FATE 是一个基于 FPGA 平台的 DDR PHY 仿真器。它主要用于基于 FPGA 的处理器硅前性能评估，通过在精准复现 CPU 与内存子系统之间的时序关系来校准 FPGA 平台上的性能评估结果。它连接 MC 的 DFI 接口与 FPGA 上的高速 DDR PHY（如 Xilinx MIG PHY）接口，在保持 DFI 协议语义的前提下，实现频率自适应与周期级精确的内存行为仿真。

> 命名说明：
> 本项目在开发初期及内部工程中使用的代号为 FAMSE，源码中大量出现 famsev2 等模块命名。FAMSE 就是 FATE，FATE 就是 FAMSE。FATE 是在论文正式发表时确定的名称，而 FAMSE 是此前的内部代号。由于 FAMSE 的原意已不再适合公开项目，我们在公开发布时统一采用 FATE 这一名称。更名不影响该工具的理解与使用。

## 背景与动机

在处理器设计流程中，准确且快速的硅前性能评估至关重要。纯软件仿真精度高但速度极慢，商业硬件仿真平台速度快但成本高昂。基于 FPGA 的评估方案以可接受的成本提供了运行完整工作负载的能力。然而，FPGA 上的 CPU 只能运行在较低频率（通常几十 MHz），而 DDR 内存因物理层约束必须运行在数百 MHz 甚至更高的频率。这种频率失配导致内存访问延迟相对于 CPU 被大幅缩短，使内存看起来像一个巨大的 Cache，从而严重扭曲性能测量结果。

FATE 通过下述方式解决该问题：

- 在 HostMC 与 TargetPHY 之间插入一个透明的 DFI-to-DFI 转换层；

- 由 FATE 代理执行刷新、ZQ 校准以及 TargetPHY 特有的 VTT 操作；

- 将 HostMC 的读/写请求转换为 ACT–RD–PRE / ACT–WR–PRE 序列，保持行默认关闭；

- 通过严格的时序分析证明在最坏情况下仍能满足 DFI 协议时序约束。

实验表明，FATE 可以达到周期级时序精度，并支持在 FPGA 上稳定运行完整的 SPEC CPU 2006 基准测试。

![FATE概览](./doc/fate-overview.png "fate overview")

## 主要特性

- 周期级时序精确：与商业 MC-PHY 对比，10K 次顺序、随机及 trace 读写均实现 0% 周期差异。

- 频率自适应：支持 HostMC 在最高 10 MHz（以 DDR4-1600、DFI 1:4 为例）的频率下稳定工作。

- 完整系统验证：已集成到包含香山处理器（XiangShan）和商业内存控制器的 SoC 中，成功运行完整 SPEC CPU 2006 套件。

- 资源开销极低：在 Xilinx VU19P 上 LUT/FF 利用率低于 1%，BRAM 约 5.8%，无 DSP。

- 易于集成：提供标准 DFI 3.1 兼容接口，可作为轻量 IP 嵌入现有 SoC 设计。

## 架构概览

FATE 采用跨时钟域设计，分为低频域和高频域，二者通过异步 FIFO 进行命令与数据的传输。

### 低频域（Low-Frequency Domain）

- 对接 HostMC 的 DFI 接口，充当逻辑 PHY；

- 接收 HostMC 发出的 DFI 命令，仅转发 RD、WR、ACT，其余命令丢弃；

- 读数据、写数据和命令分别通过独立的异步 FIFO 缓存；

### 高频域（High-Frequency Domain）

- 对接 TargetPHY 的类 DFI 接口，充当逻辑 MC。

- `cmd_buffer`：解析来自 HostMC 的 DFI 命令，并处理跨时钟同步问题。

- `wrdata_buffer`：将 256 位 DFI 写数据拼接为 512 位 MIG 写数据，并处理跨时钟同步问题。

- `rddata_buffer`：将 512 位 MIG 读数据拆分为 256 位 DFI 读数据，并处理跨时钟同步问题。

- `famsev2_ctrl`：核心调度状态机，负责命令仲裁，包括 REF/ZQ/VTT 定时、ACT/RD/WR 处理及其调度。

- `mig_phy_driver`：将内部命令翻译为 MIG PHY 需要的 16 位控制信号格式（仅使用 slot0）。

![FATE架构图](./doc/fate-architecture.png "fate architecture")

## 仓库结构

    doc/            # 模块级说明文档
    fifos/          # FATE 所需 fifo 的仿真测试环境
    tcl/            # FATE 所需 IP 的 tcl 脚本
    vsrc/           # FATE 源码
    wrapper/        # FATE wrapper 的参考代码
    LICENSE.txt     # 开源协议
    README_zh.md    # 本文档
    README.md       # 本文档的英文版

## 环境依赖

- FPGA 平台：AMD Virtex™ UltraScale+™ VU19P FPGA

- EDA 工具：Vivado 2024.2

- 仿真器：VCS

- TargetPHY：Xilinx MIG IP（PHY-Only 模式）

- HostMC：任何符合 DFI 3.1 接口的内存控制器 IP

## 部署说明

### 例化必要的 IP

在您的项目中例化 FATE 所需 IP，使用 Vivado 2024.2 执行 `tcl/ip_export_mig_phy.tcl` 脚本，该脚本将生成符合要求的 MIG PHY IP。另外，`tcl/` 目录下的另外三个用于实例化 ILA 的 tcl 脚本也是有益的，也建议实例化。

### 例化 FATE

在您的项目中例化 famsev2_top，连接 DFI 接口与 MIG PHY 接口。以下为关键连接示例（伪代码）：

    famsev2_top u_fate (
        .dfi_clk          (host_dfi_clk),
        .mig_clk          (mig_ui_clk),
        .rst_n            (system_rst_n),
        .calDone          (mig_init_calib_complete),

        // DFI 命令
        .dfi_reset_n      (host_dfi_reset_n),
        .dfi_cke          (host_dfi_cke),
        .dfi_odt          (host_dfi_odt),
        .dfi_address      (host_dfi_address),
        .dfi_ba           (host_dfi_ba),
        .dfi_bg           (host_dfi_bg),
        .dfi_cs_n         (host_dfi_cs_n),
        .dfi_act_n        (host_dfi_act_n),
        .dfi_ras_n        (host_dfi_ras_n),
        .dfi_cas_n        (host_dfi_cas_n),
        .dfi_we_n         (host_dfi_we_n),

        // DFI 数据
        .dfi_wrdata_en    (host_dfi_wrdata_en),
        .dfi_wrdata       (host_dfi_wrdata),
        .dfi_wrdata_mask  (host_dfi_wrdata_mask),
        .dfi_rddata_en    (host_dfi_rddata_en),
        .dfi_rddata       (host_dfi_rddata),
        .dfi_rddata_valid (host_dfi_rddata_valid),

        // MIG PHY 命令
        .mc_ACT_n         (mig_mc_act_n),
        .mc_ADR           (mig_mc_adr),
        .mc_BA            (mig_mc_ba),
        .mc_BG            (mig_mc_bg),
        .mc_CKE           (mig_mc_cke),
        .mc_CS_n          (mig_mc_cs_n),
        .mc_ODT           (mig_mc_odt),
        .winRank          (mig_win_rank),
        .mcRdCAS          (mig_rd_cas),
        .mcWrCAS          (mig_wr_cas),
        .mcCasSlot        (mig_cas_slot),
        .mcCasSlot2       (mig_cas_slot2),
        .winBuf           (mig_win_buf),
        .winInjTxn        (mig_win_inj_txn),

        // MIG PHY 数据
        .mig_rddata_en    (mig_rddata_en),
        .mig_rddata       (mig_rddata),
        .per_rd_done      (mig_per_rd_done),
        .gt_data_ready    (mig_gt_data_ready),
        .mig_wrdata_en    (mig_wrdata_en),
        .mig_wrdata       (mig_wrdata),
        .mig_wrdata_mask  (mig_wrdata_mask)
    );

更多细节可以参考 `wrapper/` 路径下的参考代码或者 Release 中的参考工程。

### 配置参数

FATE 内部的主要时序参数已在 famsev2_ctrl.v 中定义为 localparam，例如：

- WAIT_CNT_REF / WAIT_CNT_ZQS 等维护操作等待周期；

- REF_WATCH_DOG / ZQS_WATCH_DOG 看门狗溢出阈值。

这些参数已根据 DDR4-1600、DFI 1:4、200 MHz TargetPHY 的假设进行优化。若更改 TargetPHY 频率，需相应调整这些参数。

### 集成与验证

建议先使用提供的简单 dfi_master 或简单的 AXI Master + 商业 MC 进行模块级仿真，验证周期精确性后再部署到完整 SoC 中。

### 实验与结果

以下结果摘自论文，详情请参阅论文正文：

- 周期精准性：在 10K 顺序、随机、trace 访存模式下，FATE 与商业 DDR PHY 的总周期数完全一致（差异 0%）。

- 稳定性：在真实 FPGA 平台上重复运行 SPEC CPU 2006 gcc_scilab 15 次，运行时间波动 < 0.04%。

- 全系统正确性：集成香山处理器（Kunminghu）与商业 MC 的 SoC，在 FPGA 上成功运行完整 SPEC CPU 2006 套件，无错误。

- 与固定延迟对比：FATE 的性能表现无法用任何单一固定延迟值在所有基准上匹配，证明了其动态时序仿真的必要性。

![固定延迟对比实验](./doc/fate_vs_fixed.png "fate_vs_fixed")

## 许可证

本项目采用木兰宽松许可证第二版开源，详见 LICENSE 文件。

## 联系方式

如有问题或建议，可邮件联系作者<yecongrong22s@ict.ac.cn>或提交 Issue。
