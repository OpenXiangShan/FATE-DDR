# FAMSE 平台配置

平台编号定义在 vsrc/famse_platform.vh。PLATFORM 是每个实例的整数参数，宏只是编号名称。
新增平台时分配新的编号，并在 famsev2_top 和 mig_phy_driver 中增加显式分支，配置逻辑 rank 数、维护操作和写计数行为，提供独立命名的 MIG Tcl。不要将 default 分支改成现有平台的兜底选择。

| 行为 | VU19P（0） | VCU128（1） |
| --- | --- | --- |
| CS 片选 | 按两个 rank 分别选通 | 两个物理 CS 同时选通，mc_CS_n=16'hfcfc |
| winRank | 跟随目标 rank | 固定 0 |
| REF/ZQS | 两个 rank 轮换 | 固定逻辑 rank 0 |
| 写数据 credit | 下降沿 | 上升沿 |
| ZQS WE_n | 保留原发布包高电平 | 标准 ZQCS 低电平 |
| MIG BG / ODT | 各 16 位 | 各低 8 位 |

两板共用 ODT 波形生成器。现有实现只在 ODT0 输出写终端脉冲，ODT1 恒为零。这是现有发布包行为，并不是任意 DDR4 rank 拓扑的通用调度器。
VU19P 的历史 ZQS 编码不是标准 ZQCS，本次合并保留其行为，避免代码整理同时引入未经上板验证的维护命令变化。
这些历史兼容项和时序参数不能直接复制用于未知新平台。

DFI 地址是两相各 18 位：phase 0 取 [16:0]，phase 1 取 [34:18]。
读数据宽度固定为 512 位。共享 ILA 布局来自 VCU128 发布包，包含数据、CS、ODT、地址和 FIFO 错误锁存。
Vitis 平台需用对应器件的 XSA 重新生成；实例参数不能转换 bit/XSA 的目标器件。

参考 wrapper 保留 VU19P 的引脚接口并显式选择 VU19P。其他平台的完整连接请参考相应发布包 fpga_top.sv。
