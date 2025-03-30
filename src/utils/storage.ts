import Conf from 'conf';

interface Alias {
  name: string;
  command: string;
  description?: string;
  tags?: string[];
  createdAt: number;
  updatedAt: number;
}

// Create config store
const config = new Conf({
  projectName: 'aliasmate',
  schema: {
    aliases: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          command: { type: 'string' },
          description: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
          createdAt: { type: 'number' },
          updatedAt: { type: 'number' }
        },
        required: ['name', 'command', 'createdAt', 'updatedAt']
      },
      default: []
    }
  }
});

// Get all aliases
export const getAliases = (): Alias[] => {
  return config.get('aliases') as Alias[];
};

// Set all aliases
export const setAliases = (aliases: Alias[]): void => {
  config.set('aliases', aliases);
};

// Get an alias by name
export const getAliasByName = (name: string): Alias | undefined => {
  const aliases = getAliases();
  return aliases.find(alias => alias.name === name);
};

// Add a new alias
export const addNewAlias = (alias: Omit<Alias, 'createdAt' | 'updatedAt'>): Alias => {
  const aliases = getAliases();
  const now = Date.now();
  
  const newAlias: Alias = {
    ...alias,
    createdAt: now,
    updatedAt: now
  };
  
  aliases.push(newAlias);
  setAliases(aliases);
  
  return newAlias;
};

// Update an existing alias
export const updateExistingAlias = (name: string, updates: Partial<Omit<Alias, 'name' | 'createdAt' | 'updatedAt'>>): Alias | null => {
  const aliases = getAliases();
  const index = aliases.findIndex(alias => alias.name === name);
  
  if (index === -1) {
    return null;
  }
  
  const updated: Alias = {
    ...aliases[index],
    ...updates,
    updatedAt: Date.now()
  };
  
  aliases[index] = updated;
  setAliases(aliases);
  
  return updated;
};

// Remove an alias
export const removeExistingAlias = (name: string): boolean => {
  const aliases = getAliases();
  const initialLength = aliases.length;
  
  const filteredAliases = aliases.filter(alias => alias.name !== name);
  
  if (filteredAliases.length === initialLength) {
    return false;
  }
  
  setAliases(filteredAliases);
  return true;
};

export type { Alias };
