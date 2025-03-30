#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// List of files/directories to remove
const unwantedPaths = [
  // Add paths to unwanted files here, examples:
  'node_modules',
  'temp',
  '.DS_Store',
  'logs',
  // Add more paths as needed
];

const rootDir = __dirname;

// Remove unwanted files/directories
unwantedPaths.forEach(item => {
  const fullPath = path.join(rootDir, item);
  
  try {
    if (fs.existsSync(fullPath)) {
      if (fs.lstatSync(fullPath).isDirectory()) {
        fs.rmdirSync(fullPath, { recursive: true });
      } else {
        fs.unlinkSync(fullPath);
      }
      console.log(`Removed: ${item}`);
    }
  } catch (error) {
    console.error(`Error removing ${item}:`, error);
  }
});

console.log('Cleanup completed!');
