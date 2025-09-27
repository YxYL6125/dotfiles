
### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


#source ~/.zinit/bin/zinit.zsh
zinit wait"0" lucid for \
    light-mode zsh-users/zsh-autosuggestions \
               zsh-users/zsh-completions \
    light-mode zdharma-continuum/fast-syntax-highlighting \
               zdharma-continuum/history-search-multi-word \
    light-mode pick"init.sh" \
               b4b4r07/enhancd \

zinit ice compile'(pure|async).zsh' pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

# gvm
source "$HOME/.gvm/scripts/gvm"
# byteshell
[ -f "$HOME/.bytebm/config/config.sh" ] && . "$HOME/.bytebm/config/config.sh"

# golang
export PATH=$PATH:$GOPATH/bin
export GO111MODULE=on
# go mod 代理地址
export GOPROXY=https://go-mod-proxy.byted.org,https://goproxy.cn,https://proxy.golang.org,direct
# go13 注释掉 gonoproxy 避免对私有库校验 checksum
export GONOPROXY=code.byted.org,gitlab.everphoto.cn,git.byted.org,sysrepo.byted.org
export GOPRIVATE=*.byted.org,*.everphoto.cn,git.smartisan.com
export GOSUMDB=sum.golang.google.cn

# java
export JAVA_HOME=/Users/bytedance/workspace/env/jdk/jdk-21
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib

# nvm
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# zig
#export ZIG_DIR="/Users/bytedance/workspace/env/zig/zig-0.15.1"
#export PATH="$ZIG_DIR:$PATH"

# scala
#export SCALA_HOME=/Users/bytedance/workspace/env/scala/scala-3.2.0
#export PATH=$SCALA_HOME/bin:$PATH

# sbt
#export SBT_HOME=/Users/bytedance/workspace/env/scala/sbt-1.10.9
#export PATH=$SBT_HOME/bin:$PATH

# fastfetch
fastfetch
#eval "$(starship init zsh)"
stty -ixon

# pyenv
#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init - zsh)"
