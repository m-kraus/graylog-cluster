#/bin/bash

XOMIT=false

while :; do
    case $1 in
        -x)
            XOMIT=true
            ;;
        *)
            break
    esac

    shift
done

vagrant up glog01
vagrant up glog02
vagrant up glog03

if [ "$XOMIT" = false ]; then
    vagrant up omd01
    vagrant up splunk01
fi
