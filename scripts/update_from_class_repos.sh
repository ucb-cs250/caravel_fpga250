#!/bin/bash

# TODO(aryap): Get source of current script, etc.
CARAVEL_ROOT=.
CLASS_REPO_ROOT=/home/arya/src/openlane_develop/designs/250
FPGA_RUN=8x7_2wb_noring_20x20buf_nocts
USER_PROJECT_WRAPPER_RUN=user_project_wrapper

PHY_SOURCE="${CLASS_REPO_ROOT}/asic_config/fpga/runs/${FPGA_RUN}/results/magic"
#PHY_SOURCE="${CLASS_REPO_ROOT}/gds/fpga"

# Update final GDS, LEF, MAG, etc.
for file_type in lef gds mag; do
  cp -v "${PHY_SOURCE}/fpga.${file_type}" "${CARAVEL_ROOT}/${file_type}";
done

# Gate-level synthesis.
GL_USER_PROJECT_WRAPPER="${CARAVEL_ROOT}/openlane/user_project_wrapper/runs/${USER_PROJECT_WRAPPER_RUN}/results/synthesis/user_project_wrapper.v"
GL_SOURCE="${CLASS_REPO_ROOT}/asic_config/fpga/runs/${FPGA_RUN}/results/fpga.synthesis.v"
GL_DEST="${CARAVEL_ROOT}/verilog/gl/user_project_wrapper.v"
cat ${GL_SOURCE} ${GL_USER_PROJECT_WRAPPER} > ${GL_DEST}

# Update Verilog source files from team repos.
