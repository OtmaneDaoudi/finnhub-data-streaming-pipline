#!/bin/bash

cqlsh -e 'SELECT now() FROM system.local'

if [ $? == 1 ]; then
    exit 1;
fi

cqlsh -f /setup.cql

if [ $? == 1 ]; then
    exit 1;
fi

exit 0