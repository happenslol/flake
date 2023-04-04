SSH_ENV="$HOME/.ssh/agent-environment"

function start_agent {
  ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
  chmod 600 "${SSH_ENV}"
  . "${SSH_ENV}" > /dev/null
  ssh-add "$HOME/.ssh/$(hostname).personal.id_ed25519" &> /dev/null
  ssh-add "$HOME/.ssh/$(hostname).opencreek.id_ed25519" &> /dev/null
  ssh-add "$HOME/.ssh/$(hostname).garage51.id_ed25519" &> /dev/null
}

if [[ -f "${SSH_ENV}" ]]; then
  . "${SSH_ENV}" > /dev/null

  ps -ef | \
    grep ${SSH_AGENT_PID} | \
    grep ssh-agent$ > /dev/null || \
    { start_agent } || true
else
  start_agent || true
fi
