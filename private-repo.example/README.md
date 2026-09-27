# Private repo: starter skeleton

This folder is a **worked example**, not something the public `ansible` repo
uses at run time. It shows exactly what your own private repo should
contain if you want to run this project with your real environment instead
of the sanitized example data.

## Why two repos

The public `ansible` repo (this one) works standalone against the example
`ubuntu`/`ubuntu_docker`/`wsl` hosts and the sanitized example inventory in
its own root `hosts.yml`, with every private value falling back to an empty
role default. Nothing you'd rather not publish (real hostnames/IPs, SSH keys,
CA certs, a branded login banner, a PAT) needs to live in a public repo. It
all lives in the private repo, which this folder mirrors:

```
private-repo.example/
  hosts.yml                    # your real inventory
  group_vars/all/private.yml   # your real keys/certs/banner/PAT/account name
  opentofu/prod.tfvars      # site.yml: the Proxmox servers and the VMs on them
  komodo/stacks/<host>.toml    # site.yml: each host's Komodo Stacks, generated
```

Each file owns one kind of fact, and the host name links them. `hosts.yml`
says what a host is and which stacks it runs. `opentofu/prod.tfvars`
describes its VM: where it runs, its size, disks and network. The files under
`komodo/stacks/` are written by `komodo-sync.yml` from `hosts.yml` and
docker-stacks' `komodo.env` files, and Komodo's Resource Sync reads them from
this repo. This folder has none, since they are generated; run
`komodo-sync.yml` against this inventory to see them.

The first two files are all that `provision.yml` needs. The other two only
matter to `site.yml`.

## Building your own

1. Create a new **private** git repo (e.g. `fleet-private`).
2. Copy this folder's files into it, at the same relative paths. If
   you've also forked the public `ansible` repo under your own GitHub
   account, set `github_user` in *its* `group_vars/all/vars.yml` to match.
   That's the only place your GitHub username needs to be recorded.
3. Fill in your real values. See the comments in `group_vars/all/private.yml`
   for what each variable drives and which role reads it.
4. Generate the Komodo sync files, from a checkout of the public repo, and
   commit them to the private repo:
   ```bash
   ansible-playbook -i /path/to/fleet-private/hosts.yml komodo-sync.yml
   ```
   Run it again whenever a host's `docker_stacks` changes, or a stack's
   `komodo.env` changes in docker-stacks. `site.yml` stops at a host whose
   committed file is out of date.
5. Check it out next to the public repo and point Ansible at its inventory.
   Ansible loads the `group_vars/` folder next to an inventory file, and the
   roles find `opentofu/` and `komodo/` there too, so nothing is copied:
   ```bash
   cd ansible
   ansible-playbook -i ../fleet-private/hosts.yml provision.yml -e target=<host>
   ```
   Both stay ordinary git checkouts. Commit and push changes to the private
   repo from its own folder, as with any other repo.

Semaphore reads the inventory straight from the private repo, so a pushed
change applies to its next run. New VMs clone it on first boot when
`ansible_private_repo_token` is set: a fine-grained GitHub PAT scoped
read-only to just this repo. Nothing in these files is a true secret on its
own, but there's no reason to make the clone any more open than it needs to
be.
