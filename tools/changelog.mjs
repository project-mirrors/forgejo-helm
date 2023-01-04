import conventionalChangelogCore from 'conventional-changelog-core';
import conventionalChangelogPreset from 'conventional-changelog-conventionalcommits';
import fs from "node:fs"

const config = conventionalChangelogPreset();

const file = process.argv[3] ? fs.createWriteStream(process.argv[3]): process.stdout;

conventionalChangelogCore(
  {
    config,
    releaseCount: 2,
  },
  { version: process.argv[2], linkCompare: false },
  undefined,
  undefined,
  { headerPartial: '' }
).pipe(file);
