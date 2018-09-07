#!/usr/bin/env bash

if [ ! -d influxdata-sandbox ]
then
    git clone https://github.com/influxdata/sandbox.git influxdata-sandbox
fi

cd influxdata-sandbox && ./sandbox up
