import inquirer from 'inquirer';
import chalk from 'chalk';
import { getAliases, Alias } from '../utils/storage';

export async function findAlias(): Promise<void> {
  const { searchTerm } = await inquirer.prompt([
    {
      type: 'input',
      name: 'searchTerm',
      message: 'Enter search term (name, command, or tag):',
      validate: (input: string) => {
        if (!input.trim()) {
          return 'Search term cannot be empty';
        }
        return true;
      }
    }
  ]);

  const aliases = getAliases();
  const term = searchTerm.toLowerCase();
  
  const matchedAliases = aliases.filter((alias: Alias) => {
    return alias.name.toLowerCase().includes(term) || 
           alias.command.toLowerCase().includes(term) ||
           (alias.description && alias.description.toLowerCase().includes(term)) ||
           (alias.tags && alias.tags.some(tag => tag.toLowerCase().includes(term)));
  });

  if (matchedAliases.length === 0) {
    console.log(chalk.yellow(`No aliases found matching '${searchTerm}'`));
    return;
  }

  console.log(chalk.bold(`\nFound ${matchedAliases.length} aliases matching '${searchTerm}':`));
  console.log('--------------------------------------------------');
  
  matchedAliases.forEach((alias: Alias) => {
    console.log(`${chalk.green(alias.name)} ${chalk.dim('→')} ${alias.command}`);
    
    if (alias.description) {
      console.log(`  ${chalk.dim('Description:')} ${alias.description}`);
    }
    
    if (alias.tags && alias.tags.length > 0) {
      console.log(`  ${chalk.dim('Tags:')} ${alias.tags.join(', ')}`);
    }
    
    console.log('--------------------------------------------------');
  });
}
