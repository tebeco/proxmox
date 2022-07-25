#!/bin/bash

qm stop 1010
qm stop 1020
qm stop 1021

qm destroy 1010 -purge -destroy-unreferenced-disks 1
qm destroy 1020 -purge -destroy-unreferenced-disks 1
qm destroy 1021 -purge -destroy-unreferenced-disks 1

qm destroy 9000 -purge -destroy-unreferenced-disks 1