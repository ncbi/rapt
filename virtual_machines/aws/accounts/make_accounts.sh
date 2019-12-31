#!/bin/bash
shopt -s nullglob

GROUP=gpipe

for UNAME in $@; do
    useradd -m -s /bin/bash -g ${GROUP} -G docker ${UNAME}
    mkdir -p /home/${UNAME}/.ssh
    mv /tmp/keys/${UNAME}.pub /home/${UNAME}/.ssh/authorized_keys
    chmod 700 /home/${UNAME}/.ssh
    chmod 600 /home/${UNAME}/.ssh/authorized_keys
    for f in /tmp/accounts/${UNAME}.* ; do
        fn=$(basename -- "$f")
        ext="${fn##*.}"
        mv $f /home/${UNAME}/.${ext}
    done
    chown -R ${UNAME}:${GROUP} /home/${UNAME}
    chmod 750 /home/${UNAME}
done
