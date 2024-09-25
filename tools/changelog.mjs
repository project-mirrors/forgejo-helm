import { getChangelog } from './changelog/util.js';
import fs from 'node:fs';

const file = process.argv[3]
  ? fs.createWriteStream(process.argv[3])
  : process.stdout;

getChangelog(process.argv[2], !!process.argv[2]).pipe(file);
