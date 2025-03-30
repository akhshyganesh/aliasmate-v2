import inquirer from 'inquirer';
import chalk from 'chalk';
import { spawn } from 'child_process';
import { getAliasByName, updateExistingAlias } from '../utils/storage';
import path from 'path';

export async function runAlias(aliasName?: string): Promise<void> {
  // If no alias name provided, prompt the user to select one
  if (!aliasName) {
    const { selectedAlias } = await inquirer.prompt([
      {
        type: 'input',
        name: 'selectedAlias',
        message: 'Enter the name of the alias to run:',
        validate: (input: string) => {
          if (!input.trim()) {
            return 'Alias name cannot be empty';
          }
          const alias = getAliasByName(input);
          if (!alias) {
            return `Alias '${input}' does not exist`;
          }
          return true;
        }
      }
    ]);
    aliasName = selectedAlias;
  }

  // Get the alias
  const alias = getAliasByName(aliasName as string);
  
  if (!alias) {
    console.log(chalk.red(`✗ Alias '${aliasName}' not found`));
    return;
  }

  // Save current working directory
  const currentDir = process.cwd();
  console.log(chalk.dim(`Current directory: ${currentDir}`));
  
  // Display the command that will be executed
  console.log(chalk.bold('\nCommand to execute:'));
  console.log(chalk.cyan(alias.command));
  console.log('--------------------------------------------------');

  // Ask for confirmation before executing
  const { confirm } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'confirm',
      message: 'Do you want to execute this command?',
      default: true
    }
  ]);

  if (!confirm) {
    console.log(chalk.yellow('Command execution cancelled.'));
    return;
  }

  // Execute the command
  console.log(chalk.green('Executing command...'));
  
  try {
    // Split command by lines and execute each line
    const commandLines = alias.command.split(/\r?\n/);
    
    for (const line of commandLines) {
      if (!line.trim()) continue; // Skip empty lines
      
      // For Windows compatibility
      const shell = process.platform === 'win32' ? 'cmd.exe' : '/bin/sh';
      const shellArgs = process.platform === 'win32' ? ['/c', line] : ['-c', line];
      
      // Execute the command and wait for it to complete
      await new Promise<void>((resolve, reject) => {
        console.log(chalk.dim(`> ${line}`));
        
        const childProcess = spawn(shell, shellArgs, {
          stdio: 'inherit',
          cwd: currentDir, // Use the saved directory
          shell: true
        });
        
        childProcess.on('close', (code) => {
          if (code !== 0) {
            console.log(chalk.red(`Command exited with code ${code}`));
            reject(new Error(`Command exited with code ${code}`));
          } else {
            resolve();
          }
        });
        
        childProcess.on('error', (err) => {
          console.error(chalk.red(`Failed to execute command: ${err.message}`));
          reject(err);
        });
      });
    }
    
    console.log(chalk.green('✓ Command executed successfully'));
    
    // Ask if the user wants to update the command
    const { updateCommand } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'updateCommand',
        message: 'Do you want to update this command?',
        default: false
      }
    ]);
    
    if (updateCommand) {
      // Pre-fill with existing command
      const { newCommand } = await inquirer.prompt([
        {
          type: 'editor',
          name: 'newCommand',
          message: 'Edit the command:',
          default: alias.command
        }
      ]);
      
      // Update the command
      const updated = updateExistingAlias(aliasName as string, {
        command: newCommand
      });
      
      if (updated) {
        console.log(chalk.green(`✓ Alias '${aliasName}' updated successfully`));
      } else {
        console.log(chalk.red(`✗ Failed to update alias '${aliasName}'`));
      }
    }
    
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(chalk.red(`✗ Error: ${errorMessage}`));
  }
}
