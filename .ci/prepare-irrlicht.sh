#!/bin/bash
set -x
set -o errexit

source .ci/prepare-repo
prepare_repo "https://code.moenext.com/mycard/irrlicht-new.git" "irrlicht"
