import inquirer from 'inquirer';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import { getAliases, setAliases, Alias } from '../utils/storage';

export async function importAliases(): Promise<void> {
  const { filePath } = await inquirer.prompt([
    {
      type: 'input',
      name: 'filePath',
      message: 'Import file path:',
      validate: (input: string) => {
        if (!input.trim()) {
          return 'File path cannot be empty';
        }
        
        const resolvedPath = path.resolve(input);
        if (!fs.existsSync(resolvedPath)) {
          return 'File does not exist';
        }
        
        return true;
      }
    }
  ]);

  const resolvedPath = path.resolve(filePath);

  try {
    const data = await fs.readJson(resolvedPath);
    
    if (!data.aliases || !Array.isArray(data.aliases)) {
      console.error(chalk.red('✗ Invalid file format. Expected { aliases: [...] }'));
      return;
    }
    
    const currentAliases = getAliases();
    const importedAliases = data.aliases as Alias[];
    
    const { action } = await inquirer.prompt([
      {
        type: 'list',
        name: 'action',
        message: 'How do you want to import the aliases?',
        choices: [
          { name: 'Merge (add new, skip existing)', value: 'merge' },
          { name: 'Overwrite (replace existing with imported)', value: 'overwrite' },
          { name: 'Append (add all, may create duplicates)', value: 'append' }
        ]
      }
    ]);

    let newAliases: Alias[] = [];
    
    if (action === 'merge') {
      const existingNames = new Set(currentAliases.map(a => a.name));
      newAliases = [
        ...currentAliases,
        ...importedAliases.filter(a => !existingNames.has(a.name))
      ];
    } else if (action === 'overwrite') {
      newAliases = importedAliases;
    } else { // append
      newAliases = [...currentAliases, ...importedAliases];
    }
    
    setAliases(newAliases);
    console.log(chalk.green(`✓ Imported ${importedAliases.length} aliases from ${resolvedPath}`));
    
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(chalk.red(`✗ Failed to import aliases: ${errorMessage}`));
  }
}
