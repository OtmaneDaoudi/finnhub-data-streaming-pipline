#!/bin/bash

cqlsh -e 'SELECT now() FROM system.local'

cqlsh -f /setup.cql

exit 0