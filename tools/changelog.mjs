import { getChangelog } from './changelog/util.js';

const changes = await getChangelog(!!process.argv[2]);

if (!changes.length) {
  console.error('No changelog found');
  process.exit(1);
}

process.stdout.write(changes);
