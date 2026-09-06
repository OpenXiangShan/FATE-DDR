/***************************************************************************************
* Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
* Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT，CAS)
* 
* YuQuan is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*   
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <stdio.h>
#include "platform.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xparameters.h"

#define LINE_WORDS 16U
#define LINE_BYTES (LINE_WORDS * 4U)   // 64 bytes

static inline UINTPTR align_line(UINTPTR addr)
{
    return addr & ~((UINTPTR)LINE_BYTES - 1U);
}

// 简单的 posted-write 收敛：flush 后读回一下同地址
static inline void bus_settle(UINTPTR addr)
{
    (void)Xil_In32(addr);
}

/**
 * @brief 强制“下一次读一定从外部内存填充这一整条 cache line”
 * 方式：InvalidateRange(整行) -> 读满 16 个 word（读 1 个就会触发 fill，但这里读满便于验证）
 */
static void read_cache_line(UINTPTR addr)
{
    UINTPTR line = align_line(addr);

    // 丢掉 cache 中该 line，保证后续读取走外部并触发 line fill
    Xil_DCacheInvalidateRange((INTPTR)line, LINE_BYTES);

    // 读完整条 line
    for (u32 i = 0; i < LINE_WORDS; i++) {
        UINTPTR a = line + (UINTPTR)(i * 4U);
        u32 v = Xil_In32(a);
        printf("read[%02lu] @0x%08lx = 0x%08lx\n",
               (unsigned long)i,
               (unsigned long)a,
               (unsigned long)v);
    }
}

/**
 * @brief 写满一条 cache line（16 words）并强制写回外部内存
 * 方式：写 16 个 word -> FlushRange(整行) -> 读回收敛
 */
static void write_cache_line(UINTPTR addr, u32 base_val)
{
    UINTPTR line = align_line(addr);

    // 写满整条 line
    for (u32 i = 0; i < LINE_WORDS; i++) {
        UINTPTR a = line + (UINTPTR)(i * 4U);
        Xil_Out32(a, base_val + i);
    }

    // 写回整条 line 到外部内存
    Xil_DCacheFlushRange((INTPTR)line, LINE_BYTES);

    // 防止 AXI posted write 还在路上，马上 invalidate/read 时看起来“慢一版”
    bus_settle(line);
}

void write_mc_reg();
void apb_write(u32 adress, u32 data);
u32 apb_read(u32 adress);

int main(void)
{
    init_platform();
    write_mc_reg();
    // 用来确认你确实跑到“新编译”的程序
    printf("build: %s %s\n", __DATE__, __TIME__);

    // 确保 cache 打开
    Xil_DCacheEnable();
//    Xil_ICacheEnable();

    const UINTPTR base   = 0x80000000U;
    const u32     nlines = 4U;               // 测 4 条 line
    const UINTPTR stride = (UINTPTR)LINE_BYTES;

    printf("\n=== Initial read (may show previous-run DDR contents) ===\n");
    for (u32 i = 0; i < nlines; i++) {
        printf("\n-- line %lu @0x%08lx --\n",
               (unsigned long)i,
               (unsigned long)(base + (UINTPTR)(i * stride)));
        read_cache_line(base + (UINTPTR)(i * stride));
    }

    printf("\n=== Write then read back ===\n");
    for (u32 i = 0; i < nlines; i++) {
        UINTPTR a = base + (UINTPTR)(i * stride);
        u32 pattern = 0xA0A02000U + i * 0x100U;  // 每条 line 不同基值，方便观察
        printf("\n-- write line %lu (base 0x%08lx) --\n",
               (unsigned long)i,
               (unsigned long)pattern);
        write_cache_line(a, pattern);
    }

    printf("\n=== Read after writeback (should match current patterns) ===\n");
    for (u32 i = 0; i < nlines; i++) {
        printf("\n-- line %lu @0x%08lx --\n",
               (unsigned long)i,
               (unsigned long)(base + (UINTPTR)(i * stride)));
        read_cache_line(base + (UINTPTR)(i * stride));
    }

    cleanup_platform();
    return 0;
}

void write_mc_reg()
{


	u32 rd_data;
	u32 rd_data_temp;
	apb_write(0x44A00000, 0x10620410);//tRRD_S = 4tck ,tRRD_L  = 6tck ,tFAW  = 32tck,tRCD   = 16tck,tRP = 16tck
	apb_write(0x44A00004, 0x0406161c);//tCCD_s = 4tck ,tCCD_L  = 6tck ,tWTR_S= 22tck,tWTR_L = 28tck
//		apb_write(0x44A00004, 0x0806161c);//tCCD_s = 8tck ,tCCD_L  = 6tck ,tWTR_S= 22tck,tWTR_L = 28tck
	apb_write(0x44A00008, 0x0a180a36);//tRTW   = 10tck,tWR     = 24tck,tRTP  = 10tck,tRAS   = 54tck
	apb_write(0x44A00014, 0x0800000c);//tphy_wrlat = 8tck,tphy_wrcslat = 0tck ,tphy_wrdata = 0tck ,trddata_en = 12tck
	apb_write(0x44A00028, 0x00000c08);//AL = 0tck,rl ,WL = 12 tck ,BL =8
	apb_write(0x44A00010, 0x00029680);//tRC = 650 , tZQCS = 128
	apb_write(0x44A00100, 0x00000000);//cache ctrl bit
	apb_write(0x44A00060, 0x0a0a0e0e); // diff rank paramters

	//MC initialization config
	apb_write(0x44A00040, 0x00100145);//dram_reset  and post_cke
	apb_write(0x44A00044, 0x00005018);//pre_cke and mrs2other
	apb_write(0x44A00048, 0x00008020);//mrs2mrs and tZQINIT
	apb_write(0x44A0004c, 0x00010A30);//mrs1 and mrs0
	apb_write(0x44A00050, 0x00000018);//mrs3 and mrs2
	apb_write(0x44A00054, 0x00400000);//mrs5 and mrs4
	apb_write(0x44A00058, 0x00000800);//mrs6
	apb_write(0x44A0002c, 0x00001d4c);//tREFI:7500 ns
	apb_write(0x44A00064, 0x00000001);//refresh mode(1:postponedRefresh,0:autoRefresh,2:speculativeRefresh)

//		rd_data = apb_read(0x44A00fff);
	//initialization start
	apb_write(0x44A00ff4, 0x00000001);//start MRS sequence

	rd_data = 0x0;
	rd_data_temp = 0;
	//read initialization end
	while(rd_data_temp == 0){
		rd_data = apb_read(0x44A0003c);
		rd_data_temp = rd_data;
		rd_data_temp = rd_data_temp;
	}
	//set MC ready
	apb_write(0x44A00034, 0x00000001);//gen

}
void apb_write(u32 adress, u32 data)
{
    Xil_Out32(adress ,data );
}

u32 apb_read(u32 adress)
{
    u32 data;
    data=Xil_In32(adress);
    return data;
}

