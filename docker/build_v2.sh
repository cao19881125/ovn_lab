#!/bin/sh
docker build -t ovn_lab:v2 --network host -f docker_file_v2 .