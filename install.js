// ...existing code...

// Add shell completion installation
function installShellCompletions() {
  const homeDir = process.env.HOME;
  const bashCompletionPath = path.join(homeDir, '.bash_completion.d', 'aliasmate-completion.bash');
  const zshCompletionPath = path.join(homeDir, '.zsh', 'completions', '_aliasmate');
  
  // Create directories if they don't exist
  ensureDir(path.dirname(bashCompletionPath));
  ensureDir(path.dirname(zshCompletionPath));
  
  // Copy completion files
  fs.copyFileSync(
    path.join(__dirname, 'completion', 'aliasmate-completion.bash'),
    bashCompletionPath
  );
  
  fs.copyFileSync(
    path.join(__dirname, 'completion', 'aliasmate-completion.zsh'),
    zshCompletionPath
  );
  
  console.log('Shell completions installed successfully');
}

// ...existing code...
