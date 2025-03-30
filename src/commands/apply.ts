import inquirer from 'inquirer';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { getAliases, Alias } from '../utils/storage';

export async function applyAliases(): Promise<void> {
  const aliases = getAliases();
  
  if (aliases.length === 0) {
    console.log(chalk.yellow('No aliases found to apply.'));
    return;
  }

  const { shellType } = await inquirer.prompt([
    {
      type: 'list',
      name: 'shellType',
      message: 'Select your shell type:',
      choices: [
        { name: 'Bash (.bashrc)', value: 'bash' },
        { name: 'Zsh (.zshrc)', value: 'zsh' },
        { name: 'Fish (config.fish)', value: 'fish' },
        { name: 'Custom file', value: 'custom' }
      ]
    }
  ]);

  let configPath = '';
  
  if (shellType === 'custom') {
    const { customPath } = await inquirer.prompt([
      {
        type: 'input',
        name: 'customPath',
        message: 'Enter path to your shell config file:',
        validate: (input: string) => input.trim() ? true : 'Path cannot be empty'
      }
    ]);
    configPath = path.resolve(customPath);
  } else {
    const homeDir = os.homedir();
    if (shellType === 'bash') {
      configPath = path.join(homeDir, '.bashrc');
    } else if (shellType === 'zsh') {
      configPath = path.join(homeDir, '.zshrc');
    } else if (shellType === 'fish') {
      configPath = path.join(homeDir, '.config', 'fish', 'config.fish');
    }
  }

  // Check if config file exists
  if (!fs.existsSync(configPath)) {
    console.log(chalk.yellow(`Config file not found: ${configPath}`));
    const { createFile } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'createFile',
        message: 'File does not exist. Create it?',
        default: true
      }
    ]);
    
    if (!createFile) {
      console.log(chalk.yellow('Operation cancelled.'));
      return;
    }
    
    // Ensure directory exists
    await fs.ensureDir(path.dirname(configPath));
  }

  // Generate alias content
  let aliasContent = '\n# AliasMate managed aliases - DO NOT EDIT BETWEEN THESE MARKERS\n';
  aliases.forEach((alias: Alias) => {
    if (shellType === 'fish') {
      aliasContent += `alias ${alias.name}='${alias.command}'\n`;
    } else {
      aliasContent += `alias ${alias.name}="${alias.command}"\n`;
    }
  });
  aliasContent += '# End of AliasMate managed aliases\n';

  try {
    let fileContent = '';
    if (fs.existsSync(configPath)) {
      fileContent = await fs.readFile(configPath, 'utf8');
    }

    // Check if AliasMate section already exists
    const startMarker = '# AliasMate managed aliases - DO NOT EDIT BETWEEN THESE MARKERS';
    const endMarker = '# End of AliasMate managed aliases';
    
    if (fileContent.includes(startMarker) && fileContent.includes(endMarker)) {
      // Replace existing section
      const startIndex = fileContent.indexOf(startMarker);
      const endIndex = fileContent.indexOf(endMarker) + endMarker.length;
      fileContent = fileContent.substring(0, startIndex) + aliasContent + fileContent.substring(endIndex);
    } else {
      // Append to file
      fileContent += aliasContent;
    }

    await fs.writeFile(configPath, fileContent);
    console.log(chalk.green(`✓ Applied ${aliases.length} aliases to ${configPath}`));
    console.log(chalk.yellow('Note: You may need to restart your shell or run "source ' + configPath + '" to apply changes'));
    
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(chalk.red(`✗ Failed to apply aliases: ${errorMessage}`));
  }
}
