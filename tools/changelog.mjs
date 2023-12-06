import conventionalChangelogCore from 'conventional-changelog-core';
import conventionalChangelogPreset from 'conventional-changelog-conventionalcommits';
import fs from 'node:fs';

const config = conventionalChangelogPreset({
  types: [
    {
      type: 'feat',
      section: 'Features',
    },
    {
      type: 'feature',
      section: 'Features',
    },
    {
      type: 'fix',
      section: 'Bug Fixes',
    },
    {
      type: 'perf',
      section: 'Performance Improvements',
    },
    {
      type: 'revert',
      section: 'Reverts',
    },
    {
      type: 'docs',
      section: 'Documentation',
    },
    {
      type: 'style',
      section: 'Styles',
    },
    {
      type: 'chore',
      section: 'Miscellaneous Chores',
    },
    {
      type: 'refactor',
      section: 'Code Refactoring',
    },
    {
      type: 'test',
      section: 'Tests',
    },
    {
      type: 'build',
      section: 'Build System',
    },
    {
      type: 'ci',
      section: 'Continuous Integration',
    },
  ],
});

const file = process.argv[3]
  ? fs.createWriteStream(process.argv[3])
  : process.stdout;

conventionalChangelogCore(
  {
    config,
    releaseCount: 2,
  },
  { version: process.argv[2], linkCompare: false },
  undefined,
  undefined,
  { headerPartial: '' },
).pipe(file);
