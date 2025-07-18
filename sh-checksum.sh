#!/bin/bash
#
# sh-checksum.sh
#
# Generate an MD5 checksum for evey file on the current folder.
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
#  18 Jul 25         - Initial version - MT
#

_status=1 # Must be in range 0-255.
if [ -z "${1}" ]; then # No extraneous parameters found.
   find . -type f -not -path '*/.*' -not -name md5sum -exec md5sum {} \;
   _status=$?
else
  error 'Too many parameters'
fi
exit ${_status}
