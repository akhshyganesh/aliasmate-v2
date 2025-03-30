#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import { addAlias } from './commands/add';
import { listAliases } from './commands/list';
import { removeAlias } from './commands/remove';
import { findAlias } from './commands/find';
import { exportAliases } from './commands/export';
import { importAliases } from './commands/import';
import { updateAlias } from './commands/update';
import { applyAliases } from './commands/apply';
import { runAlias } from './commands/run';

// Setup CLI
program
  .name('aliasmate')
  .description('A CLI tool to manage your shell aliases')
  .version('1.0.0');

// Add commands
program
  .command('add')
  .description('Add a new alias')
  .action(addAlias);

program
  .command('list')
  .description('List all aliases')
  .action(listAliases);

program
  .command('remove')
  .description('Remove an alias')
  .action(removeAlias);

program
  .command('find')
  .description('Find an alias by name or command')
  .action(findAlias);

program
  .command('export')
  .description('Export aliases to a file')
  .action(exportAliases);

program
  .command('import')
  .description('Import aliases from a file')
  .action(importAliases);

program
  .command('update')
  .description('Update an existing alias')
  .action(updateAlias);

program
  .command('apply')
  .description('Apply aliases to your shell configuration')
  .action(applyAliases);

program
  .command('run')
  .description('Run an alias command')
  .argument('[alias]', 'Alias name to run')
  .action(runAlias);

// Parse command line arguments
program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
