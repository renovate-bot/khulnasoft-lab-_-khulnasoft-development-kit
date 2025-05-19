nginx-setup: nginx/conf/nginx.conf nginx/logs nginx/tmp

nginx/logs:
	$(Q)mkdir -p $@

nginx/tmp:
	$(Q)mkdir -p $@
