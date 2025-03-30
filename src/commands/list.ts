import chalk from 'chalk';
import { getAliases, Alias } from '../utils/storage';

export function listAliases(): void {
  const aliases = getAliases();
  
  if (aliases.length === 0) {
    console.log(chalk.yellow('No aliases found. Add some with the add command.'));
    return;
  }

  console.log(chalk.bold('\nAliases:'));
  console.log('--------------------------------------------------');
  
  aliases.forEach((alias: Alias) => {
    console.log(`${chalk.green(alias.name)} ${chalk.dim('→')}`);
    
    // Handle multi-line commands
    const commandLines = alias.command.split('\n');
    if (commandLines.length > 1) {
      console.log(chalk.dim('Multi-line command:'));
      commandLines.forEach((line, index) => {
        console.log(`  ${chalk.blue(`${index + 1}:`)} ${line}`);
      });
    } else {
      console.log(`  ${alias.command}`);
    }
    
    if (alias.description) {
      console.log(`  ${chalk.dim('Description:')} ${alias.description}`);
    }
    
    if (alias.tags && alias.tags.length > 0) {
      console.log(`  ${chalk.dim('Tags:')} ${alias.tags.join(', ')}`);
    }
    
    console.log('--------------------------------------------------');
  });
  
  console.log(chalk.dim(`Total: ${aliases.length} aliases`));
}
