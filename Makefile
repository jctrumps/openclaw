SHELL := /bin/bash
.PHONY: init fmt validate plan apply destroy ping deploy status
init:
	cd opentofu && tofu init
fmt:
	tofu fmt -recursive opentofu
validate:
	cd opentofu && tofu validate
plan:
	cd opentofu && tofu plan -out=openclaw.tfplan
apply:
	cd opentofu && tofu apply openclaw.tfplan
destroy:
	cd opentofu && tofu destroy
ping:
	cd ansible && ANSIBLE_CONFIG="$$PWD/ansible.cfg" ansible -i inventory/hosts.ini openclaw -m ping
deploy:
	cd ansible && ANSIBLE_CONFIG="$$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
status:
	@echo 'Use: ssh -i ~/.ssh/openclaw_01_ed25519 ubuntu@<VM_IP>'
	@echo 'Then: cd /opt/openclaw && docker compose ps'
