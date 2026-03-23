# Homelab Ansible

## Hosts

| Host | Group | IP | OS |
|------|-------|-----|-----|
| nas | deb | 10.0.0.2 | Debian |
| transcoder | nixos | 10.0.0.11 | NixOS |

## Project Structure

```
ansible/
  playbooks/
    site.yml                  # main playbook
  inventory/
    hosts.yml                 # host definitions
    host_vars/                # per-host variables (enabled_services, GPU, etc.)
    group_vars/all/
      main.yml                # shared variables (paths, ports, domains)
      vault.yml               # encrypted secrets
  roles/
    common/                   # base system setup (deb hosts)
    docker/                   # docker installation (deb hosts)
    git-setup/                # git + SSH keys (all hosts)
    nixos-rebuild/            # flake rebuild (nixos hosts)
    nfs-server/               # NFS exports (nas)
    services/                 # service deployment orchestration
  services/                   # per-service definitions (see below)
```

## Services

Each service lives in `services/<name>/` with:

```
services/<name>/
  templates/
    compose.yml.j2            # required — docker compose definition
    .env.j2                   # optional — environment variables
    <extra>.j2                # optional — additional config files
  hooks/
    pre.yml                   # optional — runs before deploy
    post.yml                  # optional — runs after deploy
```

### Deploy loop

For each service in `enabled_services` (defined per host in `host_vars/`), the deployment runs:

1. **Pre-hook** — `hooks/pre.yml` if it exists (e.g., generate credentials, create directories)
2. **Deploy** — create config dir, template all files, `docker compose up`
3. **Post-hook** — `hooks/post.yml` if it exists (e.g., install plugins, configure integrations)

### Adding a new service

1. Create `services/<name>/templates/compose.yml.j2`
2. Add the service to `enabled_services` in the appropriate `host_vars/` file
3. Add a port to `service_ports` in `group_vars/all/main.yml` if needed
4. Optionally add `hooks/pre.yml` or `hooks/post.yml` for setup steps

## Usage

Deploy everything:

```bash
ansible-playbook playbooks/site.yml
```

Deploy only services (skip system setup):

```bash
ansible-playbook playbooks/site.yml --tags services
```

Deploy on a specific host:

```bash
ansible-playbook playbooks/site.yml --limit nas --tags services
```

Deploy specific services (comma-separated, deploys only on hosts where they're enabled):

```bash
ansible-playbook playbooks/site.yml -e deploy_services=jellyfin,navidrome
```

Combine both:

```bash
ansible-playbook playbooks/site.yml --limit nas -e deploy_services=jellyfin
```

Dry run (check mode):

```bash
ansible-playbook playbooks/site.yml --tags services --check --diff
```

## Vault

Secrets are stored in `inventory/group_vars/all/vault.yml`, encrypted with ansible-vault. The vault password file is at the repo root (`.vault_pass`, gitignored).

Edit secrets:

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

Add a new secret:

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
# Add: vault_my_secret: "value"
```

Reference in templates as `{{ vault_my_secret }}`. Convention: all vault variables are prefixed with `vault_`.
