#/bin/bash

OMD=false
SPLUNK=false

while :; do
    case $1 in
        -o)
            OMD=true
            ;;
        -s)
            SPLUNK=true
            ;;
        *)
            break
    esac

    shift
done

vagrant up glog01
vagrant up glog02
vagrant up glog03

if [ "$OMD" = true ]; then
    vagrant up omd01
fi
if [ "$SPLUNK" = true ]; then
    vagrant up splunk01
fi
