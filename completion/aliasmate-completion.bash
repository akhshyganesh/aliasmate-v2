#!/usr/bin/env bash

_aliasmate_completions() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  
  # Get all available aliases
  local aliases=$(aliasmate --list-all 2>/dev/null)
  
  COMPREPLY=($(compgen -W "$aliases" -- "$cur"))
}

complete -F _aliasmate_completions aliasmate
