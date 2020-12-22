# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

# cannot commit files larger than 100 MB to GitHub 
FILE_SIZE_LIMIT_MB = 80
FILE_SIZE_SPLIT_MB = 80
LARGE_FILES := $(shell find ./gds -type f -name "*.gds")
LARGE_FILES += $(shell find . -type f -size +$(FILE_SIZE_LIMIT_MB)M \
	       -not -path "./.git/*" \
	       -not -path "./gds/*" \
	       -not -path "./openlane/*")

LARGE_FILES_XZ := $(addsuffix .xz, $(LARGE_FILES))
LARGE_FILES_XZ_PART := $(addsuffix .part, $(LARGE_FILES_XZ))

# These are compressed (.xz) and split (.part*) archives.
ARCHIVES_XZ_PART := $(shell find . -type f -name "*.xz.part*")

# These are the name of the .xz archives to restore by joining split parts.
ARCHIVES_XZ := $(sort $(basename $(ARCHIVES_XZ_PART)))

# These are names of the .gds files to restores from the compressed and split
# archives.
ARCHIVED := $(sort $(basename $(ARCHIVES_XZ)) $(basename $(shell find . -type f -name "*.xz")))

ARCHIVES := $(shell find . -type f -name "*.gz")
ARCHIVE_SOURCES := $(basename $(ARCHIVES))

# PDK setup configs
THREADS ?= $(shell nproc)
STD_CELL_LIBRARY ?= sky130_fd_sc_hd
SPECIAL_VOLTAGE_LIBRARY ?= sky130_fd_sc_hvl
IO_LIBRARY ?= sky130_fd_io
SKYWATER_COMMIT ?= 3d7617a1acb92ea883539bcf22a632d6361a5de4
OPEN_PDKS_COMMIT ?= 32cdb2097fd9a629c91e8ea33e1f6de08ab25946

.DEFAULT_GOAL := ship

.PHONY: print_vars
print_vars:
	@echo "LARGE_FILES         = $(LARGE_FILES)"
	@echo "LARGE_FILES_XZ      = $(LARGE_FILES_XZ)"
	@echo "LARGE_FILES_XZ_PART = $(LARGE_FILES_XZ_PART)"
	@echo "ARCHIVES_XZ_PART    = $(ARCHIVES_XZ_PART)"
	@echo "ARCHIVES_XZ         = $(ARCHIVES_XZ)"
	@echo "ARCHIVED            = $(ARCHIVED)"

# We need portable GDS_FILE pointers...
.PHONY: ship
ship: check-env uncompress
	@echo "###############################################"
	@echo "Generating Caravel GDS (sources are in the 'gds' directory)"
	@sleep 1
	@cp gds/caravel.gds gds/caravel.old.gds && echo "Copying old Caravel to gds/caravel.old.gds" || true
	@cd gds && MAGTYPE=mag magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/current/sky130A.magicrc -noc -dnull gen_caravel.tcl < /dev/null



.PHONY: clean
clean:
	echo "clean"



.PHONY: verify
verify:
	echo "verify"
	cd verilog/dv/caravel/fpga_250 && make clean && make

$(LARGE_FILES_XZ_PART): %.xz.part: %
	@xz --extreme --force --threads=$(THREADS) $< && \
	split -b $(FILE_SIZE_SPLIT_MB)M $(addsuffix .xz, $<) $@ && \
	rm $<.xz && \
	echo "$< -> $$(find . -wholename '*$<*' | xargs)"

# This target compresses all files larger than $(FILE_SIZE_LIMIT_MB) MB
.PHONY: compress
compress: $(LARGE_FILES_XZ_PART)
	@echo "Files larger than $(FILE_SIZE_LIMIT_MB) MBytes are compressed and split!"

$(ARCHIVES_XZ):

$(ARCHIVED): $(ARCHIVES_XZ)
	@export PARTS="$(sort $(wildcard $@.xz.par*))" && \
	cat $${PARTS} > $@.xz && \
	unxz --force --threads=$(THREADS) $@.xz && \
	rm $${PARTS} && \
	echo "$${PARTS} -> $@"

.PHONY: uncompress
uncompress: $(ARCHIVED)
	@echo "All files are concatenated and uncompressed!"

.PHONY: decompress
decompress: uncompress


# LVS
BLOCKS = $(shell cd openlane && find * -maxdepth 0 -type d)
LVS_BLOCKS = $(foreach block, $(BLOCKS), lvs-$(block))
$(LVS_BLOCKS): lvs-% : ./mag/%.mag ./verilog/gl/%.v
	echo "Extracting $*"
	mkdir -p ./mag/tmp
	echo "load $* -dereference;\
		extract no all;\
		extract do local;\
		extract;\
		ext2spice lvs;\
		ext2spice;\
		feedback save extract_$*.log;\
		exit;" > ./mag/extract_$*.tcl
	cd mag && MAGTYPE=maglef magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/current/sky130A.magicrc -noc -dnull extract_$*.tcl
	mv ./mag/$*.spice ./spi/lvs
	mv -f ./mag/extract_$*.{tcl,log} ./mag/*.ext ./mag/tmp
	####
	mkdir -p ./spi/lvs/tmp
	sh ./spi/lvs/run_lvs.sh ./verilog/gl/$*.v ./spi/lvs/$*.spice $*
	mv -f ./spi/lvs/*{.out,.json,.log} ./spi/lvs/tmp 2> /dev/null || true
	

.PHONY: help
help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

		
###########################################################################
.PHONY: pdk
pdk: skywater-pdk skywater-library open_pdks build-pdk

$(PDK_ROOT)/skywater-pdk:
	git clone https://github.com/google/skywater-pdk.git $(PDK_ROOT)/skywater-pdk

.PHONY: skywater-pdk
skywater-pdk: check-env $(PDK_ROOT)/skywater-pdk
	cd $(PDK_ROOT)/skywater-pdk && \
		git checkout master && git pull && \
		git checkout -qf $(SKYWATER_COMMIT)

.PHONY: skywater-library
skywater-library: check-env $(PDK_ROOT)/skywater-pdk
	cd $(PDK_ROOT)/skywater-pdk && \
		git submodule update --init libraries/$(STD_CELL_LIBRARY)/latest && \
		git submodule update --init libraries/$(IO_LIBRARY)/latest && \
		git submodule update --init libraries/$(SPECIAL_VOLTAGE_LIBRARY)/latest && \
		$(MAKE) -j$(THREADS) timing

### OPEN_PDKS
$(PDK_ROOT)/open_pdks:
	git clone https://github.com/RTimothyEdwards/open_pdks.git $(PDK_ROOT)/open_pdks

.PHONY: open_pdks
open_pdks: check-env $(PDK_ROOT)/open_pdks
	cd $(PDK_ROOT)/open_pdks && \
		git checkout master && git pull && \
		git checkout -qf $(OPEN_PDKS_COMMIT)

.PHONY: build-pdk
build-pdk: check-env $(PDK_ROOT)/open_pdks $(PDK_ROOT)/skywater-pdk
	[ -d $(PDK_ROOT)/sky130A ] && \
		(echo "Warning: A sky130A build already exists under $(PDK_ROOT). It will be deleted first!" && \
		sleep 5 && \
		rm -rf $(PDK_ROOT)/sky130A) || \
		true
	cd $(PDK_ROOT)/open_pdks && \
		./configure --with-sky130-source=$(PDK_ROOT)/skywater-pdk/libraries --with-sky130-local-path=$(PDK_ROOT) && \
		cd sky130 && \
		$(MAKE) veryclean && \
		$(MAKE) && \
		$(MAKE) install-local

.RECIPE: manifest
manifest:
	cd verilog/rtl/ && \
	find * -type f ! -name "user_*.v" ! -name "manifest" ! -name "README" ! -name "defines.v" -exec shasum {} \; > manifest && \
	cd ../../maglef/ && \
	shasum *.mag > manifest && \
	cd ../mag/ && \
	shasum caravel.mag .magicrc > manifest


check-env:
ifndef PDK_ROOT
	$(error PDK_ROOT is undefined, please export it before running make)
endif
