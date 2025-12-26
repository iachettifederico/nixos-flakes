# Ruby Development Environment Setup

This NixOS configuration provides automatic Ruby environment loading using direnv and nixpkgs-ruby.

## How It Works

Your system now has:
- **direnv + nix-direnv**: Automatically loads environments when entering directories
- **bundix**: Converts Gemfile.lock to gemset.nix for Nix-managed gems
- **All Ruby versions**: Available from nixpkgs-ruby (hundreds of versions!)
- **Native gem support**: Each Ruby environment includes build tools (gcc, make, pkg-config) and common libraries (libyaml, openssl, zlib, readline) needed to compile gems with native extensions

## Quick Start

For each Ruby project, you need just two simple files:

### 1. Create `.ruby-version`

```bash
echo "ruby-3.4.2" > .ruby-version
```

**Important:** Use the format `ruby-X.Y.Z` (with the `ruby-` prefix, not just `X.Y.Z`)

### 2. Create `.envrc`

```bash
cat > .envrc << 'EOF'
RUBY_VERSION=$(cat .ruby-version)
use flake "/home/fedex/nixos-flakes-azula#\"${RUBY_VERSION}\""
EOF
```

**Notes:** 
- Replace `/home/fedex/nixos-flakes-azula` with your NixOS config path if different
- The escaped quotes `\"` are required because version names contain dots
- You can also hardcode the version: `use flake "/home/fedex/nixos-flakes-azula#\"ruby-3.4.2\""`

### 3. Allow direnv

```bash
direnv allow
```

That's it! Ruby will now automatically load when you enter this directory.

## Complete Example

```bash
# Navigate to your Ruby project
cd ~/code/podcast_app

# Step 1: Create .ruby-version with the ruby- prefix
echo "ruby-3.4.2" > .ruby-version

# Step 2: Create .envrc (note: single quotes preserve the literal string)
cat > .envrc << 'EOF'
RUBY_VERSION=$(cat .ruby-version)
use flake "/home/fedex/nixos-flakes-azula#\"${RUBY_VERSION}\""
EOF

# Step 3: Allow direnv to load the environment
direnv allow

# Now Ruby is automatically available!
ruby --version
# Output: ruby 3.4.2 (2025-02-15 revision d2930f8e7a) +PRISM [x86_64-linux]

# Bundler works normally, including gems with native extensions
bundle install
# This will compile native gems like psych (YAML), nokogiri (XML), puma (HTTP server), etc.

# bundix is available system-wide if you need Nix-managed gems
bundix --version
```

## Switching Ruby Versions

To switch to a different Ruby version in a project:

```bash
# Update .ruby-version to the new version
echo "ruby-3.2.9" > .ruby-version

# Reload direnv (happens automatically when you cd, or manually:)
direnv reload

# Verify the new version
ruby --version
# Output: ruby 3.2.9 (...)
```

## Available Ruby Versions

Hundreds of versions are available from nixpkgs-ruby! 

### Specific Versions (Recommended)
- `ruby-3.4.7`, `ruby-3.4.2`, `ruby-3.4.1`, `ruby-3.4.0`
- `ruby-3.3.10`, `ruby-3.3.6`, `ruby-3.3.5`, etc.
- `ruby-3.2.9`, `ruby-3.2.2`, `ruby-3.2.1`, etc.
- `ruby-3.1.7`, `ruby-3.1.4`, etc.
- `ruby-3.0.7`, `ruby-3.0.6`, etc.
- `ruby-2.7.8`, etc.

### Wildcard Versions (Auto-updates)
You can also use wildcard versions that automatically resolve to the latest:
- `ruby-3.4` → latest 3.4.x (currently 3.4.7)
- `ruby-3.3` → latest 3.3.x (currently 3.3.10)
- `ruby-3` → latest 3.x (currently 3.4.7)
- `ruby-2` → latest 2.x (currently 2.7.8)

**Note:** Wildcards like `ruby-3.4.*` also work but aren't commonly needed.

### List All Available Versions

```bash
# See all available Ruby versions
nix flake show github:bobvanderlinden/nixpkgs-ruby --json 2>/dev/null | \
  jq -r '.packages."x86_64-linux" | keys[]' | \
  grep "^ruby-[0-9]" | \
  sort -V
```

Or check your local flake:
```bash
cd /home/fedex/nixos-flakes-azula
nix flake show --json 2>/dev/null | \
  jq -r '.packages."x86_64-linux" | keys[]' | \
  grep "^ruby-[0-9]" | \
  sort -V | head -20
```

## Native Gem Compilation

The development environment includes all necessary build dependencies for compiling Ruby gems with native extensions:

- **C compiler**: gcc
- **Build tools**: make, pkg-config
- **Libraries**: libyaml (psych/YAML), openssl (SSL), zlib (compression), readline (interactive input)

Common gems that work out of the box:
- `psych` (YAML parsing)
- `nokogiri` (XML/HTML parsing)
- `puma` (HTTP server)
- `pg` (PostgreSQL)
- `sqlite3` (SQLite database)
- `msgpack` (MessagePack)
- `nio4r` (async I/O)
- `websocket-driver` (WebSocket)
- And many more!

If a gem requires additional libraries not included by default, you can add them to the `buildInputs` in `flake.nix`.

## Troubleshooting

### Error: "undefined variable 'ruby-ruby-3.4.2'"

This means your `.ruby-version` file has the wrong format. It should be:
```
ruby-3.4.2
```
NOT:
```
3.4.2
```

### Error: "does not provide attribute 'devShells.x86_64-linux.ruby-3.4.2'"

Check that your `.envrc` has the proper escaping with `\"`:
```bash
use flake "/home/fedex/nixos-flakes-azula#\"${RUBY_VERSION}\""
```

### direnv not loading automatically

Make sure you've run:
```bash
direnv allow
```

And verify direnv is enabled in your shell. For zsh (which is configured system-wide):
```bash
# Should be in your ~/.zshrc already from the NixOS config
eval "$(direnv hook zsh)"
```

### Rebuild NixOS if you haven't yet

If this is your first time using this setup, make sure you've applied the configuration:
```bash
sudo nixos-rebuild switch --impure --flake "/home/fedex/nixos-flakes-azula#azula"
```

### Check Ruby is working

Test the devShell directly without direnv:
```bash
nix develop '/home/fedex/nixos-flakes-azula#"ruby-3.4.2"' --command ruby --version
```

## Multiple Projects, Different Versions

Each project can use a different Ruby version independently:

```bash
# Project A uses Ruby 3.4.2
cd ~/projects/project-a
echo "ruby-3.4.2" > .ruby-version
# ... create .envrc ...

# Project B uses Ruby 3.2.9
cd ~/projects/project-b
echo "ruby-3.2.9" > .ruby-version
# ... create .envrc ...

# Switching between them is automatic:
cd ~/projects/project-a
ruby --version  # → ruby 3.4.2

cd ~/projects/project-b
ruby --version  # → ruby 3.2.9
```
