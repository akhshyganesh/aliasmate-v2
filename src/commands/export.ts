import inquirer from 'inquirer';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import { getAliases } from '../utils/storage';

export async function exportAliases(): Promise<void> {
  const aliases = getAliases();
  
  if (aliases.length === 0) {
    console.log(chalk.yellow('No aliases found to export.'));
    return;
  }

  const { filePath } = await inquirer.prompt([
    {
      type: 'input',
      name: 'filePath',
      message: 'Export file path:',
      default: './aliases.json',
      validate: (input: string) => {
        if (!input.trim()) {
          return 'File path cannot be empty';
        }
        return true;
      }
    }
  ]);

  const resolvedPath = path.resolve(filePath);

  try {
    await fs.writeJson(resolvedPath, { aliases }, { spaces: 2 });
    console.log(chalk.green(`✓ Aliases exported to ${resolvedPath}`));
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(chalk.red(`✗ Failed to export aliases: ${errorMessage}`));
  }
}
