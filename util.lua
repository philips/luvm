#!/usr/bin/env luvit

local Fiber = require('fiber')
local Fs = require('fs')
local Path = require('path')
local gmatch = require('string').gmatch

--
-- mimicks mkdir -p
--
local function mkdir_p(path, perm, callback)
  path = Path.resolve(process.cwd(), path)
  Fiber.new(function(resume, wait)
    local err
    local pa = '/'
    for dir in gmatch(path, '[^/]+') do
      pa = Path.join(pa, dir)
      Fs.mkdir(pa, perm, resume)
      err = wait()
      if err and err.code ~= 'EEXIST' then
        callback(err)
        return
      end
    end
    callback()
  end)
end

--
-- mimicks rm -fr
--
local function rm_fr(path, callback)
  path = Path.normalize(path)
  Fiber.new(function(resume, wait)
    local err, stat, files
    -- stat without resolving symlinks
    Fs.lstat(path, resume)
    err, stat = wait()
    -- stat failed -> bail out
    if err then
      callback(err)
      return
    end
    -- path is not directory?
    if not stat.is_directory then
      -- unlink
      Fs.unlink(path, resume)
      err = wait()
      callback(err)
      return
    end
    -- path is directory. read files
    while true do
      Fs.readdir(path, resume)
      err, files = wait()
      -- read error -> bail out
      if err then
        callback(err)
        return
      end
      -- no files in directory? break cleaning loop
      -- N.B. we do it in loop since a concurrent process
      -- may be putting files into this directory
      if #files == 0 then break end
      -- recursively rm_fr them
      local i, file
      for i, file in ipairs(files) do
        rm_fr(Path.join(path, file), resume)
        -- bail out on any error
        err = wait()
        if (err) then
          callback(err)
          return
        end
      end
    end
    -- directory is clean. rmdir it
    Fs.rmdir(path, resume)
    err = wait()
    callback(err)
  end)
end


--
-- mimicks find
--
local function find(path, match_fn, callback)
  path = Path.normalize(path)
  Fiber.new(function(resume, wait)
    local err, files
    -- match
    match_fn(path, stat)
    -- read sub-files, if any
    Fs.readdir(path, resume)
    err, files = wait()
    -- read error -> bail out
    if err then
      -- ENOTDIR: current path is not directory. reset error and proceed
      -- ENOENT: e.g. broken symlink
      if err.code == 'ENOTDIR' or err.code == 'ENOENT' then
        err = nil
      end
      callback(err)
      return
    end
    -- recursively iterate thru files
    local i, file
    for i, file in ipairs(files) do
      find(Path.join(path, file), match_fn, resume)
      -- bail out on any error
      err = wait()
      if (err) then break end
    end
    callback(err)
  end)
end


--[[

Fiber.new(function(resume, wait)
local err

local paths = {
  '   ', '/foo/bar/bar', 'foo/bar/bar', './fi/bar', '/home/dvv/LUA/luvm/tests/install/N/fu/bar/baz'
}
local i, path
for i, path in ipairs(paths) do
  mkdir_p(path, '0755', resume)
  err = wait()
  p('DONE', i, err)
end

p()

local paths = {
  './fi/bar', './fi', 'foo/bar', 'foo', 'tests', 'examples', '   ', 'fu', 'modules'
}
local i, path
for i, path in ipairs(paths) do
  p('RM?', i, path)
  rm_fr(path, resume); err = wait()
  p('RM!', i, err)
end

end)


]]--

find('/home', function(path, stat)
  debug('MATCH?', path)
end, function(err)
  debug('DONE', err)
end)

-- export
return setmetatable({
  find = find,
  mkdir_p = mkdir_p,
  rm_fr = rm_fr,
}, { __index = Fs })