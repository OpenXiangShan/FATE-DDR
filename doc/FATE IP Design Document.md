# FATE Design Documentation

## Overview

FATE (FPGA-based Frequency-Adaptive Timing-Accurate DDR PHY Emulator) is an FPGA-based DDR PHY emulator designed to accurately reproduce the timing relationship between the CPU and the memory subsystem during pre-silicon performance evaluation of processors. FATE is a cross-clock-domain design, divided into a low-frequency domain (HostMC side) and a high-frequency domain (TargetPHY side), with commands and data transferred through asynchronous FIFOs. This design has been implemented and verified on an AMD Virtex UltraScale+ VU19P FPGA. To help users understand and use it, the detailed design of each module is described below.

> Naming note: FATE is FAMSE, and FAMSE is FATE. The source code contains many module names such as `famsev2`, which are remnants of the project's early internal codename FAMSE. FATE is the name finalized and publicly used when the paper was published. Both refer to the same design, and the naming difference does not affect understanding or usage.

## Top-Level Structure

The top-level module of FATE is `famsev2_top`, which is internally divided into the following functional modules:

| Module Name | Clock Domain | Main Function |
| :---------: | :----------: | :-----------: |
| `cmd_buffer` | `dfi_clk` / `mig_clk` | Cross-clock-domain buffering of DFI commands |
| `wrdata_buffer` | `dfi_clk` / `mig_clk` | Cross-clock-domain buffering and width conversion of write data |
| `rddata_buffer` | `dfi_clk` / `mig_clk` | Cross-clock-domain buffering and width conversion of read data |
| `famsev2_ctrl` | `mig_clk` | Core scheduling state machine, command arbitration, and maintenance operation timing |
| `mig_phy_driver` | `mig_clk` | Converts internal commands into MIG PHY control signal format |
| `mig_phy_odt` | `mig_clk` | Generates ODT signals for the MIG PHY |

In addition, common basic modules such as `async_fifo`, `sync_fifo`, and `delay_n` are provided for reuse by the above functional modules.

### Signal Flow Overview

#### Command Path:
HostMC DFI commands → `cmd_buffer` → asynchronous FIFO → synchronous FIFO → `famsev2_ctrl` → `mig_phy_driver` → MIG PHY

#### Write Data Path:
HostMC DFI write data (256 bit) → `wrdata_buffer` asynchronous FIFO → concatenated into 512 bit → synchronous FIFO → MIG PHY

#### Read Data Path:
MIG PHY read data (512 bit) → `rddata_buffer` synchronous FIFO → split into 256 bit → asynchronous FIFO → HostMC DFI

## Module Details

### famsev2_top

**File**: `famsev2_top.v`

**Function**: FATE top-level module. Instantiates all submodules and completes their interconnection. Exposes the DFI interface (HostMC side) and the MIG PHY interface (TargetPHY side).

**Main Interfaces**:

- **DFI clock and commands**: `dfi_clk`, `dfi_reset_n`, `dfi_cke`, `dfi_odt`, `dfi_address`, `dfi_ba`, `dfi_bg`, `dfi_cs_n`, `dfi_act_n`, `dfi_ras_n`, `dfi_cas_n`, `dfi_we_n`
- **DFI write data**: `dfi_wrdata_en`, `dfi_wrdata`, `dfi_wrdata_mask`
- **DFI read data**: `dfi_rddata_en`, `dfi_rddata`, `dfi_rddata_valid`
- **MIG commands**: `mc_ACT_n`, `mc_ADR`, `mc_BA`, `mc_BG`, `mc_CKE`, `mc_CS_n`, `mc_ODT`, `winRank`, `mcRdCAS`, `mcWrCAS`, `mcCasSlot`, `mcCasSlot2`, `winBuf`, `winInjTxn`
- **MIG data**: `mig_rddata_en`, `mig_rddata`, `per_rd_done`, `gt_data_ready`, `mig_wrdata_en`, `mig_wrdata`, `mig_wrdata_mask`
- **Control and status**: `rst_n`, `calDone` (MIG calibration complete)

**Key Implementation Points**:

- Internally instantiates `cmd_buffer`, `famsev2_ctrl`, `mig_phy_driver`, `wrdata_buffer`, `rddata_buffer`, and `mig_phy_odt`.
- Maintains a write-data-ready counter `wrdata_ready_cnt` to ensure write requests are only issued to the scheduler when the write data buffer is non-empty.
- Provides extensive debug signals and optionally instantiates ILA cores for online debugging.

---

### cmd_buffer

**File**: `cmd_buffer.v`

**Function**: Parses DFI commands from the HostMC, extracts ACT, RD, and WR operations, and passes them through cross-clock-domain FIFOs to the scheduler.

**Command Parsing Rules** (phase 0 / slot0 only):

| DFI Combination | Recognized Command |
|-----------------|-------------------|
| `cs_n == 0` and `act_n == 0` | ACT |
| `cs_n == 0`, `act_n == 1`, `ras_n == 1`, `cas_n == 0`, `we_n == 1` | RD |
| `cs_n == 0`, `act_n == 1`, `ras_n == 1`, `cas_n == 0`, `we_n == 0` | WR |

**Data Path**:

DFI command → asynchronous FIFO (`dfi_clk` → `mig_clk`) → synchronous FIFO (`mig_clk`) → `cmd_info_to_ctrl` → `famsev2_ctrl`

**Key Timing Constraints**:

- The asynchronous FIFO read enable is gated by the `async_rd_gap` counter, requiring at least two `mig_clk` cycles between consecutive read operations to avoid instability caused by slow writes and fast reads.
- The synchronous FIFO read enable requires that `cmd_info_to_ctrl` is idle (i.e., the previous command has been taken by the controller).
- Outputs `debug_cmd_fifo_empty` to observe the command FIFO status.

---

### famsev2_ctrl

**File**: `famsev2_ctrl.v`

**Function**: FATE core scheduling state machine. Responsible for command arbitration, maintenance operation timing, and command conversion.

**State Machine**:

| State | Description |
|-------|-------------|
| `STA_RET` | Reset state |
| `STA_IDL` | Idle, waiting for commands or maintenance requests |
| `ACT_CMD` / `ACT_WAT` | Execute ACT command |
| `RDA_CMD` / `RDA_WAT` | Execute read (with auto-precharge) |
| `WRA_CMD` / `WRA_WAT` | Execute write (with auto-precharge) |
| `REF_CMD` / `REF_WAT` | Execute refresh |
| `ZQS_CMD` / `ZQS_WAT` | Execute ZQ calibration |
| `VAT_CMD` / `VAT_WAT` | Execute VTT activation |
| `VRD_CMD` / `VRD_WAT` | Execute VTT read |

**Maintenance Operation Timing**:

- VTT: approximately `1 us`
- REF: approximately `6 us`
- ZQS: approximately `60 ms`

These are implemented through three watchdog counters: `vtt_watch_dog`, `ref_watch_dog`, and `zqs_watch_dog`, which trigger the corresponding command upon overflow.

**Key Logic**:

- ACT commands from the HostMC are not forwarded directly; instead, the target Rank/BG/BA and row address are recorded (`ActivatedRowMem`).
- RD/WR requests are converted into `ACT → RD/WR → PRE` sequences (with auto-precharge), keeping rows closed by default.
- Write commands are valid only when write data is ready (`fm_wrReq && wrdata_ready_cnt > 0`), as propagated from the top level.
- Invalid read data produced by VTT reads is discarded through the `rddata_ignore` signal sent to the read data buffer.
- Priority: maintenance commands (REF/ZQS/VTT) are higher than normal reads/writes to ensure timely response.
- Outputs various debug state signals for ILA observation.

---

### mig_phy_driver

**File**: `mig_phy_driver.v`

**Function**: Converts internal commands from the scheduler (`actReq`, `rdaReq`, `wraReq`, `refReq`, `zqsReq`, etc.) into the multi-cycle control signal format required by the MIG PHY.

**Main Outputs**:

- `mc_CS_n[15:0]`: chip select (only slot0 is used)
- `mc_ADR[135:0]`: address/command encoding
- `mc_BA[15:0]`, `mc_BG[15:0]`: bank addresses
- `mc_ACT_n[7:0]`: activate command
- `mc_CKE[15:0]`: fixed to all `1`
- `mcCasSlot`, `mcCasSlot2`: fixed to `0`
- `winRank`, `mcRdCAS`, `mcWrCAS`: read/write CAS indications

**Implementation**:

Pure combinational logic that selects the corresponding field based on command priority and generates signals in the repeated pattern of 8 bits per group required by MIG.

---

### wrdata_buffer

**File**: `wrdata_buffer.v`

**Function**: Converts 256-bit DFI write data from the HostMC into 512-bit burst data required by the MIG PHY.

**Data Path**:

`dfi_wrdata` (256 bit) → asynchronous FIFO → two 256-bit halves concatenated into 512 bits → synchronous FIFO → `mig_wrdata` (512 bit)

**Key Implementation**:

- Uses `wrtick_lo` and `wrtick_hi` flags to manage the reception of two half-beats.
- The write mask `dfi_wrdata_mask` (32 bit) is expanded to 64 bits and inverted at the output to match MIG polarity.
- Outputs `wrdata_filling` to indicate that data is being filled, for use by the top-level counter.

---

### rddata_buffer

**File**: `rddata_buffer.v`

**Function**: Splits 512-bit read data returned by the MIG PHY into two 256-bit parts and filters out invalid data generated by VTT reads.

**Data Path**:

`mig_rddata` (512 bit) → synchronous FIFO → split into lower 256 bits and upper 256 bits → asynchronous FIFO → `dfi_rddata` (256 bit)

**Key Implementation**:

- The `rddata_ignore` signal is used to discard VTT read data.
- The `RD_ERROR` signal is asserted when the DFI expects data but the asynchronous FIFO is empty, used to detect timing violations.
- Provides rich debug signals such as `debug_sync_fifo_*` and `debug_async_fifo_*`.

---

### async_fifo

**File**: `async_fifo.v`

**Function**: Asynchronous FIFO for cross-clock-domain data/command transfer.

**Features**:

- Gray-code pointer synchronization
- Two-stage synchronization to eliminate metastability
- Combinational read data output
- Configurable data width `DATA_WIDTH` and depth `DEPTH`

**Ports**:

- Write clock domain: `wr_clk`, `wr_rst_n`, `wr_en`, `wr_data`, `full`, `wr_ack`
- Read clock domain: `rd_clk`, `rd_rst_n`, `rd_en`, `rd_data`, `empty`, `rd_valid`

---

### sync_fifo

**File**: `sync_fifo.v`

**Function**: Synchronous FIFO for data buffering within the same clock domain.

**Features**:

- Binary read/write pointers
- Registered read data output
- Configurable data width `DATA_WIDTH` and depth `DEPTH`

**Ports**:

- `clk`, `rst_n`
- Write port: `wr_en`, `wr_data`, `full`, `wr_ack`
- Read port: `rd_en`, `rd_data`, `empty`, `rd_valid`

---

### delay_n

**File**: `delay_n.v`

**Function**: Variable delay line with configurable delay stages `N`.

**Usage**: Used to align control signals such as write enable or read enable.

**Implementation**: Shift register chain. When `N=0`, the signal passes through directly; when `N>=2`, the delayed signal is extracted from the shift register.

---

### mig_phy_odt

**File**: `mig_phy_odt.v`

**Function**: Simplified ODT waveform generator used to replace the official Xilinx `ddr4_v2_2_8_cal_mc_odt`.

**Features**:

- Produces a fixed-width ODT pulse only on write CAS
- Uses a 24-bit shift register to support pulse overlap
- Uses only ODT pin0; pin1 is fixed to `0`

**Ports**: `clk`, `rst_n`, `winWrite`, `mc_ODT[15:0]`

## Preset Timing Parameters

The following parameters are defined in `famsev2_ctrl.v` and should be adjusted according to the TargetPHY frequency and DDR specifications. These values are based on the assumptions of DDR4-1600, DFI 1:4, and `mig_clk` = 200 MHz. Many of them contain loose estimates and leave room for optimization. All values are counted in `mig_clk` cycles.

| Parameter Name | Value | Description |
| :------------: | :---: | :---------: |
| `WAIT_CNT_ACT` | 4 | ACT command wait time |
| `WAIT_CNT_RDA` | 18 | Read + auto-precharge wait time |
| `WAIT_CNT_WRA` | 13 | Write + auto-precharge wait time |
| `WAIT_CNT_REF` | 70 | Refresh wait time |
| `WAIT_CNT_ZQS` | 32 | ZQ calibration wait time |
| `WAIT_CNT_VAT` | 9 | VTT activation wait time |
| `WAIT_CNT_VRD` | 10 | VTT read wait time |
| `VTT_WATCH_DOG` | 187 | VTT trigger period (about 1 us) |
| `REF_WATCH_DOG` | 600 | REF trigger period (about 6 us) |
| `ZQS_WATCH_DOG` | 60000 | ZQS trigger period (about 60 ms) |

## Debugging and Verification

FATE contains multiple ILA debug IPs (such as `ila_ctrl`, `ila_famse_top`, `ila_afifo`, etc.) for observing key signals:

- State machine states (`debug_*_cmd`, `debug_*_wat`)
- Internal command requests (`fm_*`)
- FIFO empty/full status and read/write enables
- Read data error flag (`RD_ERROR`)

### Verification Suggestions:

- Use a simple `dfi_master` or `AXI Master` + commercial MC for module-level simulation;
- Verify timing accuracy (compare cycle counts with a commercial PHY);
- Integrate into a complete SoC (e.g., XiangShan processor + commercial MC) for full-system testing.

## Summary

The FATE design implements the core functions of a DDR PHY emulator: command parsing and buffering, scheduling arbitration, maintenance operation timing, data width conversion, and ODT control. Its low resource overhead and standard DFI interface make it easy to integrate into various FPGA-based pre-silicon evaluation platforms. The source code is clear, simple, and well-commented, making it suitable as a foundation for both academic research and industrial prototyping.