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

echo "Run quartus_generic.sh"

# Derive generic Quartus tool version related paths from $QUARTUS_DIR that gets defined in quartus_version.sh
# Quartus, SOPC, Nios
export QUARTUS_ROOTDIR=${QUARTUS_DIR}/quartus
export QUARTUS_ROOTDIR_OVERRIDE=${QUARTUS_DIR}/quartus
export NIOSDIR=${QUARTUS_DIR}/nios2eds
export SOPC_KIT_NIOS2=${NIOSDIR}

# Add to the $PATH, only once to avoid double entries
pathadd ${QUARTUS_ROOTDIR}/bin
pathadd ${QUARTUS_ROOTDIR}/sopc_builder/bin
pathadd ${NIOSDIR}/bin
pathadd ${NIOSDIR}/bin/gnu/H-i686-pc-linux-gnu/bin
pathadd ${NIOSDIR}/bin/gnu/H-x86_64-pc-linux-gnu/bin
pathadd ${NIOSDIR}/sdk2/bin

# Qsys
export ALTERA_HW_TCL_KEEP_TEMP_FILES=1

# User synthesis timestamp in FPGA image
export UNB_COMPILE_STAMPS=1
export RADIOHDL_SVN_REVISION=`svn info ${RADIOHDL} | grep Revision`
