#!/bin/bash

# ===================== 配置部分 =====================
BUILD_DIR="./build"
TOP_MODULE="sync_fifo_tb"
VCS_FILES="sync_fifo.v sync_fifo_tb.v"

# ===================== 1. 清理旧文件 =====================
echo "Cleaning old files..."
rm -rf $BUILD_DIR 64 simv.daidir csrc simv ucli.key wave.vcd wave.fsdb

# ===================== 2. 创建build目录 =====================
echo "Creating build directory: $BUILD_DIR"
mkdir -p $BUILD_DIR

# ===================== 3. 复制源文件到build目录（关键！） =====================
echo "Copying source files to build directory..."
cp $VCS_FILES $BUILD_DIR/

# ===================== 4. 进入build目录运行VCS =====================
echo "Starting VCS compilation in build directory..."
cd $BUILD_DIR

vcs -sverilog \
    -debug_acc+all \
    -kdb \
    -timescale=1ns/1ps \
    -full64 \
    $VCS_FILES \
    -o simv

# 检查编译是否成功
if [ $? -ne 0 ]; then
    echo "ERROR: VCS compilation failed!"
    exit 1
fi

echo "VCS compilation successful!"

# ===================== 5. 运行仿真 =====================
echo "Starting simulation..."
./simv

if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed!"
    exit 1
fi

echo "Simulation successful!"
echo "All generated files are in: $BUILD_DIR"
