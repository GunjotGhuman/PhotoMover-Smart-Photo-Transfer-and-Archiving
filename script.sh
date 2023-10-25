#!/bin/bash
# The following goes first, so we can refer back the directory containing these scripts.

function usage(){
    echo "Usage: addPhotos [OPTION]... [DIR1]...[DIR2]...[DIRX]    ";
    echo "Copies photos in a designated directory to $PHOTOS_DIR   ";
    echo "                                                         ";
    echo "  --help                       display this help and exit";
    echo "  -v DIR1 [DIR2] ...   add all photos in directories dir1 into $PHOTOS_DIR  with verbose output, identifying the fate of each file in dir1";
    echo "                                                         ";
    echo "Examples:                                                ";
    echo "addPhotos -v DIR1 [DIR2] ... Copy all non-duplicate files into $PHOTOS_DIR from each DIR listed while noting the fate of each file.   ";
    echo "addPhotos DIR1 [DIR2] ...Copy all non-duplicate files into $PHOTOS_DIR from DIR1.     ";
}

if ! mkdir /tmp/myscript.lock 2>/dev/null; then #prevent 2 scripts from running at the same time
    echo "A script is already running." >&2     #by creating a file during runtime and delete when
    exit 1                                      #complete to indicate a script is running!
else
    trap 'rm -rf /tmp/myscript.lock' EXIT
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

QUESTION_DIR="$HOME/csc209_23s_a1q1"
DB_DIR="$QUESTION_DIR/database"
PHOTOS_DIR="$DB_DIR/photos"

find $PHOTOS_DIR/ -type f -exec md5sum {} + > $DB_DIR/db.txt

#definition of a bad argument is anything other than verbose, help, or an address

if [ "$1" == '--help' ] || ([ "$1" != '-v' ] && [ ! -d "$1" ]);# help is outside the loop because I want to call it ATMOST once if it is the first element
then 
    usage
else
    while (( $# > 0 ))
    do
        if [ -d $1 ]
        then
            for file in $1/*
            do    
                if [[ -f "$file" ]]
                then
                    is_dup=0
                    is_repeateName=0

                    # Get the address of the file
                    file_basename=$(basename "$file")

                    # Get the checksum of the file
                    file_checksum="$(md5sum "$file" | cut -d ' ' -f 1)"

                    result_content=$(grep $file_checksum $record_file | awk '{print $2}')

                    if [ -n "$result_content" ]; then
                        if [ $VERBOSE == 1 ]
                        then
                            echo "duplicate image $file."
                        fi
                        is_dup=1
                    fi

                    result_name=$(grep $file_basename $record_file | awk '{print $1}')

                    if [ -n "$result_name" ]; then
                        is_repeateName=1
                    fi

                    if [ $is_dup == 0 ]
                    then
                        if [ $is_repeateName == 1 ] 
                        then
                            rand_name=$(echo $RANDOM | md5sum | head -c 10; echo;)
                            echo "$rand_name $file_checksum" >> $record_file
                            if [ $VERBOSE == 1 ]
                            then
                                echo "copied $rand_name"
                            fi
                        else
                            echo "$file_basename $file_checksum" >> $record_file
                            cp $file $PHOTOS_DIR
                        fi
                    fi
                fi
            done
            shift
        else
            echo "directory does not exist" >&2
            switch
        fi
    done
fi
