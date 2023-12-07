import { Command, runExit } from 'clipanion';
import { getChangelog } from './changelog/util.js';

const api = 'https://https://codeberg.org/api/v1';
const repo = 'forgejo-contrib/forgejo-helm';

class GiteaReleaseCommand extends Command {
  async execute() {
    const token = process.env.GITHUB_TOKEN;

    if (!token) {
      this.context.stdout.write('GITHUB_TOKEN environment variable not set.\n');
      return 1;
    }

    this.context.stdout.write(`Getting tag.\n`);
    const tag = process.env.GITHUB_REF_NAME;

    if (!tag) {
      this.context.stdout.write(
        'No tag found for this commit. Please tag the commit and try again.\n',
      );
      return 1;
    }

    this.context.stdout.write(`Checking remote tag ${tag}.\n`);
    let resp = await fetch(`${api}/repos/${repo}/tags/${tag}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!resp.ok) {
      this.context.stdout.write(`Tag ${tag} not found on remote.\n`);
      return 1;
    }

    this.context.stdout.write(`Checking remote release ${tag}.\n`);
    resp = await fetch(`${api}/repos/${repo}/releases/tags/${tag}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    if (resp.ok) {
      this.context.stdout.write(`Release ${tag} already exists.\n`);
      return 1;
    } else if (resp.status !== 404) {
      this.context.stdout.write(
        `Error checking for release ${tag}.\n${resp.status}: ${resp.statusText}\n`,
      );
      return 1;
    }

    const stream = getChangelog(tag, true).setEncoding('utf8');
    const changes = (await stream.toArray()).join('');

    this.context.stdout.write(`Creating release ${tag}.\n`);
    resp = await fetch(`${api}/repos/${repo}/releases`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        draft: false,
        prerelease: tag.includes('-'),
        tag_name: tag,
        name: tag.replace(/^v/, ''),
        body: changes,
        target_commitish: 'main',
      }),
    });

    if (!resp.ok) {
      this.context.stdout.write(
        `Error creating release ${tag}.\n${resp.status}: ${resp.statusText}\n`,
      );
      return 1;
    }
  }
}

void runExit(GiteaReleaseCommand);
