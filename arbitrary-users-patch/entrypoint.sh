#!/bin/bash
#
# Copyright (c) 2019-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# Ensure $HOME exists when starting
if [ ! -d "${HOME}" ]; then
  mkdir -p "${HOME}"
fi

# Setup $PS1 for a consistent and reasonable prompt
if [ -w "${HOME}" ] && [ ! -f "${HOME}"/.bashrc ]; then
  echo "PS1='\[\e[38;5;69m\]$CHE_WORKSPACE_NAMESPACE\[\e[0;39m\]@\[\e[38;5;220m\]$CHE_WORKSPACE_NAME\[\e[0;39m\] 🟢 $CHE_MACHINE_NAME\[\e[0;39m\]:\[\e[38;5;172m\]\w\[\e[0;39m\]\[\e[1;32m\]\[\e[0;39m\] \n\[\e[38;5;172m\]>_ \[\e[1;39m\]'" > "${HOME}"/.bashrc
fi

# Add current (arbitrary) user to /etc/passwd and /etc/group
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-user}:x:$(id -u):0:${USER_NAME:-user} user:${HOME}:/bin/bash" >> /etc/passwd
    echo "${USER_NAME:-user}:x:$(id -u):" >> /etc/group
  fi
fi

exec "$@"
