# Private overlay repo — starter skeleton

This folder is a **worked example**, not something the public `ansible` repo
uses at run time. It shows exactly what your own private repo should
contain if you want to run this project with your real environment instead
of the sanitized example data.

## Why two repos

The public `ansible` repo (this one) works standalone against the example
`ubuntu`/`ubuntu_docker`/`wsl` hosts and the sanitized example inventory in
its own root `hosts.yml`, with every private value defaulting to empty (see
`group_vars/all/private.yml` at the repo root). Nothing you'd rather not
publish — real hostnames/IPs, SSH keys, CA certs, a branded login banner, a
PAT — needs to live in a public repo. It all collapses into exactly **two
files**, which this folder mirrors:

```
private-repo.example/
  hosts.yml                    # your real inventory
  group_vars/all/private.yml   # your real keys/certs/banner/PAT/account name
```

## Building your own

1. Create a new **private** git repo (e.g. `ansible-private`).
2. Copy this folder's two files into it, at the same relative paths. If
   you've also forked the public `ansible` repo under your own GitHub
   account, set `github_user` in *its* `group_vars/all/vars.yml` to match —
   that's the only place your GitHub username needs to be recorded.
3. Fill in your real values — see the comments in `group_vars/all/private.yml`
   for what each variable drives and which role reads it.
4. At bootstrap time, clone both repos and copy your private repo's two
   files over the public repo's checkout, overwriting them in place:
   ```bash
   git clone https://github.com/myah-mitchell/ansible /tmp/ansible
   git clone https://x-access-token:${ANSIBLE_PRIVATE_PAT}@github.com/<you>/ansible-private /tmp/ansible-private
   cp /tmp/ansible-private/hosts.yml /tmp/ansible/hosts.yml
   cp /tmp/ansible-private/group_vars/all/private.yml /tmp/ansible/group_vars/all/private.yml
   ```
   `scripts/bootstrap-private.sh` at the root of the public repo wraps
   exactly this. `ANSIBLE_PRIVATE_PAT` should be a fine-grained GitHub PAT
   scoped read-only to just your private repo — nothing in either file is a
   true secret on its own, but there's no reason to make the clone itself
   any more open than it needs to be.
5. Run `ansible-galaxy install -r requirements.yml` and
   `ansible-playbook -i hosts.yml -c local provision.yml -e '{...}'` as
   normal — the copied files are picked up automatically (`hosts.yml` is the
   inventory Ansible is already pointed at; `group_vars/all/*.yml` is
   auto-loaded by Ansible for every host).

The working copy under `/tmp/ansible` becomes locally modified once your
private files are copied in — that's expected. Never commit or push back
from that checkout.
