#!/bin/bash

set -euxo pipefail

find . -type f \! -name checksum.md5 -printf '%P\n' | sort | xargs -rd'\n' md5sum

