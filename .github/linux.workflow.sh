#!/bin/bash

set -e

# silence bundler complaining about being root
mkdir ~/.bundle
echo 'BUNDLE_SILENCE_ROOT_WARNING: "1"' > ~/.bundle/config

# configure git
git config --global user.name "BrewTestBot"
git config --global user.email "homebrew-test-bot@lists.sfconservancy.org"

# create stubs so build dependencies aren't incorrectly flagged as missing
for i in python svn unzip xz
do
  touch /usr/bin/$i
  chmod +x /usr/bin/$i
done

CORE_DIR="$(brew --repo homebrew/core)"
mkdir -p "$CORE_DIR"
rm -rf "$CORE_DIR"
ln -s "$PWD" "$CORE_DIR"

# Get latest
git -C "$CORE_DIR" fetch
git -C "$CORE_DIR" checkout -f master
git -C "$CORE_DIR" reset --hard origin/master

# setup Homebrew environment
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export PATH="$(brew --repo)/Library/Homebrew/vendor/portable-ruby/current/bin:$PATH"

# setup SSH
mkdir ~/.ssh
chmod 700 ~/.ssh
echo "$FORMULAE_DEPLOY_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
git config --global core.sshCommand "ssh -i ~/.ssh/id_ed25519 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# clone formulae.brew.sh with SSH so we can push back

# Issy: None of this will work until we switch to Homebrew org repos,
# and give it a key, etc. etc. Also we'll need to merge the
# formulae.brew.sh branch on Issy's fork into master. This checks out
# a branch so we can run `rake formula_linux`.
git clone git@github.com:issyl0/formulae.brew.sh
cd formulae.brew.sh
git checkout generated_linux_formulae

# setup analytics
echo "$ANALYTICS_JSON_KEY" > ~/.homebrew_analytics.json
unset HOMEBREW_NO_ANALYTICS

# run rake (without a rake binary)
ruby -e "load Gem.bin_path('rake', 'rake')" formulae_linux

# commit and push generated files
git add _data/formula-linux api/formula-linux formula-linux
git diff --exit-code HEAD -- _data/formula-linux api/formula-linux formula-linux && exit 0
git commit -m 'formula: update from Homebrew/linuxbrew-core push' _data/formula-linux api/formula-linux formula-linux
git push
