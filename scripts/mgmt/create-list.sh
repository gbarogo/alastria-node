#!/bin/sh

function rawregularlist {
  cat ../../DIRECTORY_REGULAR.md | \
  gawk -F"|" \
  '$6~/enode/ { \
     match($6, /enode:\/\/[0-9a-z]*@([.0-9]*):[0-9]+/, arr); \
     if (arr[1] != "")  { \
        print "\n"$6""; \
     } \
  }'
}

function rawvalidatorlist {
  cat ../../DIRECTORY_VALIDATOR.md | \
  gawk -F"|" \
  '$5~/enode/ { \
       match($5, /enode:\/\/[0-9a-z]*@([.0-9]*):[0-9]+/, arr); \
       if (arr[1] != "")  { \
            print "\n"$5""; \
       } \
  }'
}

function rawcombinedlist {
  rawregularlist
  rawvalidatorlist
}

function tojson {
  #tee | sed 's/ //g' | sed 's/\"//g' | sed '/^\s*$/d' | sort | uniq | jq -R . | jq --indent 4 -s 
  #tee | sed 's/[[:blank:]]//g' | sed 's/\"//g' | sed '/^\s*$/d' | sort | uniq | jq -R . | jq --indent 4 -s .
  tee | sed 's/[[:blank:]]//g;s/\"//g;/^\s*$/d' | sort -fu | jq -R . | jq --indent 4 -s .
}

case "$1" in 
  --regular)
  rawregularlist | tojson
  ;;
  --validator)
  rawvalidatorlist | tojson
  ;;
  --combined)
  rawcombinedlist | tojson
  ;;
  --sliced)
  slicedlist $2 $3| tojson
  ;;
esac

