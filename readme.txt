GEOSBuild
=========

Command-line tool that builds a GEOS file on a Commodore 64/128 disk image from
its constituent parts.

Copyright (C) 2016, Daniel England.
All Rights Reserved.  Released under the GPL.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.


Introduction
------------

GEOS is an operating system that is run on a C64, C128 or Apple IIe.  It is a
GUI OS which was quite remarkable at the time given the constraints of its
target systems.

GEOS extended the file formats used on these sytems in order to include the
equivalent of today's resource forks as well as data forks.  This was done to
supply additional information for the operating system as well as to break the
file into chunks that could be loaded or unloaded as required (called VLIR or
variable length, indexed records).

This tool builds these GEOS files from the constituent parts onto a disk image.
It can be used to create application files as well as application data files or
any other GEOS file type (such as fonts).  The underlying structures for these
files is the same and you need only supply the binary files for the header/info
block/fork as well as the data or record forks.  Only C64 and C128 disk images
are supported, however.


Usage
-----

GEOSBuild is a command-line tool and has the following option format:

    GEOSBuild [-h | --help] | [[-s | --silent] | [-v | --verbose]] <build file>

        -h | --help
        Produce a help message, to remind you of the usage.

        -s | --silent
        Prevent information messages from being printed.

        -v | --verbose
        Cause the output to include extended information.

        <build file>
        The name of the file to use for the build file instructions.  Typically,
        these files should have the extension ".gbuild".

A build instruction file must be supplied for normal usage.  It is a simple
"ini" type file that can contain three different sections.  The "[build]"
section is always required, where-as the "[sequential]" and "[VLIR]" sections
are required only for the applicable GEOS file structure.

The "[build]" section has the following items:

    File        Optional.  Specifies the name for the file entry created on the
                disk.  If not supplied, the name is collected from the
                info/header data.  Should always be supplied for data files and
                not used for application files since GEOS on the C64 will not
                execute an application if the names do not match.

    Disk        Required.  Specifies the name and type of the disk image onto
                which the file will be written.  If the disk image file doesn't
                exist, it will be created.  The type of the disk image is
                determined by the file extension.

    Header      Required.  Specifies the file used for the info/header fork.  It
                must be a file of exactly 256 or 254 bytes in size.  The size of
                256 is supported for legacy reasons and if used, the first two
                bytes will be ignored.  This file must contain valid GEOS info
                or header data.  See the included examples or GEOS programming
                documentation for further information.

The "[sequential]" section is used when the structure in the info/header data
indicates that the file should be a GEOS sequential file.  It has the following
items:

    Data        Required.  Specifies the file to use for the data fork.  If the
                file is specified with the extension ".prg", then the first two
                bytes of the file will be ignored (they should be set to the
                load address for that file type).  GEOS files do not use a load
                address from the data fork, instead relying on it from the info/
                header fork.  This has been done to ensure that the widest range
                of assemblers/compilers can be supported.

The "[VLIR]" section is used when the structure in the info/header data
indicates that the file should be a GEOS VLIR file.  It has the following items:

    <record n>  At least one should be specified.  The exact name of the item is
                the decimal integer representation (with no leading zeros) of
                the record to specify.  The value should be the file to use for
                that reocord's data fork.  The same rules apply as per the
                "Data" item in the "sequential" section however, if the value is
                given as "__VLIR_END" then the record is set as a VLIR End
                record and if "__VLIR_EMPTY" is used the record is set as an
                Empty VLIR record.  The range of records is zero (0) to 126.  If
                a record value is not specified then the record is set to Empty.
                You should see the GEOS programming documentation for further
                information.


Exit Codes
----------

For using GEOSBuild in a chain of programs, the following exit codes can be
detected:

     0      Success
    -1      Help requested
    -2      Invalid option specified
    -3      Processing error
    -4      Unexpected error


Compiling
---------

You need FPC and Lazarus to compile GEOSBuild.  You can get Lazarus (which
includes FPC) for your platform from the following address:

        http://www.lazarus-ide.org/

At the time of writing, I am using Lazarus version 1.6 but earlier versions
should be supported so long as they have FPC version 2.1 or higher.

Several platforms are supported, including Windows, Linux and MacOSX.  32bit or
64bit compilation should be supported, depending upon your requirements.

To compile, open the "GEOSBuild.lpi" file in Lazarus and select Run | Build.
You can switch the Build Mode by using the Compiler Project Options under
Project | Project Options | Compiler Options and selecting either the Release or
Debug Build Mode.

Delphi is presently unsupported due to the extensive use of Lazarus features.


Examples
--------

I have included two examples with the GEOSBuild sources.  These should help you
get started with using GEOSBuild.


Contact
-------

I can be contacted for further information regarding this tool at the following
address:

        mewpokemon {you know what goes here} hotmail {and here} com

Please include the word "GEOSBuild" in the subject line.

Thanks for using GEOSBulid!



Daniel England.
