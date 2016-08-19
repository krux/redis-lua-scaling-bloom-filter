#!/bin/bash

#set -xe

MY_DIR=$( dirname $0 )

### Redis variables
REDIS_CLI='redis-cli'
REDIS_HOST='localhost'
REDIS_PORT=6379
REDIS_PASS=''
REDIS_HASH=_bloom_commands

### Where the scripts live
SCRIPT_DIR=$MY_DIR/../src
SCRIPT_SUFFIX=.lua

###
### Option parsing
###

# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "vc:h:p:P:H:" opt; do
    case "$opt" in
    v)  set -xe
        ;;
    c) REDIS_CLI=$OPTARG
        ;;
    h) REDIS_HOST=$OPTARG
        ;;
    p) REDIS_PORT=$OPTARG
        ;;
    P) REDIS_PASS="-a $OPTARG"
        ;;
    H) REDIS_HASH=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

###
### Load scripts
###

REDIS_OPTS="-h $REDIS_HOST -p $REDIS_PORT $REDIS_PASS"
SCRIPTS=`ls -1 $SCRIPT_DIR | xargs basename -s $SCRIPT_SUFFIX`

for name in $SCRIPTS
do
    ### This loads the bloomfilter lua code into redis and returns the SHA1 which
    ### can be used as the key to EVALSHA
    sha1=`cat $SCRIPT_DIR/$name$SCRIPT_SUFFIX | $REDIS_CLI $REDIS_OPTS -x script load`

    ### Now, make the command discoverable to clients
    rv=`$REDIS_CLI $REDIS_OPTS HSET $REDIS_HASH $name $sha1`

    echo "Command $name has SHA $sha1"
done
