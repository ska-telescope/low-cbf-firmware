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

"""Common class for accessing a Python dictionary in one or more files

   The contents of the dictionary file consist of a series of key - value
   pairs. These key - value pairs are read from the file and kept in a
   single dictionary of keys and values.

   The format of the dictionary file is similar to that of an ini file. For ini
   files Python has the ConfigParser package, but that is not used here because
   the ini file specification is not very strict. The parsing can be done in
   a single method read_dict_file() that gives more freedom for interprating
   the ini file.

   Like an ini file the dictionary can contain one or more sections. The first
   section is common, has no header and always included. The specific sections
   have a header that is marked by [section header]. The square brackets '['
   and ']' are used to identify the section header. If the 'section header' is
   included in the object argument fileSections list then the keys of that
   section will be included in the dictionary.

     'fileSections' = None  --> ignore fileSections to include all sections in
                                the dict.
     'fileSections' = []    --> empty list to include only the common first
                                section in the dict.
     'fileSections' = ['section header' ...] -->
                                dedicated list of one or more section header
                                strings to include these specific sections,
                                and also the common first section, in the
                                dict.

   The key and value string in the dictionary file are separated by '='. Hence
   the '=' character can not be used in keys. The '=' can be used in values,
   because subsequent '=' on the same line are part of the value.
   Every key must start on a new line. The value string can extend over one
   or multiple lines.

   Comment in line is supported by preceding it with a '#'. The '#' and the
   text after it on the line are stripped. The remainder of the line before
   the '#' is still interpreted.

     # This is a comment section
     # a key starts on a new line and extends until the '='
     # a key and its values are separated by '='

     key=string   # this is a comment and the key is still interpreted
     key=string
     key =string
     key = string

     # a key with multiple values in its string
     key = value value value

     # how the values are separated depends on the dictionary user
     key = value, value, value
     key = value value

     # a key with many values can have its string extend on multiple lines,
     # the newline is replaced by a ' ' and any indent is removed
     key =
     value
     value
     value

     # empty lines and spaces are allowed
     key = value

   Whether the key is a valid key depends on the dict user that interprets
   the dictionary.

   The information about the <fileName> ini files is kept in parallel lists.
   First all filePaths to the fileName ini files are found within the rooDir
   tree and kept in two parallel lists of filePaths and filePathsNames. Then
   the ini files are read and kept in a parallel list of dicts. Iherefore it
   is important that the indexing of parallel lists remains intact at all
   times.

   It can be useful to be able to refer to the dicts based on a certain key
   value, e.g. a key value that gives the name of the dict. The methods
   get_key_values() and get_dicts() provide a means to easily link a dict
   to its name and its name to the dict. The argument and the return can be
   a list or a single value. Default the init list of self.dicts is used as
   argument.

   'fileName'     = the name of the dictionary file including extension
   'filePath'     = the full directory name where the dictionary file is
                    stored
   'filePathName' = filePath/fileName

"""

import common as cm
import sys
import os
import os.path
import collections
import re

class CommonDictFile:

    def __init__(self, rootDir, fileName='dict.txt', fileSections=None):
        """Store the dictionaries from all fileName files in rootDir."""
        self.CDF_COMMENT = '#'
        self.CDF_SEPARATOR = '='
        self.rootDir = rootDir
        self.fileName = fileName                            # all dictionary files have the same fileName
        self.filePaths = self.find_all_dict_file_paths()    # list of all directory paths of dictionary files that are available in the rootDir tree
        if len(self.filePaths)==0:
            sys.exit('Error : No %s file found in %s directory tree.' % (fileName, rootDir))
        self.filePathNames = []                             # list of all directory paths + fileName of the available dictionary files
        for path in self.filePaths:
            self.filePathNames.append(os.path.join(path, self.fileName)) # tcl only recognises posix paths not nt
        self.fileSections = fileSections                    # specific dictionary file sections to include in the dict
        self.dicts = self.read_all_dict_files()             # list of dictionaries that are read from the available dictionary files
        self.nof_dicts = len(self.dicts)                    # number of dictionaries = number of dictorary files

    def remove_dict_from_list(self, the_dict):
        """Remove the_dict from the internal list of dicts from the available dictionary files and from the parallel lists of filePaths and filePathNames."""
        k = self.dicts.index(the_dict)
        self.filePaths.pop(k)
        self.filePathNames.pop(k)
        self.dicts.remove(the_dict)
        self.nof_dicts -= 1

    def remove_all_but_the_dict_from_list(self, the_dict):
        """Remove all dicts from the internal list of dicts from the available dictionary files, except the_dict."""
        k = self.dicts.index(the_dict)
        filePath = self.filePaths[k]
        filePathName = self.filePathNames[k]
        self.filePaths = []
        self.filePaths.append(filePath)
        self.filePathNames = []
        self.filePathNames.append(filePathName)
        self.dicts = []
        self.dicts.append(the_dict)
        self.nof_dicts = 1

    def find_all_dict_file_paths(self, rootDir=None):
        """Recursively search the rootDir tree to find the paths to all fileName files."""
        if rootDir==None: rootDir=self.rootDir
        paths = []
        exclude = set([cm.path_string(os.path.expandvars('$HDL_BUILD_DIR'))])
        for root, dirs, files in os.walk(rootDir, topdown=True):
            dirs[:] = [d for d in dirs if cm.path_string(root+d) not in exclude and '.git' not in d and '.svn' not in d]
            if self.fileName in files:
                paths.append(root)
        return paths

    def read_all_dict_files(self, filePathNames=None):
        """Read the dictionary information from all files that were found in the rootDir tree."""
        if filePathNames==None: filePathNames=self.filePathNames
        read_dicts = []
        for fp in self.filePathNames:
            read_dicts.append(self.read_dict_file(fp))
        return read_dicts

    def read_dict_file(self, filePathName=None):
        """Read the dictionary information the filePathName file."""
        if filePathName==None: filePathName=self.filePathNames[0]
        file_dict = collections.OrderedDict()
        section_headers = []
        with open(filePathName, 'r') as fp:
            include_section = True      # default include all sections
            key = ''
            value = ''
            for line in fp:
                ln = line.split(self.CDF_COMMENT, 1)         # Strip comment from line by if necessary splitting it at the first CDF_COMMENT
                ln = ln[0]                                   # Continue with the beginning of the line before the first CDF_COMMENT
                section_begin= ln.find('[')                  # Search for [section] header in this line
                section_end  = ln.find(']')
                if section_begin>=0 and section_end>section_begin:
                    section_header = ln[section_begin+1:section_end].strip()  # new section header
                    section_headers.append(section_header)
                    include_section = True                   # default include this new section
                    if self.fileSections!=None:
                        if section_header not in self.fileSections:
                            include_section = False          # skip this section
                else:
                    key_end = ln.find(self.CDF_SEPARATOR)    # Search for key in this line
                    if key_end>=0:
                        key = ln[0:key_end].strip()          # new key
                        value = ln[key_end+1:].strip()       # new value
                    else:
                        value += ' '                         # replace newline by space to separate values
                        value += ln.strip()                  # append value
                    if include_section==True and key!='':
                        file_dict[key] = value.strip()       # Update dict with key and values
            file_dict['section_headers'] = section_headers       # Add the section headers as a key-value pair to the dict
        file_dict['lib_path'] = os.path.split(filePathName)[0]
        return file_dict

    def write_dict_file(self, dicts, filePathNames, keySeparator=None):
        """Write the dictionary information to the filePathName file."""
        if keySeparator==None: keySeparator=self.CDF_SEPARATOR
        for fpn, the_dict in zip(cm.listify(filePathNames), cm.listify(dicts)):
            with open(fpn, 'w') as fp:
                for key in the_dict:
                    fp.write('%s%s%s\n' % (key, keySeparator, the_dict[key]))

    def append_key_to_dict_file(self, filePathName, key, values):
        """Write append the key = value pair to the filePathName file."""
        with open(filePathName, 'a') as fp:
            if len(cm.listify(values))==1:
                fp.write('%s = %s' % (key, values))
            else:
                fp.write('%s = \n' % key)
                for v in cm.listify(values):
                    fp.write('%s\n' % v)

    def insert_key_in_dict_file_at_line_number(self, filePathName, key, value, insertLineNr):
        """Write a new key = value pair in the filePathName file at insertLineNr. The first line has lineNr=1."""
        # Read dict file into string and insert new key = value pair at insertLineNr
        dict_string = ''
        with open(filePathName, 'r') as fp:
            lineNr=1
            for line in fp:
                if lineNr==insertLineNr:
                    dict_string += key + ' = ' + value + '\n'
                dict_string += line
                lineNr += 1
            while lineNr<=insertLineNr:
                if lineNr==insertLineNr:
                    dict_string += key + ' = ' + value + '\n'
                dict_string += '\n'
                lineNr += 1
        # Write string to dict file
        with open(filePathName, 'w') as fp:
            fp.write(dict_string)

    def insert_key_in_dict_file_before_another_key(self, filePathName, key, value, beforeKey):
        """Write a new key = value pair in the filePathName file just before another existing beforeKey."""
        # Read dict file into string and insert new key = value pair before beforeKey
        dict_string = ''
        with open(filePathName, 'r') as fp:
            for line in fp:
                key_start = line.find(beforeKey)                  # find the 'before' key
                if key_start==0:
                    dict_string += key + ' = ' + value + '\n'     # insert the new key = value pair
                dict_string += line
        # Write string to dict file
        with open(filePathName, 'w') as fp:
            fp.write(dict_string)

    def remove_key_from_dict_file(self, filePathName, key):
        """Remove a key and value pair from the dictfile."""
        # Read dict file into string and skip the lines of the key = value pair that must be removed
        dict_string = ''
        with open(filePathName, 'r') as fp:
            remove_line = False
            for line in fp:
                if remove_line==True:
                    if line.find(self.CDF_SEPARATOR)>=0:
                        remove_line = False             # found next key, which indicates the end of remove key-value pair
                if line.find(key)==0:
                    remove_line = True                  # found key that has to be removed
                if not remove_line:
                    dict_string += line
        # Write string to dict file
        with open(filePathName, 'w') as fp:
            fp.write(dict_string)

    def rename_key_in_dict_file(self, filePathName, old_key, new_key):
        """Write new key name for old_key in the filePathName file."""
        # Read dict file into string
        with open(filePathName, 'r') as fp:
            dict_string = fp.read()
        # Rename old_key in dict string
        old_key_start = dict_string.find(old_key)                                                       # find old_key
        if old_key_start>0:
            separator_start = dict_string.find(self.CDF_SEPARATOR, old_key_start)                       # find separator
            dict_string = dict_string[0:old_key_start] + new_key + ' ' + dict_string[separator_start:]  # replace old key by new key
        # Write string to dict file
        with open(filePathName, 'w') as fp:
            fp.write(dict_string)

    def change_key_value_in_dict_file(self, filePathName, key, value):
        """Write new value for key in the filePathName file. The original key = value pair must fit on one line."""
        # Read dict file into string
        with open(filePathName, 'r') as fp:
            dict_string = fp.read()
        # Modify key value in dict string
        key_start = dict_string.find(key)                                 # find key
        if key_start>0:
            separator = dict_string.find(self.CDF_SEPARATOR, key_start)   # find separator
            if separator>0:
                value_start = separator + 1                               # value start index
            eol = dict_string.find('\n', value_start)
            if eol>0:
                value_end = eol                                           # value end index at end of line
            else:
                value_end = len(dict_string)                              # value end index at end of file
            dict_string = dict_string[0:value_start] + ' ' + value + dict_string[value_end:]
        # Write string to dict file
        with open(filePathName, 'w') as fp:
            fp.write(dict_string)

    def get_filePath(self, the_dict):
        """Get file path to the dictionary file location."""
        return self.filePaths[self.dicts.index(the_dict)]

    def get_filePathName(self, the_dict):
        """Get file path to the dictionary file location including the dictionary file name."""
        return self.filePathNames[self.dicts.index(the_dict)]

    def get_key_values(self, key, dicts=None, must_exist=False):
        """Get the value of a key in the dicts, or None in case the key does not exist, or exit if the key must exist.
           If no dicts are specified then default to the self.dicts of the object.
        """
        if dicts==None: dicts=self.dicts
        key_values = []
        for fd in cm.listify(dicts):
            if key in fd:
                key_values.append(fd[key])
            elif must_exist:
                sys.exit('Error : Key %s does not exist in the dictionary:\n%s.' % (key, fd))
            else:
                key_values.append(None)
        return cm.unlistify(key_values)

    def get_key_value(self, key, the_dict):
        """Get the value of a key from a single dict, or None in case the key does not exist, or exit if the key must exist."""
        if key in the_dict:
            key_value = the_dict[key]
        elif must_exist:
            sys.exit('Error : Key %s does not exist in the dictionary:\n%s.' % (key, fd))
        else:
            key_value = None
        return key_value

    def get_dicts(self, key, values=None, dicts=None):
        """Get all dictionaries in dicts that contain the key with a value specified in values. If values==None then
           get all dictionaries in dicts that contain the key.
        """
        if dicts==None:
            dicts=self.dicts
        the_dicts = []
        for fd in cm.listify(dicts):
            if fd not in the_dicts:
                if key in fd:
                    if values==None:
                       the_dicts.append(fd)
                    elif fd[key] in cm.listify(values):
                       the_dicts.append(fd)
        return cm.unlistify(the_dicts)


if __name__ == '__main__':
    tmpFileName = 'tmp_dict.txt'
    tmpDirName = 'tmp_dict'

    # Create some example file
    with open(tmpFileName, 'w') as f:
        f.write('# Example dictionary file 0\n')
        f.write('src=\n')
        f.write('z.vhd\n')
        f.write('\n')
        f.write('u.vhd\n')
        f.write('tb = \'c.vhd\n')
        f.write('x.vhd\'\n')
        f.write('abc.vhd\n')
        f.write('syn=\n')
        f.write(' = \n')
        f.write('              \n')
        f.write('sim= d, u\n')
        f.write('test= d u\n')
        f.write('src_files = \n')
        f.write('     x.vhd \n')
        f.write('    y.vhd \n')
        f.write('equal= with = in value\n')
        f.write('\n')

    # and created another example file in a sub directory
    os.mkdir(tmpDirName)
    tmpFilePathName = os.path.join(tmpDirName, tmpFileName)
    with open(tmpFilePathName, 'w') as f:
        f.write('# Example dictionary file 1\n')
        f.write('   # Strip indent comment\n')
        f.write('skip = will get skipped due to # this indent comment\n')
        f.write('src = x.vhd y.vhd\n')

    # Read the dictionary from the example files
    cdf = CommonDictFile(rootDir='./', fileName=tmpFileName)

    print('#')
    print('# Test for CommonDictFile.py')
    print('#')
    print('rootDir       = {}'.format(cdf.rootDir      ))
    print('nof_dicts     = {}'.format(cdf.nof_dicts    ))
    print('fileName      = {}'.format(cdf.fileName     ))
    print('filePaths     = {}'.format(cdf.filePaths    ))
    print('filePathNames = {}'.format(cdf.filePathNames))
    print('')
    for i, p in enumerate(cdf.filePaths):
        print(os.path.join(p, cdf.fileName))
        d = cdf.dicts[i]
        for k,v in d.iteritems():
            print(k, '=', v)
        print('')

    # Write dict file
    cdf.write_dict_file(cdf.dicts[0], 'tmp_dict.out')

    # Remove the example files
    os.remove(tmpFileName)
    os.remove(tmpFilePathName)
    os.rmdir(tmpDirName)