# ansible

Ansible playbooks for provisioning and hardening hosts (Proxmox VE/PBS/PMG,
Docker hosts, plain Ubuntu boxes, etc).

This repo is fully self-contained and runs out of the box against the
included example inventory (`hosts.yml`) with sanitized placeholder data. No real hostnames, keys, certs, or
credentials required. See
[Using your own environment](#using-your-own-environment) below to layer
your real data on top.

## Quick start

Needs ansible-core >= 2.15 (for `ansible.builtin.deb822_repository`). The
`ansible` apt package is recent enough on current Debian/Ubuntu releases.

```bash
sudo apt install git ansible sudo python3-netaddr python3-jmespath sshpass figlet

git clone https://github.com/myah-mitchell/ansible /tmp/ansible
cd /tmp/ansible

ansible-galaxy install -r requirements.yml

ansible-playbook -i hosts.yml -c local provision.yml \
  -e '{"target":"ubuntu", "server_password":"", "short_name":"", "abbr_name":"", "location_abbr":"", "domain_name":""}'
```

(`figlet` renders the SSH login banner's org name as ASCII art; see
`roles/ssh/tasks/ssh.yml`. `python3-netaddr` backs the `ansible.utils.ipaddr`
filter the `pve`/`vrrp` roles use, and `python3-jmespath` backs the
`json_query` filter, used by `provision.yml`'s own target-selection prompt as
well as the `pve` role, so it's needed for every run, not just `pve` hosts.
Both run on the control node, so they need to be importable by whichever
Python `ansible-playbook` itself runs under.)

`provision.yml` needs `server_password` and four identity values:
`short_name`, `abbr_name`, `location_abbr` and `domain_name`. The commands here
pass them with `-e`, which sets them for the whole run. They can also live in
the inventory, per host, per group, or fleet-wide under `all: vars:` in
`hosts.yml`, but only when `-e` leaves them out, since `-e` always wins.
Whatever neither sets is asked for once at the start of the run. Without a
terminal, as under Semaphore, nothing can be asked: a missing identity value
stops the run, and a missing `server_password` counts as empty, which leaves
every password as it is.

### Running from a virtualenv instead

Everything above installs straight into system Python. If you'd rather keep
this repo's dependencies isolated (or don't have apt access to it on this
particular machine), use a venv for the Python side instead. `figlet` and
`sudo` are still plain system packages either way, and a venv doesn't cover
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
(`127.0.0.1`): everything runs on the machine you invoke `ansible-playbook`
from. To provision an actual remote host over SSH instead:

1. Point a host's `ansible_host` at its real address: edit `hosts.yml`
   directly, or in your private repo's inventory (see
   [Using your own environment](#using-your-own-environment)).
2. Drop `-c local` so Ansible connects over SSH instead of running locally.
3. A brand-new host has no `ansible` service account yet (that's exactly
   what the `users` role creates on first run), so connect as `root` or an
   existing sudo-capable user for that first pass:

```bash
ansible-playbook -i hosts.yml provision.yml \
  -e '{"target":"pve_host_h", "server_password":"", "short_name":"", "abbr_name":"", "location_abbr":"", "domain_name":""}' \
  -u root --ask-pass --ask-become-pass
```

- `-u root` picks the connecting user, overriding the `users` role's default
  (`ansible_account`, `"ansible"`, an account that only exists once this
  role has already run against the host once).
- `--ask-pass` prompts for the SSH password (this is what `sshpass` in the
  prereqs is for); use `--private-key <path>` instead if you're using key
  auth.
- `--ask-become-pass` prompts for `root`'s password for privilege escalation.
  Drop it if that account already has passwordless sudo, or if you
  connected as `root` directly (escalation is then a no-op).

On later runs, once the `users` role has created the `ansible` account and
installed your `ansible_ssh_public_keys` on it, drop `-u root` and the
password flags. Ansible connects as `ansible_account` with key auth
automatically.

## From nothing to running stacks: site.yml

`site.yml` wraps `provision.yml` for Docker hosts built from the inventory. For
each host in `target` it creates the Proxmox VM through OpenTofu when the
private repo describes one for it (the `vms` role, running the
[opentofu](https://github.com/myah-mitchell/opentofu) repo), waits for its
first boot, runs `provision.yml` against it, then has Komodo deploy the host's
Stacks through a Resource Sync (the `komodo_stacks` role).

```bash
ansible-playbook -i /path/to/fleet-private/hosts.yml site.yml -e target=ex01
```

That assumes the identity values and `server_password` are in the inventory
(see [Quick start](#quick-start)). The VMs and the Proxmox servers they run
on are in the private repo's `opentofu/prod.tfvars`, keyed by the host's
`serverHostname` in lower case, and the VM's address there must match its
`ansible_host`. A host with no VM there is left alone, so a host built by hand
still gets provisioned and its Stacks deployed.

Each host's Stacks are in the private repo's `komodo/stacks/<host>.toml`,
which Komodo's Resource Sync reads. Those files are generated from the
inventory's `docker_stacks` and docker-stacks' `komodo.env` files:

```bash
ansible-playbook -i /path/to/fleet-private/hosts.yml komodo-sync.yml
```

Commit the result to the private repo. `site.yml` stops at a host whose
committed file no longer matches what `komodo-sync.yml` would write, so run it
after changing a host's stacks and before `site.yml`.

It needs `tofu` on the PATH, and reads OpenTofu's state encryption, Postgres
connection and Proxmox API tokens, and a Komodo API key, from environment
variables. `roles/vms/defaults/main.yml` and
`roles/komodo_stacks/defaults/main.yml` list them, and the run stops early
when one is missing. `--check` shows OpenTofu's plan and skips the sync. The
setup, including the Resource Sync and the Semaphore Template, is in
docker-stacks' `docs/one-run-provisioning.md`.

## Using your own environment

All the real, private stuff (hostnames, internal IPs, SSH public keys, CA
certs, a branded login banner, a read-only PAT for the private
`fleet-private` repo itself, used to bootstrap fresh VMs (see the `pve`
role), and the human admin account name) lives in a private repo:

- `hosts.yml`: the inventory (topology, per-host/group vars)
- `group_vars/all/private.yml`: everything else, auto-loaded by Ansible for
  every host
- `opentofu/prod.tfvars`: the Proxmox servers and VMs, for `site.yml`
- `komodo/stacks/<host>.toml`: each host's Komodo Stacks, generated by
  `komodo-sync.yml`, for `site.yml`

Everything else in this repo is generic automation with safe, empty/generic
defaults, so it never needs to change per environment.

To use your own data, build a private repo with those files (see
[`private-repo.example/`](private-repo.example/) for a ready-to-copy
skeleton and full instructions). Check it out next to this one, and point
Ansible at its inventory:

```
src/
  ansible/          # this repo
  fleet-private/    # yours
```

```bash
cd ansible
ansible-playbook -i ../fleet-private/hosts.yml provision.yml -e target=<host>
```

Ansible loads the `group_vars/` next to an inventory file, and the roles find
the other files next to it too, so nothing is copied between the two. Each
stays an ordinary git checkout: edit, commit and push the private one as
usual, and this one never changes. Semaphore does the same by reading the
inventory from the private repo, and new VMs do it on first boot (see the
`pve` role).

## Forking

The GitHub user/org this repo (and the sibling `dotfiles` and
`fleet-private` repos it clones) lives under is a single variable:
`github_user` in [`group_vars/all/vars.yml`](group_vars/all/vars.yml).
Change it to your own username/org and every clone URL in the roles follows.

## Structure

- `hosts.yml`: inventory (sanitized example data by default)
- `provision.yml`: the entry-point playbook for an existing host; roles are
  tag-selectable
- `site.yml`: creates missing VMs, then runs `provision.yml` and deploys the
  host's Komodo Stacks
- `komodo-sync.yml`: writes the private repo's `komodo/stacks/<host>.toml`
  files from the inventory
- `group_vars/all/vars.yml`: shared non-sensitive defaults meant to be
  edited directly in a fork (currently just `github_user`)
- `roles/`: one role per concern (users, ssh, certificates, firewall, pve,
  pbs, pmg, docker, stacks, monitoring, ...). `pve` also builds and refreshes the
  Proxmox cloud-init VM template from its own `templates/cloudinit-vendor.yml.j2`
  and `templates/create-cloud-init-template.sh.j2`.
- `private-repo.example/`: worked example of what the private repo should
  contain
