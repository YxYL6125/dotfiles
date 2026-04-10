
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

# alias
alias cls="clear"
alias l="ls -l"
alias ll="ls -l"
alias la="ls -a"
alias p="posting"
alias t="tmux"
alias ta="tmux a"
alias ss="source ~/.yabairc"
alias g="git"
alias ge="gemini"
alias tc="ttadk code -t claude"
alias h="hermes"


# antigravity-tool
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
export ANTHROPIC_BASE_URL="http://127.0.0.1:8045"

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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
#stty -ixon

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# rust
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
source $HOME/.cargo/env

# posting 
source $HOME/.local/bin
. "$HOME/.local/bin/env"

# adb platform-tools
export ADB_VENDOR_KEYS=$HOME/.android/adbkey



 #~/.zshrc — yazi 退出后自动 cd 函数
y() {
  # 使用 mktemp 创建临时文件记录 yazi 退出目录
  local tmp
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  # 启动 yazi，传入当前目录或参数中的路径
  # -m 关闭鼠标（可按需去掉），--cwd-file 把最终目录写入 tmp
  yazi "$@" --cwd-file="$tmp"
  # 如果 tmp 文件存在且非空，读取并 cd；否则保持原目录
  if [[ -s "$tmp" ]]; then
    local dest
    dest="$(cat "$tmp")"
    # 安全检查：目标必须是目录
    if [[ -d "$dest" ]]; then
      builtin cd -- "$dest"
    fi
  fi
  # 清理临时文件
  rm -f -- "$tmp"
}

# ts
function ts() {
  if [ -z "$1" ]; then
    echo "用法: ts <unix_timestamp>"
    echo "例子 (秒): ts 1718953200"
    echo "例子 (毫秒): ts 1718953200000"
    return 1
  fi

  local ts_input=$1
  local ts_seconds

  # 检查时间戳长度，判断是秒还是毫秒
  if [ ${#ts_input} -eq 13 ]; then
    ts_seconds=$((ts_input / 1000))
  elif [ ${#ts_input} -eq 10 ]; then
    ts_seconds=$ts_input
  else
    echo "错误: 时间戳长度应为10位(秒)或13位(毫秒)。"
    return 1
  fi

  # 使用 date 命令格式化输出，你可以自定义你喜欢的格式
  date -r "$ts_seconds" '+%Y-%m-%d %H:%M:%S'
}

function j() {
  if [ -z "$1" ]; then
    echo "用法: j '<json_string>'"
    echo "将 json 字符串通过管道传递给 jq 进行格式化"
    return 1
  fi
  echo "$1" | jq .
}



# Added by Antigravity
export PATH="/Users/bytedance/.antigravity/antigravity/bin:$PATH"

# OpenClaw Completion
source "/Users/bytedance/.openclaw/completions/openclaw.zsh"

# adb cp cert for /sdcard/Download/Reqable
reqcert() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "usage: reqcert <hash.0>"
    return 1
  fi

  adb remount || return 1

  adb shell cp "/sdcard/Download/Reqable/$name" "/system/etc/security/cacerts/$name" || return 1
  adb shell chmod 644 "/system/etc/security/cacerts/$name" || return 1
  adb shell chown root:root "/system/etc/security/cacerts/$name" || return 1
  adb shell restorecon "/system/etc/security/cacerts/$name" || true

  if adb shell test -d /apex/com.android.conscrypt/cacerts; then
    adb shell cp "/sdcard/Download/Reqable/$name" "/apex/com.android.conscrypt/cacerts/$name" || return 1
    adb shell chmod 644 "/apex/com.android.conscrypt/cacerts/$name" || return 1
    adb shell chown root:root "/apex/com.android.conscrypt/cacerts/$name" || return 1
    adb shell restorecon "/apex/com.android.conscrypt/cacerts/$name" || true
  fi

  adb reboot
}

pullreq() {
  local name="$1"
  local dest="${2:-.}"

  if [[ -z "$name" ]]; then
    echo "usage: pullreq <hash.0> [dest]"
    return 1
  fi

  mkdir -p "$dest" || return 1
  adb pull "/sdcard/Download/Reqable/$name" "$dest/" || return 1
}

