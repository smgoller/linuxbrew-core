workflow "Push" {
  on = "push"
  resolves = ["Generate formulae.brew.sh"]
}

action "Generate formulae.brew.sh" {
  uses = "docker://linuxbrew/brew"
  runs = ".github/linux.workflow.sh"
  secrets = ["ANALYTICS_JSON_KEY", "FORMULAE_DEPLOY_KEY"]
}
