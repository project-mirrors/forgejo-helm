import { getChangelog } from './changelog/util.js';

const stream = getChangelog(!!process.argv[2]).setEncoding('utf8');

const changes = (await stream.toArray()).join('');

if (!changes.length) {
  console.error('No changelog found');
  process.exit(1);
}

process.stdout.write(changes);
