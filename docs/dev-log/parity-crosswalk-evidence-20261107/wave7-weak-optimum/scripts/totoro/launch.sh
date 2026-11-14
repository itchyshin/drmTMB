#!/bin/bash
# usage: bash launch.sh <variant> <parallel>
cd $HOME/drm_weak_20261108
nohup bash run_weak.sh $1 $2 > run_$1.log 2>&1 &
echo launched $1
