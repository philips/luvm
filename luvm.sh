# Luvit Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
#
# Made after Tim Caswell's nvm

alias luvm=$HOME/.luvm/luvm_cmd.sh
alias luvm_version=$HOME/.luvm/luvm_version_cmd.sh
luvm ls default >/dev/null 2>&1 && luvm use default >/dev/null
