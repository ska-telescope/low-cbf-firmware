#!/bin/bash
###############################################################################
#
# Copyright (C) 2015
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
# . Extract fMax from Timequest report file
# Usage:
# . $ quartus_fmax [project].sta.rpt [clk]
# . [clk] is the full path of the clock of interest; copy/paste this from Timequest GUI.


if [ ! -z $1 ] 
then 
    # $1 was given
    RPT_FILE=$1
else
    : # $1 was not given
    echo 'Pass a .sta.rpt file as first argument.'
    exit 1
fi

if [ ! -z $2 ] 
then 
    : # $2 was given
    CLK=$2
else
    : # $2 was not given
    echo 'Pass (part of) the clock path as second argument.'
    exit 1
fi




nof_clk=`awk '/; Slow 900mV 85C Model Fmax Summary/,/This panel reports FMAX/' $RPT_FILE | grep -c $CLK`

if [ $nof_clk = 0 ] 
then
    echo 'Clock not found; check provided clock path'
    exit 1
elif [ $nof_clk -gt 1 ]
then
    echo 'Multiple clocks found; check provided clock path.'
    exit 1
else
    # Good; only one clock found mathing user passed clk path.
    awk '/; Slow 900mV 85C Model Fmax Summary/,/This panel reports FMAX/' $RPT_FILE | grep $CLK | cut -d';' -f2
fi


