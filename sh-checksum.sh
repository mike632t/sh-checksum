#!/bin/bash
#
# sh-checksum.sh
#
# Can generate and check the MD5 checksum of the all files in folder and its 
# sub folders.  
#
# By comparing the current contents of a folder with a previously saved copy
# of  the checksum for each file, it can be used to identify any files  that
# have been modified, added, or deleted.  
#
# Since the file paths of each file in each checksum are relative is is also
# possible to compare files in different folders. 
#
# This  program is free software: you can redistribute it and/or  modify  it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your  option)
# any later version.
#
# This  program  is  distributed  in the hope that it will  be  useful,  but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or  FITNESS  FOR A PARTICULAR PURPOSE. See the GNU General Public  License
# formore details.
#
# You  should  have received a copy of the GNU General Public License  along
# with this program. If not, see <http://www.gnu.org/licenses/>
#
#  18 Jul 25   0.1   - Initial version - MT
#  20 Jul 25   0.2   - Combined both checksum generation and checking into a
#                      single script - MT
#                    - Combining all the filenames into a single list allows
#                      modified, new and deleted files to be identified in a
#                      single pass - MT
#

_version="0.2.0003"
_name=$(basename $0)

### Print help and exit

usage() {
printf "%s\n" "\
Usage: md5sum [OPTION]... PATH
Print or verify MD5 (128-bit) checksums for file in the folder specified by
the given PATH.

  -b, --binary         read in binary mode
  -c, --check FILE     read checksums from a FILE and verify that they 
                       match the files in the folder specified by PATH 
  -t, --text           read in text mode (default)
      --maxdepth LEVEL search at most LEVEL folders below PATH 
      --name PATTERN   only include files matching PATTERN (not case 
                       sensitive)
      --verbose        display all files

      --help           display this help and exit
      --version        output version information and exit
      
Search options are not applied to saved checksum details.
"
exit 0
}

### Print version details and exit
version() {
printf "%s\n" "\
$_name $_version
Copyright (C) 2025 MT.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law."
exit 0
}

### Print error message and exit
error() {
printf "%b\n" "$_name: ${1:-"Unknown Error"}" 1>&2 # Subsitute "Unknown Error" if no error message is defined.
exit 1
}

### Print checksums
print() {
IFS=$'\t\n' # A bit of a fudge to allow file names with spaces
if [ -d $1 ] ;then
   pushd "$1" > /dev/null # Use relative paths 
   _files="$(find . "${_find_options[@]}" -type f -not -path '*/.*' | sort)"
   for _file in $_files ;do
      if ! md5sum "${_md5sum_options[@]}" $_file ;then
         _status=$?
         break
      fi
   done
   popd  > /dev/null 
else
  error "folder '$1' not found."
fi
exit ${_status}
}

### Validate checksums
check() {
IFS=$'\t\n' # A bit of a fudge to allow file names with spaces

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null ;then
   # We have color support; assume it's compliant with Ecma-48
   # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
   # a case would tend to support setf rather than setaf.)
   _normal=$'\033[00m'
   _blue=$'\033[01;34m'
   _yellow=$'\033[0;33m'
   _green=$'\033[0;32m'
   _red=$'\033[0;31m'
   _black=$'\033[0;30m'
fi

_new=" [${_blue}NEW${_normal}]" 
_modified=" [${_yellow}MODIFIED${_normal}]"
_match=" [${_green}OK${_normal}]"
_deleted=" [${_red}DELETED${_normal}]"

if [ -f "$2" ] ;then
   # Search for any MODIFIED or NEW files...
   pushd "$1" > /dev/null # Use relative paths 
   _checksum="$(realpath -s --relative-to=./ "$2")"
   #find . "${_find_options[@]}" -type f -not -path '*/.*' -not -wholename ./$_checksum | sort
   _files="$(find . "${_find_options[@]}" -type f -not -path '*/.*' -not -wholename ./$_checksum | sort)"
   _saved="$(cat $_checksum | cut -c 35-)"
   _combined="$(echo "$(for _name in $_files $_saved ;do echo $_name ;done)" | sort | uniq)"
   for _name in $_combined ;do
      if [ -e "$_name" ] ;then
         _file=$(md5sum """$_name""")
      else
         _file=""
      fi
      if [ $DEBUG ] ;then echo "+ $_file" ;fi
      _save="$(cat $_checksum | grep -w "$_name\$")"
      if [ $DEBUG ] ;then echo "-  $_save" ;fi
      if [ "$_file" != "$_save" ] ;then
         if [ "$_save" != "" ] ;then 
            if [ "$_file" != "" ] ;then 
               echo "$_file$_modified"
            else
               echo "$_save$_deleted"
            fi
         else 
            echo "$_file$_new"
         fi
      else
         if [ $_verbose ] ;then 
            echo "$_file$_match"
         fi
      fi
   done

   # Restore current location
   popd > /dev/null
else
   error "'$_checksum' file not found."
fi

exit ${_status}
}

### Parse command line arguments
while [[ $# -gt 0 ]] ;do # Scan command line arguments
   case "$1" in
   --help)
      usage;;
   --version)
      version;;
   --verbose)
      _verbose=true;;
   --maxdepth)
      _find_options=("${_find_options[@]}" "-maxdepth" "$2")
      shift;;
   --name)
      _find_options=("${_find_options[@]}" "-iname" "$2")
      shift;;
   -c|--check|--checksum)
      if [ ! "$2" ] ;then 
         error "'$1' requires a file name"
      else
         _checksum="$2"
      fi
      shift;;
   -b|--binary|-t|--text)
      _md5sum_options=("${_md5sum_options[@]}" "$1");;
   -*) # Unrecognized qualifier!
      error "unrecognized option '$1'\nTry '$_name --help' for more information.";;
   *) # Process any arguments.
      if [ ! $_path ] ;then
         _path="$1"
      else
         error "Multiple PATHs not allowed"
      fi
   esac
   shift
done

if [ ! $_path ] ;then _path=".";fi

if [ ! $_checksum ] ;then 
   print "$_path"
else
   _checksum="$(realpath $_checksum)"
   check "$_path" "$_checksum"
fi

exit
