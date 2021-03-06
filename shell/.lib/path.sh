if [[ ! $DOT_SHELL_LIB_PATH -eq 1 ]]; then
DOT_SHELL_LIB_PATH=1

lazy_source() {
  eval "$1 () { [[ -f $2 ]] && source $2 && $1 \$@; }"
}

if [[ $IS_MAC -eq 1 ]]; then
  # for mac
  source $HOME/.lib/path.macosx.sh
elif [[ $IS_LINUX -eq 1 ]]; then
  # for linux
  source $HOME/.lib/path.linux.sh
fi

# ruby, rbenv
# https://github.com/carsomyr/rbenv-bundler/issues/33
# https://github.com/rbenv/rbenv
# https://github.com/rbenv/ruby-build
# if [[ -d "$HOME/.rbenv" ]]; then
#   export PATH="$HOME/.rbenv/bin:$PATH"
#   eval "$(rbenv init --no-rehash -)"
# fi

# pythen, pyenv
# https://github.com/yyuu/pyenv
# if [[ -d $HOME/.pyenv ]]; then
#   export PATH="$HOME/.pyenv/bin:$PATH"
#   eval "$(pyenv init -)"
#   eval "$(pyenv virtualenv-init -)"
# fi

# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash

# golang
# var: GOROOT
if [[ -n $GOROOT ]]; then
  export GOPATH=$HOME/.go
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
fi

# heroku
# var: HEROKU_HOME
# if [[ -n $HEROKU_HOME ]]; then export PATH="$HEROKU_HOME/bin:$PATH"; fi

# java
if [[ -d $HOME/.sdkman ]]; then
  source $HOME/.sdkman/bin/sdkman-init.sh
fi
if [[ -n $JAVA_HOME ]]; then
  export JAVA_BIN="$JAVA_HOME/bin"
  export CLASSPATH=".:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# android
# var: ANDROID_HOME
if [[ -n $ANDROID_HOME ]]; then
  export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH
fi

# haskell
# HASKELL_HOME
if [[ -n $HASKELL_HOME ]]; then export PATH="$HASKELL_HOME/bin:$PATH"; fi

# js javascript yarn
if [[ -d $HOME/.config/yarn ]]; then
  export PATH="$PATH:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"
fi

# rust lang
if [[ -d $HOME/.cargo ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
  export RUSTC="$HOME/.cargo/bin/rustc"
  # export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
fi

[[ -x `which fzf` ]] >/dev/null 2>&1 && \
  source "$HOME/.lib/fzf.sh"

# https://github.com/asdf-vm/asdf
if [[ -e "$HOME/.asdf/asdf.sh" ]]; then
  source "$HOME/.asdf/asdf.sh"
  # source "$HOME/.asdf/completions/asdf.bash"
fi

# https://github.com/skywind3000/z.lua
z-lua() {
  local shell_name
  local _ZL_CMD
  shell_name=$(echo $SHELL | rev | cut -d '/' -f 1 | rev)
  _ZL_CMD=_z
  eval "$(lua ~/.bin/z.lua  --init $shell_name)"
}
z-lua

# common
export PATH="$PATH:/usr/local/bin:/usr/local/sbin"

fi
