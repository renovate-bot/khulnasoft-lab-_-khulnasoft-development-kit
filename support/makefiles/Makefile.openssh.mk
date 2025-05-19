openssh-setup: openssh/sshd_config $(sshd_hostkeys)

$(kdk_root)/openssh/ssh_host_%_key:
	$(Q)ssh-keygen -f $@ -N '' -t $*
