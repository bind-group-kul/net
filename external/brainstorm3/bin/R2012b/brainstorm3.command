#!/bin/bash
# USAGE:  brainstorm3.command <MATLABROOT>
#         brainstorm3.command
#
# If MATLABROOT argument is specified, the Matlab root path is saved
# in the file ~/.brainstorm/MATLABROOT80.txt.
# Else, MATLABROOT is read from this file
#
# AUTHOR: Francois Tadel, 2011-2012

#########################################################################
# Detect system type
if [ $(uname -s) == "Linux" ]; then
    if [ $(getconf LONG_BIT) == "32" ]; then
        SYST=glnx86
    else
        SYST=glnxa64
    fi
elif [ $(uname -s) == "Darwin" ]; then
    SYST=maci64
else
    echo "ERROR: Unsupported operating system"
    uname -a
    exit 1
fi 

# Configuration file path
MDIR="$HOME/.brainstorm"
MFILE="$MDIR/MATLABROOT80.txt"

##########################################################################
# Detect in which directory is this script
SH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# JAR is in the same folder (Linux)
if [ -f "$SH_DIR/brainstorm3.jar" ]; then
    JAR_FILE=$SH_DIR/brainstorm3.jar
# JAR is 3 levels up (on MacOSX: brainstorm3.app/Contents/MacOS/brainstorm3.command)
elif [ -f "$SH_DIR/../../../brainstorm3.jar" ]; then
    JAR_FILE=$SH_DIR/../../../brainstorm3.jar
else
    echo "ERROR: brainstorm3.jar not found"
fi

#########################################################################
# Read the Matlab root folder from the command line
if [ "$1" ]; then
    MATLABROOT=$1 
# Read the folder from the file
elif [ -f $MFILE ]; then
    MATLABROOT=$(<$MFILE)
# Run the java file selector
else
    java -classpath $JAR_FILE org.brainstorm.file.SelectMcr2012b
    # Read again the folder from the file
    if [ -f $MFILE ]; then
        MATLABROOT=$(<$MFILE)
    fi
fi

#########################################################################
# If folder not specified: error
if [ -z "$MATLABROOT" ]; then
    echo " "
    echo "USAGE: brainstorm3.command <MATLABROOT>"
    echo " "
    echo "MATLABROOT is the installation folder of the MCR 8.0"
    echo "The Matlab Compiler Runtime 8.0 is the library needed to"
    echo "run executables compiled with Matlab R2012b."
    echo " "
    echo "Examples:"
    echo "    Linux:  /usr/local/Matlab_Compiler_Runtime/v80"
    echo "    Linux:  $HOME/MCR_R2012b"
    echo "    MacOSX: /Applications/MATLAB/MATLAB_Compiler_Runtime/v80"
    echo " "
    echo "MATLABROOT has to be specified only at the first call,"
    echo "then it is saved in the file ~/.brainstorm/MATLABROOT80.txt"
    echo " "
    exit 1
# If folder not a valid Matlab root path
else
    if [ $SYST == "maci64" ]; then
        LIBNAT=$MATLABROOT/bin/$SYST/libnativedl.jnilib
    else
        LIBNAT=$MATLABROOT/bin/$SYST/libnativedl.so
    fi
    if [ ! -f "$LIBNAT" ]; then
		echo " "
        echo "Error: $MATLABROOT"
        echo "Not a valid MATLAB root path."
		echo " "
		echo "USAGE: brainstorm3.command <MATLABROOT>"
		echo " "
        exit 1
    fi
fi

#########################################################################
# Create .brainstorm folder is necessary
if [ ! -d "$MDIR" ]; then
    mkdir $MDIR
fi
# Save Matlab path in user folder
echo "$MATLABROOT" > $MFILE

##########################################################################
# Setting library path for MACOSX
if [ $SYST == "maci64" ]; then

    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$MATLABROOT/runtime/maci64:$MATLABROOT/sys/os/maci64:$MATLABROOT/bin/maci64:/System/Library/Frameworks/JavaVM.framework/JavaVM:/System/Library/Frameworks/JavaVM.framework/Libraries

# Setting library path for LINUX
else
    export PATH=$PATH:$MATLABROOT/runtime/$SYST

    JAVA_SUBDIR=$(find $MATLABROOT/sys/java/jre -type d | tr '\n' ':') 
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_SUBDIR$MATLABROOT/runtime/$SYST:$MATLABROOT/bin/$SYST:$MATLABROOT/sys/os/$SYST
    # export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MATLABROOT/runtime/$SYST:$MATLABROOT/bin/$SYST:$MATLABROOT/sys/os/$SYST:$MATLABROOT/sys/java/jre/$SYST/jre/lib/i386/native_threads:$MATLABROOT/sys/java/jre/$SYST/jre/lib/i386/server:$MATLABROOT/sys/java/jre/$SYST/jre/lib/i386
fi

export XAPPLRESDIR=$MATLABROOT/X11/app-defaults

##########################################################################
# Run Brainstorm
java -jar $JAR_FILE

# Force shell death on MacOSX
if [ $SYST == "maci64" ]; then
    exit 0
fi



