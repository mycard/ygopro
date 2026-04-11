#!/bin/bash
set -o errexit
set -x

source .ci/pack-common

_pack win32 ygopro.exe Bot.exe WindBot
