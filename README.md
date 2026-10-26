# dotfiles

Public bootstrap for my private `dev-setup` repo. No secrets or inventory live here.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/bgushurst/dotfiles/main/bootstrap.sh)"
```

It installs `gh` (Homebrew on macOS, apt on Debian/Ubuntu), runs `gh auth login`, clones `dev-setup` to `~/dev-setup`, asks which host this is (from `hosts.yaml`) and runs `scripts/<host>-setup.sh`. Set `DEV_SETUP_HOST` or `DEV_SETUP_DIR` to skip the prompt or change the path.
