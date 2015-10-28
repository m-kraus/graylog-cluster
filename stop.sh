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

vagrant halt glog01
vagrant halt glog02
vagrant halt glog03

if [ "$XOMIT" = false ]; then
    vagrant halt omd01
    vagrant halt splunk01
fi
