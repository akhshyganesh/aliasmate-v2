import inquirer from 'inquirer';
import chalk from 'chalk';
import { getAliases, removeExistingAlias } from '../utils/storage';

export async function removeAlias(): Promise<void> {
  const aliases = getAliases();
  
  if (aliases.length === 0) {
    console.log(chalk.yellow('No aliases found to remove.'));
    return;
  }

  const { name } = await inquirer.prompt([
    {
      type: 'list',
      name: 'name',
      message: 'Select alias to remove:',
      choices: aliases.map(alias => ({
        name: `${alias.name} (${alias.command})`,
        value: alias.name
      }))
    }
  ]);

  const { confirm } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'confirm',
      message: `Are you sure you want to remove alias '${name}'?`,
      default: false
    }
  ]);

  if (confirm) {
    const removed = removeExistingAlias(name);
    
    if (removed) {
      console.log(chalk.green(`✓ Alias '${name}' removed successfully`));
    } else {
      console.log(chalk.red(`✗ Could not find alias '${name}'`));
    }
  } else {
    console.log(chalk.yellow('Operation cancelled.'));
  }
}
