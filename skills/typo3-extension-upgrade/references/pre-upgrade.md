# Pre-Upgrade Checklist

Use this checklist before starting a TYPO3 extension upgrade.

## Repository Status

- [ ] Git repository is clean (`git status` shows no changes)
- [ ] On main/master branch
- [ ] All tests passing on current version
- [ ] CI/CD pipeline green

## Current State Assessment

- [ ] Document current TYPO3 version support
- [ ] Document current PHP version requirement
- [ ] List all deprecated API usages (run PHPStan with deprecation rules)
- [ ] Identify database-related code (for DBAL migration)
- [ ] Check for direct `$GLOBALS['TSFE']` usage
- [ ] Check for `GeneralUtility::_GET/POST/GP` usage
- [ ] Check for `PDO::PARAM_*` constants

## Dependency Check

- [ ] Review `composer.json` dependencies
- [ ] Check for abandoned packages
- [ ] Verify testing framework compatibility
- [ ] Check Rector/PHPStan version requirements

## Backup & Branch

- [ ] Create feature branch: `git checkout -b feature/typo3-v12-v13-upgrade`
- [ ] Tag current state: `git tag v-before-upgrade`
- [ ] Ensure local development environment works

## Environment Setup

- [ ] DDEV or local environment ready
- [ ] Can install TYPO3 v12.4 LTS
- [ ] Can install TYPO3 v13.4 LTS
- [ ] Database access configured

## Documentation Review

- [ ] Read TYPO3 v12 changelog: https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog/12.0/Index.html
- [ ] Read TYPO3 v13 changelog: https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog/13.0/Index.html
- [ ] Review breaking changes relevant to extension

## Team Communication

- [ ] Inform team about upgrade work
- [ ] Set up review process for changes
- [ ] Plan testing strategy
