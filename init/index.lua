-- Pre-Loader
local r = require
local UI, static, JSON, Flags, Version = r 'UI', r 'static', r 'JSON', r 'Flags', r 'VersionInfo';
if not UI then return error('cannot get ui'); end
if getgenv then
  if getgenv().RexLoaderUI then getgenv().RexLoaderUI:Destroy() end
  getgenv().RexLoaderUI = UI;
end
if not pcall(function() UI.Parent = game:GetService('CoreGui') end) then
  UI.Parent = game:GetService 'Players'.LocalPlayer:WaitForChild('PlayerGui')
end
local MainUI = UI:WaitForChild('MainUI');
MainUI.Version.Text = string.format(MainUI.Version.Text, Version.Loader, Version.Rex);
MainUI.Changelog.Changes.Text = 'Getting Changelog'
task.spawn(function() MainUI.Changelog.Changes.Text = game:HttpGetAsync(static 'CHANGELOG.txt') end)
local StatusInformationScroller = MainUI.StatusInformation;
local StatusInformationTextlabel = StatusInformationScroller.Text;
StatusInformationTextlabel.Text = 'Starting up...';
StatusInformationTextlabel.RichText = true;
local Step = function(t)
  StatusInformationTextlabel.Text = StatusInformationTextlabel.Text .. '\n' .. t;
  StatusInformationScroller.CanvasSize = UDim2.new(0, 0, 0, StatusInformationTextlabel.TextBounds.Y);
end
local error = function(r)
  Step('Error: ' .. r);
  task.wait(3);
  UI:Destroy();
  return error(r, 2);
end
Step 'Ensure Valid Environment';
if not pcall(loadstring, 'return true') then return error('Loadstring Unavailable') end
if not Flags.Debug then
  local s, versionInfoRawLua = pcall(function() return game:HttpGetAsync(static 'init/VersionInfo.lua') end)
  if not s then return error('HttpService Unavailable') end
  Step('Get Version');
  local LatestVersionInfo = loadstring(versionInfoRawLua)();
  if Version.Loader ~= LatestVersionInfo.Loader and not Flags.Debug then return error('Loader Version Mismatch'); end
end
-- for _, o in pairs(MainUI:GetDescendants()) do if o:IsA('TextLabel') then o.RichText = true end end=
-- Lua Env Check
if true ~= true then error('Lua Environment Check Failed') end
if true == false then error('Lua Environment Check Failed') end
-- Begin Actual Loader Code
-- Will pass this into main script:
local APIs;
pcall(function()
  Step 'Getting Latest Roblox Studio Version'
  local StudioVersion = game:HttpGetAsync('http://setup.roblox.com/versionQTStudio');
  if not StudioVersion then return Step 'Could not get studio version, falling back to regular' end
  Step 'Getting API Dump'
  local RawAPIs;
  if readfile then pcall(function() RawAPIs = readfile(string.format('RBX-%s-API-Dump.json', StudioVersion)); end) end
  if not RawAPIs then RawAPIs = game:HttpGetAsync(string.format('http://setup.roblox.com/%s-API-Dump.json', StudioVersion)) end
  if writefile then pcall(function() writefile(string.format('RBX-%s-API-Dump.json', StudioVersion), RawAPIs); end) end
  Step 'Parsing API Dump'
  pcall(function() APIs = JSON.parse(RawAPIs); end)
  if not APIs then APIs = game:GetService 'HttpService':JSONDecode(RawAPIs) end
end)
if not APIs then
  Step 'Failed to get from RBX Servers\nLoading Backup API Dump'
  APIs = r 'BackupAPIDump';
end
Step '<font color="#aaffaa">Milestone Reached: API Dump Loaded</font>'

