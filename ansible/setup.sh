#!/usr/bin/env bash

if [ ! -d venv ]
then
    python3 -m venv venv
fi

. venv/bin/activate

pip install -r requirements.txt
ansible-galaxy install -r requirements.yml
