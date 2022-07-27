#!/bin/bash

./install-prerequisites.sh

kubectl label node "$(hostname -s)" node-role.kubernetes.io/worker=worker-node
