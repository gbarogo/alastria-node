#!/bin/bash

TIME_S=180

if([ $1 -gt 0 ]); then
	TIME_S=$1
fi

temporizador() {
	date1=$((`date +%s` + $TIME_S));
	while [ "$date1" -ge `date +%s` ]; do 
	  echo -ne "$(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r" > ~/alastria-node/data/RestartTime  
	done
}

while true
do
    temporizador
    current_dir=$PWD
    cd ~/alastria-node/scripts/
    ./restart.sh auto
    cd $current_dir
done
