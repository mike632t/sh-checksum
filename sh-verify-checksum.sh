#!/bin/bash
#
# sh-verify-checksum.sh
#
# Checks the contents of the current folder (and subfolders) for files that
# have been modified.
#
# It then checks to see if any files have been deleted!
#
# This allows you to compaire two sets of files to see which ones have been
# changed.
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
# https://unix.stackexchange.com/questions/9957
#
#  18 Jul 25         - Initial version - MT
#

_version="0.1"
_name=$(basename $0)

usage() {
printf "%s\n" "\
Usage: $_name [OPTION]... [FILE]...
  -b, --binary         read in binary mode
      --help           display this help and exit
      --version        output version information and exit"
#  -c, --check          read checksums from a FILE and check them
exit 0
}

version() {
printf "%s\n" "\
$_name $_version
Copyright (C) 2025 MT.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law."
exit 0
}

error() { # Print formatted error message
printf "%b\n" "$_name: ${1:-"Unknown Error"}" 1>&2 # Subsitute "Unknown Error" if no error message is defined.
exit 1
}

# Scan command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    usage;;
  --version)
    version;;
  --verbose)
    _verbose=1;;
  -b|--binary)
    _binary=1;;
# -c|--check)
#   _check=true;;
  -*) # Unrecognized qualifier!
    error "unrecognized option '$1'\nTry '$_name --help' for more information.";;
  *) # Append each argument to args[] (preserving quoted strings).
    _args[$_count]="${1}"
    _count=$((_count + 1));;
 esac
  shift
done

# Set up escape sequences
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
   # We have color support; assume it's compliant with Ecma-48
   # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
   # a case would tend to support setf rather than setaf.)
   _normal="\033[00m"
   _blue="\033[01;34m"
   _yellow="\033[0;33m"
   _green="\033[0;32m"
   _red="\033[0;31m"
   _black="\033[0;30m"
fi

_new=" [${_blue}NEW${_normal}]"
_modified=" [${_yellow}MODIFIED${_normal}]"
_match=" [${_green}OK${_normal}]"
_deleted=" [${_red}DELETED${_normal}]"


for _checksum in ${_args[@]} ;do
   if [ -f $_checksum ] ;then
      # Save current location
      pushd "$(dirname $(realpath --relative-to=. ./$_checksum))" > /dev/null
      _checksum="$(basename $_checksum)"

      # Search for any MODIFIED or NEW files...
      if [ $_verbose ] ;then
         find . -type f -not -path '*/.*' -not -name $_checksum -exec sh -c "(if [ \"\$(md5sum \"\"\"{}\"\"\")\" != \"\$(cat $_checksum | grep -w \"{}\"\$)\" ] ;then if grep -qw \"{}\"\$\"\" $_checksum ;then echo \"{}$_modified\" ;else echo \"{}$_new\"; fi ;else echo \"{}$_match\"; fi)" \;
         _status=$?
      else
         find . -type f -not -path '*/.*' -not -name $_checksum -exec sh -c "(if [ \"\$(md5sum \"\"\"{}\"\"\")\" != \"\$(cat $_checksum | grep -w \"{}\"\$)\" ] ;then if grep -qw \"{}\"\$\"\" $_checksum ;then echo \"{}$_modified\" ;else echo \"{}$_new\"; fi ; fi)" \;
         _status=$?
      fi

      # Check for any files that have been deleted
      if [ $_status -eq 0 ]; then
         md5sum -c --quiet $_checksum 2>&1 | grep ": FAILED.\{1,\}$" | sed "s/: FAILED.\\{1,\\}\$/$(echo -e $_deleted)/g"
         _status=$?
      fi


      # Restore current location
      popd > /dev/null
   else
      error "'$_checksum' file not found."
   fi
done
exit ${_status}
