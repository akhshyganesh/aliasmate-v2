import inquirer from 'inquirer';
import chalk from 'chalk';
import { addNewAlias, getAliasByName } from '../utils/storage';

export async function addAlias(): Promise<void> {
  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'name',
      message: 'Alias name:',
      validate: async (input: string) => {
        if (!input.trim()) {
          return 'Alias name cannot be empty';
        }
        
        const existingAlias = getAliasByName(input);
        if (existingAlias) {
          return 'Alias already exists. Use update command to modify it.';
        }
        
        return true;
      }
    },
    {
      type: 'confirm',
      name: 'isMultiLine',
      message: 'Is this a multi-line command?',
      default: false
    },
    {
      type: 'editor',
      name: 'multiLineCommand',
      message: 'Enter your command(s):',
      when: (answers) => answers.isMultiLine,
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
      when: (answers) => !answers.isMultiLine,
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
    },
    {
      type: 'input',
      name: 'tags',
      message: 'Tags (comma-separated, optional):',
    }
  ]);

  const tags = answers.tags ? answers.tags.split(',').map((tag: string) => tag.trim()).filter(Boolean) : [];
  const command = answers.isMultiLine ? answers.multiLineCommand : answers.command;

  const newAlias = addNewAlias({
    name: answers.name,
    command: command,
    description: answers.description || undefined,
    tags: tags.length > 0 ? tags : undefined
  });

  console.log(chalk.green(`✓ Alias '${newAlias.name}' added successfully`));
}
