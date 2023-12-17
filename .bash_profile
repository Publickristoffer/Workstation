# Kristoffers Mac's .bash_profile

# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.pre.bash"

# Mac OS X specific settings
export BASH_SILENCE_DEPRECATION_WARNING=1     # Make osx Sonoma shut up about using bash
#defaults write com.apple.dock autohide-delay -float 0   # Remove the auto-hiding Dock delay
#defaults write com.apple.dock autohide-time-modifier -float 0  # Remove the animation when hiding/showing the Dock

# Terminal aliases
alias l='ls -l'
alias terraform='tf'
alias vim="vim -S ~/.vimrc"
alias gl="git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)\' --all"

# Terminal settings
eval "$(/opt/homebrew/bin/brew shellenv)"  # Set PATH, MANPATH, etc., for Homebrew.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export SHELL_SESSION_HISTORY=100000
export HISTFILESIZE=
export HISTSIZE=
unset LC_CTYPE   #  Sometimes LC_CTYPE is set, which annoys ssh sessions
# secretive enable git commit signing
export SSH_AUTH_SOCK="${HOME}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
#export SSH_AUTH_SOCK=""   # disable ssh-agent which makes multiple gitlab accounts fuck up

# Terminal colors
export TERM=xterm-color
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
RED='\033[0;31m'
NOCOLOR='\033[0m'

# Path settings
export PATH="${HOME}/.gem/ruby/3.2.0/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="${HOME}/.local/bin:$PATH"

# Various completion
[[ -r "${HOME}/git/git-completion.bash" ]] && builtin source "${HOME}/git/git-completion.bash"
[[ -r "${HOME}/lib/oci_autocomplete.sh" ]] && builtin source "${HOME}/lib/oci_autocomplete.sh"
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && builtin source "/opt/homebrew/etc/profile.d/bash_completion.sh"

# Setup a nice gitprompt
[[ -r "$HOME/.bash-git-prompt/gitprompt.sh" ]] && builtin source "$HOME/.bash-git-prompt/gitprompt.sh"
export GIT_PROMPT_ONLY_IN_REPO=0
function prompt_callback {  # Show aws account info if authenticated to AWS
  if [ -n "$AWS_SESSION_EXPIRATION" ]; then
          ttl=$(( ($(gdate -d "$AWS_SESSION_EXPIRATION" +%s) - $(gdate +%s))/(60)))
  elif [[ -n "$AWS_SSO_SESSION_EXPIRATION" ]]; then
          ttl=$(( ($(date -j -f "%Y-%m-%d %H:%M:%S %z %Z" "$AWS_SSO_SESSION_EXPIRATION" "+%s") - $(date "+%s"))/(60)))
  fi
  if [ -n "$AWS_SSO_PROFILE" ]; then echo -en " ${RED}($AWS_SSO_PROFILE)${NOCOLOR} ttl: ${ttl}min"; fi
}

# BEGIN_AWS_SSO_CLI - configured by the aws-sso command
__aws_sso_profile_complete() {
    COMPREPLY=()
    local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
    local cur
    _get_comp_words_by_ref -n : cur

    COMPREPLY=($(compgen -W '$(/opt/homebrew/bin/aws-sso $_args list --csv -P "Profile=$cur" Profile)' -- ""))

    __ltrim_colon_completions "$cur"
}

aws-sso-profile() {
    local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
    if [ -n "$AWS_PROFILE" ]; then
        echo "Unable to assume a role while AWS_PROFILE is set"
        return 1
    fi
    eval $(/opt/homebrew/bin/aws-sso $_args eval -p "$1")
    if [ "$AWS_SSO_PROFILE" != "$1" ]; then
        return 1
    fi
}

aws-sso-clear() {
    local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
    if [ -z "$AWS_SSO_PROFILE" ]; then
        echo "AWS_SSO_PROFILE is not set"
        return 1
    fi
    eval $(aws-sso eval $_args -c)
}

complete -F __aws_sso_profile_complete aws-sso-profile
complete -C /opt/homebrew/bin/aws-sso aws-sso
complete -C aws_completer aws

# END_AWS_SSO_CLI

_complete_ssh_hosts ()
{
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        comp_ssh_hosts=$(cat ~/.ssh/*config* | \
                        grep -i "^Host " | \
                        awk '{print $2 " " $3 " " $4}' | \
                        tr " " "\n" | \
                        sed '/^$/d';
                )

        COMPREPLY=( $(compgen -W "${comp_ssh_hosts}" -- $cur))
        return 0
}
complete -F _complete_ssh_hosts ssh

_complete_aws ()
{
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        comp_aws=$(cmd < ~/.aws/config | \
                        grep -E '\[profile' | \
                        tr ']' ' ' | \
                        awk '{print $2}';)

        COMPREPLY=( $(compgen -W "${comp_aws}" -- $cur))
        return 0
}
complete -F _complete_aws auth
complete -C '/opt/homebrew/bin/aws_completer' aws

curl_time() {
    curl -sD - -w "\
     nslookup:  %{time_namelookup}s\n\
      connect:  %{time_connect}s\n\
   sslconnect:  %{time_appconnect}s\n\
  pretransfer:  %{time_pretransfer}s\n\
     redirect:  %{time_redirect}s\n\
         TTFB:  %{time_starttransfer}s\n\
 size request:  %{size_request} Bytes\n\
  size upload:  %{size_upload} Bytes\n\
  uploadspeed:  %{speed_upload} byte/sec\n\
  size header:  %{size_header} Bytes\n\
size download:  %{size_download} Bytes\n\
downloadspeed:  %{speed_download} byte/sec \n\
-------------------------\n\
        total:  %{time_total}s\n" "$@"
}


tf() {
  echo "${FUNCNAME[0]} called from .bash_profile"
  cmd="/opt/homebrew/bin/terraform $*"
  if [ -n "$AWS_SESSION_EXPIRATION" ]; then
          ttl=$(( ($(gdate -d "$AWS_SESSION_EXPIRATION" +%s) - $(gdate +%s))/(60)))
  elif [[ -n "$AWS_SSO_SESSION_EXPIRATION" ]]; then
          ttl=$(( ($(date -j -f "%Y-%m-%d %H:%M:%S %z %Z" "$AWS_SSO_SESSION_EXPIRATION" "+%s") - $(date "+%s"))/(60)))
  else
      read -r -p "*** No aws token found - proceed ? [y/N] " response
      case "$response" in
        [yY][eE][sS]|[yY])
        echo "Proceeding..."
        eval "$cmd"
        ;;
      *)
        echo "Exiting..."
        return
        ;;
      esac
      echo "Exiting..."
      return
  fi
  if [[ $ttl -lt 10 ]]; then
    echo "***"
    echo "*** Warning: Token expires in less than 10 minuttes. Continue? "
    echo "***"
    read -r answer
    if [ ${#answer} -eq 0 ]; then
      eval "$cmd"
    fi
  else
    eval "$cmd"
  fi
}


# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.post.bash"
