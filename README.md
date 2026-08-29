# ansible

Ansible playbooks for provisioning and hardening hosts (Proxmox VE/PBS/PMG,
Docker hosts, plain Ubuntu boxes, etc).

This repo is fully self-contained and runs out of the box against the
included example inventory (`hosts.yml`) with sanitized placeholder data -
no real hostnames, keys, certs, or credentials required. See
[Using your own environment](#using-your-own-environment) below to layer
your real data on top.

## Quick start

Needs ansible-core >= 2.15 (for `ansible.builtin.deb822_repository`) - the
`ansible` apt package is recent enough on current Debian/Ubuntu releases.

```bash
sudo apt install git ansible sudo python3-netaddr python3-jmespath sshpass figlet

git clone https://github.com/myah-mitchell/ansible /tmp/ansible
cd /tmp/ansible

ansible-galaxy install -r requirements.yml

ansible-playbook -i hosts.yml -c local provision.yml \
  -e '{"target":"ubuntu", "server_password":"", "short_name":"", "abbr_name":"", "location_abbr":"", "domain_name":""}'
```

(`figlet` renders the SSH login banner's org name as ASCII art - see
`roles/ssh/tasks/ssh.yml`. `python3-netaddr` backs the `ansible.utils.ipaddr`
filter the `pve`/`vrrp` roles use, and `python3-jmespath` backs the
`json_query` filter - used by `provision.yml`'s own target-selection prompt as
well as the `pve` role, so it's needed for every run, not just `pve` hosts.
Both run on the control node, so they need to be importable by whichever
Python `ansible-playbook` itself runs under.)

### Running from a virtualenv instead

Everything above installs straight into system Python. If you'd rather keep
this repo's dependencies isolated (or don't have apt access to it on this
particular machine), use a venv for the Python side instead - `figlet` and
`sudo` are still plain system packages either way, a venv doesn't cover
those:

```bash
sudo apt install git python3-venv sshpass figlet

git clone https://github.com/myah-mitchell/ansible /tmp/ansible
cd /tmp/ansible

python3 -m venv .venv
source .venv/bin/activate
pip install ansible-core netaddr jmespath

ansible-galaxy install -r requirements.yml

ansible-playbook -i hosts.yml -c local provision.yml \
  -e '{"target":"ubuntu", "server_password":"", "short_name":"", "abbr_name":"", "location_abbr":"", "domain_name":""}'
```

Re-run `source .venv/bin/activate` in any new shell before using
`ansible-playbook`/`ansible-galaxy` again.

### Running against a remote host

The commands above use `-c local` against the bundled example inventory
(`127.0.0.1`) - everything runs on the machine you invoke `ansible-playbook`
from. To provision an actual remote host over SSH instead:

1. Point a host's `ansible_host` at its real address - edit `hosts.yml`
   directly, or set it in your private overlay's copy (see
   [Using your own environment](#using-your-own-environment)).
2. Drop `-c local` so Ansible connects over SSH instead of running locally.
3. A brand-new host has no `ansible` service account yet - that's exactly
   what the `users` role creates on first run - so connect as `root` or an
   existing sudo-capable user for that first pass:

```bash
ansible-playbook -i hosts.yml provision.yml \
  -e '{"target":"pve_host_h", "server_password":"", "short_name":"", "abbr_name":"", "location_abbr":"", "domain_name":""}' \
  -u root --ask-pass --ask-become-pass
```

- `-u root` picks the connecting user, overriding the `users` role's default
  (`ansible_account`, `"ansible"` - an account that only exists once this
  role has already run against the host once).
- `--ask-pass` prompts for the SSH password (this is what `sshpass` in the
  prereqs is for); use `--private-key <path>` instead if you're using key
  auth.
- `--ask-become-pass` prompts for `root`'s password for privilege escalation
  - drop it if that account already has passwordless sudo, or if you
  connected as `root` directly (escalation is then a no-op).

On later runs, once the `users` role has created the `ansible` account and
installed your `ansible_ssh_public_keys` on it, drop `-u root` and the
password flags - Ansible connects as `ansible_account` with key auth
automatically.

## Using your own environment

All the real, private stuff - hostnames, internal IPs, SSH public keys, CA
certs, a branded login banner, a read-only PAT for the private
`ansible-private` repo itself (used to bootstrap fresh VMs - see the `pve`
role), the human admin account name - collapses into exactly **two files**:

- `hosts.yml` - the inventory (topology, per-host/group vars)
- `group_vars/all/private.yml` - everything else, auto-loaded by Ansible for
  every host

Everything else in this repo is generic automation with safe, empty/generic
defaults, so it never needs to change per environment.

To use your own data: build a small private repo containing just those two
files (see [`private-repo.example/`](private-repo.example/) for a
ready-to-copy skeleton and full instructions), then before running
`ansible-playbook`, drop your real files in over the sanitized ones:

```bash
./scripts/bootstrap-private.sh https://github.com/<you>/ansible-private
```

A fine-grained, read-only GitHub PAT scoped to just that one private repo
(passed via `PRIVATE_REPO_TOKEN`) is enough - see the script's header
comment and `private-repo.example/README.md` for details.

## Forking

The GitHub user/org this repo (and the sibling `dotfiles` and
`ansible-private` repos it clones) lives under is a single variable -
`github_user` in [`group_vars/all/vars.yml`](group_vars/all/vars.yml).
Change it to your own username/org and every clone URL in the roles follows.

## Structure

- `hosts.yml` - inventory (sanitized example data by default)
- `provision.yml` - the single entry-point playbook; roles are tag-selectable
- `group_vars/all/private.yml` - the private-data variables described above
- `group_vars/all/vars.yml` - shared non-sensitive defaults meant to be
  edited directly in a fork (currently just `github_user`)
- `roles/` - one role per concern (users, ssh, certificates, firewall, pve,
  pbs, pmg, docker, monitoring, ...). `pve` also builds and refreshes the
  Proxmox cloud-init VM template from its own `templates/cloudinit-vendor.yml.j2`
  and `templates/create-cloud-init-template.sh.j2`.
- `private-repo.example/` - worked example of what a private overlay repo
  should contain
- `scripts/bootstrap-private.sh` - drops a private overlay's two files into
  a checkout of this repo
