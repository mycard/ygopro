#!/bin/bash
set -o errexit
set -x

source .ci/pack-common

_pack linux ygopro
