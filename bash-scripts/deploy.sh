#!/bin/bash

cd ./infra || exit
./deploy.sh

cd ./controlplane || exit
./deploy.sh