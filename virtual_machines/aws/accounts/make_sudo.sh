#!/bin/bash

for UNAME in $@; do
    echo "${UNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/packer-init
done
chmod 0440 /etc/sudoers.d/packer-init
