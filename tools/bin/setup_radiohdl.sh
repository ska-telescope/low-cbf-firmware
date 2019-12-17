#!/bin/bash
###############################################################################
#
# Copyright (C) 2016
# ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
# P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

# Only run this script once
if [ -z "${LOWCBF_SH}" ]; then
  export LOWCBF_SH=true
  echo "Setup RadioHDL environment for LOWCBF"

  # 1) Usage

  # Define $SVN in .bashrc
  # Source this script in the .bashrc to setup the RadioHDL environment for Modelsim and Quartus.


  # 2) Setup

  if [ "${SITE-}" = "ASTRON" ]; then
    export RADIOHDL=${SVN}
    export VIVADO_PATH=/home/software/Xilinx/Vivado
    export VIVADO_SDK_PATH=/home/software/Xilinx/SDK
    export MODEL_TECH_XILINX_LIB=/home/software/modelsim_xilinx_libs/vivado
    export MODELSIM_PATH=/home/software/Mentor
  else
    export RADIOHDL=${SVN}
    export VIVADO_PATH=/opt/Xilinx/Vivado
    export VIVADO_SDK_PATH=/opt/Xilinx/SDK
    export MODEL_TECH_XILINX_LIB=
  fi

  export HDL_BUILD_DIR=${RADIOHDL}/build

  # Read generic functions/definitions
  . ${RADIOHDL}/tools/generic.sh

  # Python Environment
  export PYTHONPATH=${RADIOHDL}/tools/radiohdl/base:${RADIOHDL}/tools/args

  # Add search paths for executeables to $PATH
  export PATH=${PATH}:${RADIOHDL}/tools/quartus:${RADIOHDL}/tools/vivado:${RADIOHDL}/tools/modelsim:${RADIOHDL}/tools/radiohdl/base

fi
