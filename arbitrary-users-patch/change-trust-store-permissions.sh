#!/bin/bash

if [[ -n "$JAVA_HOME" ]]; then
  if [[ -f "$JAVA_HOME/jre/lib/security/cacerts" ]]; then
    chmod 664 "$JAVA_HOME/jre/lib/security/cacerts"
  fi
fi
