#!/bin/sh
docker build -t ovn_lab:v2 --network host -f dockerfile_v2 .