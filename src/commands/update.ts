import inquirer from 'inquirer';
import chalk from 'chalk';
import { getAliases, updateExistingAlias, getAliasByName } from '../utils/storage';

export async function updateAlias(): Promise<void> {
  const aliases = getAliases();
  
  if (aliases.length === 0) {
    console.log(chalk.yellow('No aliases found to update.'));
    return;
  }

  const { name } = await inquirer.prompt([
    {
      type: 'list',
      name: 'name',
      message: 'Select alias to update:',
      choices: aliases.map(alias => ({
        name: `${alias.name} (${alias.command.split('\n')[0]}${alias.command.includes('\n') ? '...' : ''})`,
        value: alias.name
      }))
    }
  ]);

  const existingAlias = getAliasByName(name);
  
  if (!existingAlias) {
    console.log(chalk.red(`✗ Could not find alias '${name}'`));
    return;
  }

  // Check if command is multi-line
  const isMultiLine = existingAlias.command.includes('\n');

  const answers = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'editAsMultiLine',
      message: 'Edit command as multi-line?',
      default: isMultiLine
    },
    {
      type: 'editor',
      name: 'multiLineCommand',
      message: 'Edit your command(s):',
      default: existingAlias.command,
      when: (answers) => answers.editAsMultiLine,
      validate: (input: string) => {
        if (!input.trim()) {
          return 'Command cannot be empty';
        }
        return true;
      }
    },
    {
      type: 'input',
      name: 'command',
      message: 'Command:',
      default: existingAlias.command,
      when: (answers) => !answers.editAsMultiLine,
      validate: (input: string) => {
        if (!input.trim()) {
          return 'Command cannot be empty';
        }
        return true;
      }
    },
    {
      type: 'input',
      name: 'description',
      message: 'Description (optional):',
      default: existingAlias.description || ''
    },
    {
      type: 'input',
      name: 'tags',
      message: 'Tags (comma-separated, optional):',
      default: existingAlias.tags ? existingAlias.tags.join(', ') : ''
    }
  ]);

  const tags = answers.tags ? answers.tags.split(',').map((tag: string) => tag.trim()).filter(Boolean) : [];
  const command = answers.editAsMultiLine ? answers.multiLineCommand : answers.command;

  const updated = updateExistingAlias(name, {
    command: command,
    description: answers.description || undefined,
    tags: tags.length > 0 ? tags : undefined
  });

  if (updated) {
    console.log(chalk.green(`✓ Alias '${name}' updated successfully`));
  } else {
    console.log(chalk.red(`✗ Failed to update alias '${name}'`));
  }
}
