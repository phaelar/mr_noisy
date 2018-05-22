# MrNoisy

Pulls open merge request list from gitlab and lists them on a messaging client (i.e. Slack).

## Usage

Set the required environment variables: `SLACK_TOKEN`, `SLACK_CHANNEL`, `TELEGRAM_TOKEN`, `TELEGRAM_CHANNEL` and `GITLAB_TOKEN`.
```
mix run lib/mr_noisy
```
