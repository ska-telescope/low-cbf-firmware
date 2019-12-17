#!/bin/bash
###############################################################################
#
# Copyright (C) 2014
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

echo "Run vivado_generic.sh"

# Derive generic Vivado tool version related paths from $VIVADO_DIR that gets defined in vivado_version.sh

export XILINX_VIVADO=${VIVADO_DIR}
pathadd ${XILINX_VIVADO}/bin
pathadd ${VIVADO_SDK_DIR}/bin

# User synthesis timestamp in FPGA image
export RADIOHDL_GIT_REVISION=`git rev-parse HEAD`
