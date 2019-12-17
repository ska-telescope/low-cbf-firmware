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

MODELSIM_VERSION=${1}
echo "Select Modelsim version: ${MODELSIM_VERSION}"

## First modelsim 6.6c,f was stored at /modeltech, subsequent versions are stored at their /<version number>/modeltech
MODELSIM_VERSION_DIR=${MODELSIM_VERSION}
#if [ "${MODELSIM_VERSION}" = "6.6c" ]; then
#  MODELSIM_VERSION_DIR=""
#fi

# Must not define MODEL_TECH, because it gets defined when the tool starts. Therefore define MODEL_TECH_DIR to denote the modeltech version directory
if [ "${MODELSIM_VERSION}" = "10.4" ]; then
    export MODEL_TECH_DIR=/home/software/Mentor/${MODELSIM_VERSION_DIR}/questasim
else
    export MODEL_TECH_DIR=/home/software/Mentor/${MODELSIM_VERSION_DIR}/modeltech
fi
export VSIM_DIR=$MODEL_TECH_DIR/linux_x86_64
