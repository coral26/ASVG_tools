#!/bin/bash
#
# Val Schmidt
# Center for Coastal and Ocean Mapping
# University of New Hampshire
# Copyright 2016
#
#
# TO DO:
# Add the ability to export all log directories.

if [ $1 == "-h" ]; then

    echo ""
    echo "USAGE: "
    echo "    asv_log_extractor.sh <path/to/ccscm> \ "
    echo "           [/path/to/output/dir]"
    echo " "
    echo "Logs will be extracted for the selected log directories"
    echo "into /path/to/output/dir/extracted_logs/ producing CSV"
    echo "files for each of the standard log types. If the output"
    echo "directory is omitted, the current working directory is used."
    echo ""
    exit
fi

# The first argument is the path to the ccscm log directory. 
ccscm=$1

if [ ! -e $ccscm ]; then
    echo "Could not find $ccscm"
    echo "Exiting..."
    exit
fi 

ccscm=`readlink -f "$ccscm"`

# The second argument is the directory into which the extact data will
# go.
tmp=$2

if [ "$tmp" == "" ]; then
    tmp=`pwd`
    echo "Setting default output directory to "
    echo "    $tmp/extracted_logs"
fi
outputdir="$tmp/extracted_logs/"

# TODO: Check to see that the output directory exist and either fail
# or make it.   

# Inquire for the directory of logs that are to be parsed. It is not
# yet clear what causes a rotation of logging directory by ASV. For
# now logs are extracted on a directory basis. 

alllogdirs=`ls -1 $ccscm/scm-vp`

# Get a list of the logs that actually have data and display them.
logswithdata=()
echo "I have detected logs in these directories:"
for logdir in ${alllogdirs[@]}; do

    if [ -e "$ccscm/scm-vp/$logdir/smState.smx" ]; then
	logswithdata=( ${logswithdata[@]} $logdir )
	echo "$logdir"
    fi

done

# Get the user's selection. 
echo "Type (cut/paste) the directory(s) to process, with 'Enter' after
each. Type'q' to quit."
read datadir
while [ "$datadir" != 'q' ]; do

    if [ "$datadir" == '*' ]; then
	datadirs=( ${logswithdata[@]} )
	datadir="q"
    else

	# This checking may not be necessary since I am now only listing
	# directories that have data. Maybe some other checking is worth
	# while here?
	# echo "Checking $ccscm/$datadir..."
	if [ -e "$ccscm/scm-vp/$datadir" ]; then
    
            datadirs=( "${datadirs[@]}" $datadir )
	else
    	    echo "That data directory does not exist. Try again. ('q' to quit)."
	fi

	read datadir
    
    fi # End check for '*'

done

# Process the data. 
for datadir in ${datadirs[@]}; do

    # Define and create the output directory.
    complete_outputdir="$outputdir/$datadir"
    outputspec="$complete_outputdir/$datadir.exs"
    echo "mkdir $complete_outputdir"
    mkdir -p "$complete_outputdir/configs/"

    # Capture where the command was executed from.
    cwd=`pwd`

    # A bug in data-export-cli utility will not support multiple
    # exports in a single file. So separate export configuration files
    # had to be generated for each. This line hails from a time when
    # we expected to be able to do it in a single go. 
    # create_export_config.sh "$complete_outputdir" > "$outputspec"

    # Go to the output directory and create the configu files. 
    cd "$complete_outputdir/configs"
    create_export_configs.sh "$complete_outputdir" 
    cd ..

    # Then find all the config files we generated and process each. 
    echo "Processing $datadir..."
    configstoprocess=`find . -type f | grep export_config.exs`
    for config in ${configstoprocess[@]}; do	
	data-export-cli -d "$ccscm/scm-vp/$datadir" \
	    -x "$config" 2>&1 > $complete_outputdir/export.log &
    done

    secs=0
    procs=`jobs | grep Running`
    while [ "$procs" != "" ]; do

	echo "Processing $datadir, ${secs}s elapsed..."
	sleep 1
	secs=`echo "$secs+1" | bc`
	tput cuu 1
	procs=`jobs | grep Running`
    
    done
    echo ""
    echo "Export of $datadir complete."
    # Go back to the original location. 
    cd "$cwd"
done

