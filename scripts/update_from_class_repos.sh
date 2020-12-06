#!/bin/bash

# TODO(aryap): Get source of current script, etc.
CARAVEL_ROOT=.
CLASS_REPO_ROOT=/home/arya/src/openlane_develop/designs/250
FPGA_RUN=debug

# Update final GDS, LEF, MAG, etc.
for type in lef gds mag; do
  cp -v "${CLASS_REPO_ROOT}/asic_config/fpga/runs/${FPGA_RUN}/results/magic/fpga.${type}" "${CARAVEL_ROOT}/${type}";
done

# Update Verilog source files from team repos.
