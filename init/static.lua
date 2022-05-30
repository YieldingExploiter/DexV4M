return require'Flags'.Debug and function(p)
  task.wait(0.1) -- waits to emulate an http request
  return 'http://localhost:5500/' .. p
end or function(p) return 'https://raw.githubusercontent.com/YieldingExploiter/DexV4M/main/' .. p end
