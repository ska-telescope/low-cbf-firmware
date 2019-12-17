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

# Purpose:
# . Extract columns of interest from Quartus fitter report file
# Description:
# . Awk extracts the lines of interest: the resource utilization block
# . Cut is used to select the right columns (fields -f)
#   . columns are delimited by ';'
# . Grep is used to extract hierarchical levels up to a certain depth:
#   . Top level  line starts with ' |'
#   . One level  down starts with '    |'
#   . Two levels down starts with '       |'
#   . The grep argument used to remove lines (e.g. '   |' is stored
#     in REMOVE_LINES.

if [ ! -z $1 ] 
then 
    # $1 was given
    DEPTH=$1
else
    : # $1 was not given
    echo 'Execute this in the path of a .fit.rpt file.'
    echo 'Usage: ./resources.sh depth columns'
    echo '. Example: ./resources.sh 2 9,10,11,12'
    echo '. depth = n (n=1..max depth): required'
    echo '. columns = 2,3,4,..: optional'
    echo '  . Columns:'
#    echo '    .  2 - Compilation Hierarchy Node' # always selected
    echo '    .  3 - Combinational ALUTs'
    echo '    .  4 - Memory ALUTs'
    echo '    .  5 - LUT_REGs'
    echo '    .  6 - ALMs'
    echo '    .  7 - Dedicated Logic Registers'
    echo '    .  8 - I/O Registers'
    echo '    .  9 - Block Memory Bits'
    echo '    . 10 - M9Ks'
    echo '    . 11 - M144Ks'
    echo '    . 12 - DSP 18-bit Elements'
    echo '    . 13 - DSP 9x9'
    echo '    . 14 - DSP 12x12'
    echo '    . 15 - DSP 18x18'
    echo '    . 16 - DSP 36x36'
    echo '    . 17 - Pins'
    echo '    . 18 - Virtual Pins'
    echo '    . 19 - Combinational with no register ALUT/register pair'
    echo '    . 20 - Register-Only ALUT/register pair'
    echo '    . 21 - Combinational with a register ALUT/register pair'
    echo '    . 22 - Full Hierarchy Name'
    echo '    . 23 - Library Name '
    echo
    echo 'Use grep to get only the info you want.'
    exit 1
fi

if [ ! -z $2 ] 
then 
    : # $2 was given
    COLUMNS=$2
else
    : # $2 was not given
    COLUMNS=3,4,5,6,78,9,10,11,12,13,14,15,16
fi

RPT_FILE_COUNT=`ls -1 *.fit.rpt 2>/dev/null | wc -l`
if [ $RPT_FILE_COUNT = 0 ] 
then
    echo 'No .fit.rpt file found!'
    exit 1
fi

RPT_FILE=*.fit.rpt
NOF_SPACES=$(expr 3 \* $DEPTH - 2) # nof_spaces = 3*DEPTH-2
REMOVE_LINES=`for i in $(eval echo {0..$NOF_SPACES}); do echo -n ' '; done`'|'

# print the rouseource utilization block only                     | only columns of interest | no long rows of dashes | X levels deep           | remove the first long line
awk '/; Fitter Resource Utilization by Entity/,/Note:/' $RPT_FILE | cut -d';' -f2,$COLUMNS   | grep ';'               | grep -v "$REMOVE_LINES" | grep -v 'Resource Utilization'

exit 0
