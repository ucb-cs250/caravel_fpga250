#!/bin/bash

# TODO(aryap): Get source of current script, etc.
CARAVEL_ROOT=.
CLASS_REPO_ROOT=/home/arya/src/openlane_develop/designs/250
FPGA_RUN=8x6_2wb

#SOURCE="${CLASS_REPO_ROOT}/asic_config/fpga/runs/${FPGA_RUN}/results/magic"
SOURCE="${CLASS_REPO_ROOT}/gds/fpga"

# Update final GDS, LEF, MAG, etc.
for file_type in lef gds mag; do
  cp -v "${SOURCE}/fpga.${file_type}" "${CARAVEL_ROOT}/${file_type}";
done

# Update Verilog source files from team repos.
