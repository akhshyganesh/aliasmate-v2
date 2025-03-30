#compdef aliasmate

_aliasmate() {
  local -a aliases
  aliases=($(aliasmate --list-all 2>/dev/null))
  
  _describe 'aliases' aliases
}

_aliasmate "$@"
