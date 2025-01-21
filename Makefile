
# https://github.com/rockchip-linux/kernel 源码目录
# KERNEL_DIR := ../kernel
KERNEL_DIR := ../../rockchip-linux/kernel

# kernel 源码中的 dts 文件目录
REF_DTS_DIR := $(KERNEL_DIR)/arch/arm64/boot/dts/rockchip

# 从 kernel 源码中拿来作为参考的 dts 文件名列表
REF_DTS_NAME_LIST := rk3399-sapphire-excavator-edp.dts rk3399-sapphire-excavator-linux.dts

# 输入数据放到下面这两个目录中：

# 存放 dump 出来的 dtb 文件的目录
DUMP_DIR := ./dump
# 存放 dump 出来魔改过的 dts 文件的目录
MOD_DIR := ./mod

# build 目录
BUILD_DIR := ./build

# 来源于 kernel 源码编译出的 *.rb.p.yaml 文件的目录。主要用来对比相同机型 Android 版和 Linux 版的差异。
BUILD_REF_DIR := $(BUILD_DIR)/ref

# build/ref 目录中的文件扩展名解释：
# .pp.dts: dts 预处理 include 后的文件
# .pp.dtb: dts 预处理 include 后的文件编译成 dtb 文件
# .pp.yaml: dts 预处理 include 后的文件转换为 yaml 文件（用于提取 node 类型信息）
# .type.yaml: .pp.yaml 提取出的 node 类型表
# .rb.dts: .pp.dtb 反编译出的 dts 文件
# .rb.yaml: .pp.dtb 反编译出的 yaml 文件
# .rb.pmap: .pp.dtb 反编译出的 yaml 文件提取出的 phandle map 文件
# .rb.p.yaml: .rb.yaml 文件解析 phandle 路径后的 yaml 文件

REF_DTS_LIST := $(patsubst %,$(REF_DTS_DIR)/%,$(REF_DTS_NAME_LIST))
REF_PP_DTS_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.pp.dts,$(REF_DTS_NAME_LIST))
REF_PP_YAML_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.pp.yaml,$(REF_DTS_NAME_LIST))
TYPE_YAML_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.type.yaml,$(REF_DTS_NAME_LIST))
REF_PP_DTB_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.pp.dtb,$(REF_DTS_NAME_LIST))
REF_RB_DTS_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.rb.dts,$(REF_DTS_NAME_LIST))
REF_RB_YAML_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.rb.yaml,$(REF_DTS_NAME_LIST))
REF_RB_PMAP_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.rb.pmap,$(REF_DTS_NAME_LIST))
REF_RB_P_YAML_LIST := $(patsubst %.dts,$(BUILD_REF_DIR)/%.rb.p.yaml,$(REF_DTS_NAME_LIST))

# 合并所有的 node 类型表
COMBINED_TYPE_YAML := $(BUILD_DIR)/combined.type.yaml

# 来源于 dump dtb 编译出的 *.p.yaml 文件的目录。主要用来对比魔改过的 dts 文件和原始 dtb 文件、其它可运行的 dtb 的差异。
BUILD_DUMP_DIR := $(BUILD_DIR)/dump

# build/dump 目录中的文件扩展名解释：
# .dts: dtb 反编译出的 dts 文件
# .yaml: dtb 反编译出的 yaml 文件
# .pmap: yaml 文件提取出的 phandle map 文件
# .p.yaml: yaml 文件解析 phandle 路径后的 yaml 文件

DUMP_DTB_LIST := $(wildcard $(DUMP_DIR)/*.dtb)
ORI_DTS_LIST := $(patsubst $(DUMP_DIR)/%.dtb,$(BUILD_DUMP_DIR)/%.dts,$(DUMP_DTB_LIST))
ORI_YAML_LIST := $(patsubst $(DUMP_DIR)/%.dtb,$(BUILD_DUMP_DIR)/%.yaml,$(DUMP_DTB_LIST))
ORI_PMAP_LIST := $(patsubst $(DUMP_DIR)/%.dtb,$(BUILD_DUMP_DIR)/%.pmap,$(DUMP_DTB_LIST))
ORI_P_YAML_LIST := $(patsubst $(DUMP_DIR)/%.dtb,$(BUILD_DUMP_DIR)/%.p.yaml,$(DUMP_DTB_LIST))

MOD_DTS_LIST := $(wildcard $(MOD_DIR)/*.dts)
MOD_YAML_LIST := $(patsubst $(MOD_DIR)/%.dts,$(BUILD_DUMP_DIR)/%.yaml,$(MOD_DTS_LIST))
MOD_PMAP_LIST := $(patsubst $(MOD_DIR)/%.dts,$(BUILD_DUMP_DIR)/%.pmap,$(MOD_DTS_LIST))
MOD_P_YAML_LIST := $(patsubst $(MOD_DIR)/%.dts,$(BUILD_DUMP_DIR)/%.p.yaml,$(MOD_DTS_LIST))

BUILD_MOD_DIR := $(BUILD_DIR)/mod

MOD_RELEASE_LIST := $(patsubst $(MOD_DIR)/%.dts,$(BUILD_MOD_DIR)/%.dtb,$(MOD_DTS_LIST))

# 生成所有的文件
all: $(REF_RB_P_YAML_LIST) $(ORI_P_YAML_LIST) $(MOD_P_YAML_LIST)

# 编译魔改的 dts 为 dtb
release: $(MOD_RELEASE_LIST)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all release clean

# 使用 .SECONDARY 保护所有中间文件
.SECONDARY: \
	$(REF_PP_DTS_LIST) \
	$(REF_PP_YAML_LIST) \
	$(TYPE_YAML_LIST) \
	$(REF_PP_DTB_LIST) \
	$(REF_RB_DTS_LIST) \
	$(REF_RB_YAML_LIST) \
	$(REF_RB_PMAP_LIST) \
	$(ORI_DTS_LIST) \
	$(ORI_YAML_LIST) \
	$(ORI_PMAP_LIST) \
	$(MOD_YAML_LIST) \
	$(MOD_PMAP_LIST)

# dtsi 文件的 include 路径
CPP_INCLUDE := -I $(KERNEL_DIR)/include -I $(REF_DTS_DIR)

# dts 预处理 include 的规则
$(BUILD_REF_DIR)/%.pp.dts: $(REF_DTS_DIR)/%.dts $(BUILD_REF_DIR)
	cpp -nostdinc $(CPP_INCLUDE) -undef -x assembler-with-cpp $< -o $@

# dts 转换为 YAML 的规则
%.yaml: %.dts
	dtc -I dts -O yaml $< -o $@

# 特别的，对于 mod 目录中 dts 转换为 YAML 的规则
$(BUILD_DUMP_DIR)/%.yaml: $(MOD_DIR)/%.dts $(BUILD_DUMP_DIR)
	dtc -I dts -O yaml $< -o $@

# 从 pp.yaml 中提取 node 类型的规则
%.type.yaml: %.pp.yaml
	python3 ./scripts/extract_dts_type.py $@ $<

# dts 编译为 dtb 的规则
%.pp.dtb: %.pp.dts
	dtc -I dts -O dtb $< -o $@

# 特别的，对于魔改的 dts 编译为 dtb 的规则
$(BUILD_MOD_DIR)/%.dtb: $(MOD_DIR)/%.dts $(BUILD_MOD_DIR)
	dtc -I dts -O dtb $< -o $@

# dtb 反编译为 dts 的规则
%.rb.dts: %.pp.dtb
	dtc -I dtb -s -O dts $< -o $@

# 特别的，对于 dump 出来的 dtb 反编译为 dts 的规则
$(BUILD_DUMP_DIR)/%.dts: $(DUMP_DIR)/%.dtb $(BUILD_DUMP_DIR)
	dtc -I dtb -s -O dts $< -o $@

# 从 yaml 中提取 phandle map 的规则
%.pmap: %.yaml
	python3 ./scripts/extract_phandle_map.py $@ $<

# 合并所有的 node 类型表
$(COMBINED_TYPE_YAML): $(TYPE_YAML_LIST)
	python3 ./scripts/combine_dts_type.py $@ $(TYPE_YAML_LIST)

# 给 YAML 文件解析 phandle 路径的规则
%.p.yaml: %.yaml %.pmap $(COMBINED_TYPE_YAML)
	python3 ./scripts/resolve_dts_phandle.py $@ $^

# 创建目录规则
$(BUILD_REF_DIR) $(BUILD_DUMP_DIR) $(BUILD_MOD_DIR):
	mkdir -p $@
