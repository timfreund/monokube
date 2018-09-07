# Monokube Ansible

So you want to use Ansible to manage your monokube nodes.

Ansible is written with python, so you'll need that.  The instructions
here are tested with python3 on Ubuntu 18.04, but it is open to bug
submissions and patches to make the instructions work elsewhere.

Run:

`setup.sh`

to configure a virtual environment, install Ansible in it, and install
all of the required ansible modules.

To activate the virtual environment:

`. ./venv/bin/activate`

To run a playbook that installs docker and makes other common initial
configurations:

`ansible-playbook ./playbooks/bootstrap.yml`

To run an arbitrary command on all nodes:

`ansible all -a "docker --version"`
