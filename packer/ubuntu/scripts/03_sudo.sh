# Enable carrying over the ssh-agent and PATH variables into sudo commands.
sed -i -e '/Defaults\s\+env_reset/a Defaults\tenv_keep = "SSH_AUTH_SOCK PATH"' /etc/sudoers
