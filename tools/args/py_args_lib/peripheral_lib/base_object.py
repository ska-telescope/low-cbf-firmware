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
# Author  Date
#   HJ    jan 2017  Original
#   EK    feb 2017
#   PD    feb 2017
#
###############################################################################
import logging
import re
import sys
from py_args_lib import unit_logger
from args_errors import ARGSNameError

logger = logging.getLogger('main.base_object')



class BaseObject(object):
    def __init__(self):
        self.success            = True
        self._name              = ""
        self._user_defined_name = None
        self._prefix            = ""
        self._args = {}

    def update_args(self, args):
        """ update self._args with all kv pairs in args """
        self._args.update(args)

    def _as_str(self, key, default=None):
        """ look in settings for key, if available return value as string,
        if key not available retur default """
        try:
            val = str(self._args[key])
            return val
        except KeyError:
            return default

    def _as_int(self, key, default=None):
        """ look in settings for key, if available return value as int if possible
        otherwise return string, if key not available retur default """
        try:
            val = int(self._args[key]) #int(self._args.get(key,None))#
            return val
        except ValueError:
            # logger.error("Invalid value for {}".format(key))
            # sys.exit()
            return self._args[key]
        except KeyError:
            return default

    def set_kv(self, key, val):
        """ set_kv()
        if key in valid keys, update key with given value, if key not excists add it.
        """
        if val is not None:
            self._args[key] = val
            return True
        return False

    def get_kv(self, key, dtype=None):
        """ get_kv()
        return value for given key, if key in valid keys, else return None
        """
        if key not in self._args.keys():
            logger.error("key not in arguments %s", key)
            return None
        if dtype == 'int':
            return self._as_int(key)
        if dtype == 'string':
            return self._as_str(key)
        return self._args[key]

    def name(self, val=None):
        """ set/get name """
        error = 0
        if val is not None:
            if isinstance(val, int):
                logger.error("BaseObject.name(), Name string \'%s\' evaluated to an int. \n\n\tAny of the following name strings: true/false/yes/no/on/off must be wrapped in quotation marks.\n \tName strings cannot begin with a numeric character", val)
                error = 1
            elif re.compile('[0-9]').match(str(val)):
                logger.error("BaseObject.name(), Name string \'%s\' violates ARGS naming rules. Name strings cannot begin with a numeric character.", val)
                error = 1
            elif re.compile('\W').search(str(val)):
                logger.error("BaseObject.name(), Name string \'%s\' violates ARGS naming rules. Name strings cannot contain non-alphanumeric characters.",val)
                error = 1
            if isinstance(val, str) and len(val) > 25:
                # logger.warning("BaseObject.name(), Name string \'%s\' is longer than 25 chars (%d). \nXilinx recommends 16 chars for signal and instance names, whenever possible", val, len(val))
                error = 0
            if isinstance(val, str) and len(val) < 1:
                logger.error("Name string must be at least 1 chars")
                error = 1

            if error == 1 :
                raise ARGSNameError

            self._name = val.lower()
            return
        return self._name

    def user_defined_name(self, val=None):
        """ set/get user_defined_name """
        if val is not None:
            self._user_defined_name = val
            return
        return self._user_defined_name

    def prefix(self, val=None):
        """ set/get prefix """
        if val is not None:
            self._prefix = val
            return
        return self._prefix
