source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH:/Applications/development/flutter/bin"
export HOMEBREW_NO_AUTO_UPDATE=1
export LANG=en_US.UTF-8export PATH="/opt/homebrew/opt/php@8.0/bin:$PATH"
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=$HOME/.composer/vendor/bin:$PATH
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
export PATH="/opt/homebrew/opt/php@8.2/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.2/sbin:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH:/opt/metasploit-framework/bin/"
export PATH="/usr/local/mysql/bin:$PATH"


# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/sam/Library/Application Support/Herd/config/php/83/"


# Herd injected PHP binary.
export PATH="/Users/sam/Library/Application Support/Herd/bin/":$PATH
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.3/sbin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/sam/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/sam/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/sam/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/sam/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
alias mysqlstart='sudo /usr/local/mysql/support-files/mysql.server start'
alias mysqlstop='sudo /usr/local/mysql/support-files/mysql.server stop'

# Added by Antigravity
export PATH="/Users/sam/.antigravity/antigravity/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

. "$HOME/.local/bin/env"

export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
