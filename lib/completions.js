const fs = require('fs');
const path = require('path');

/**
 * Get all saved aliases for autocompletion
 */
function getAvailableAliases() {
  const aliasDir = path.join(process.env.HOME, '.config', 'aliasmate', 'aliases');
  
  try {
    if (fs.existsSync(aliasDir)) {
      return fs.readdirSync(aliasDir)
        .filter(file => file.endsWith('.js') || file.endsWith('.sh'))
        .map(file => path.basename(file, path.extname(file)));
    }
  } catch (error) {
    console.error('Error reading aliases directory:', error);
  }
  
  return [];
}

module.exports = { getAvailableAliases };
