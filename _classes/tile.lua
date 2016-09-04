tile = class:new({
	type = "tile",
	color = color.none,
	buildTime = 1,
	name = "def",
})

function tile:load()

	self.job = {}
end

function tile:draw()
	local x,y = (self.x-self.map.x)*self.map.scale, (self.y-self.map.y)*self.map.scale
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill",x,y,self.map.scale,self.map.scale)
	if self.object and self.object.name ~= "none" then
		self.object:draw()
	end
	if table.count(self.job) > 0 then
		love.graphics.setColor(100,100,100,100)
		love.graphics.rectangle("fill",x,y,self.map.scale,self.map.scale)
	end
end

function tile:instalObject(obj)
	local j = self.job.object
	local shouldBuild = obj.name ~= self.object.name and not j -- should I build
	if j and obj.name == "none" then -- stop object build job
		j:cancel()
		self.job.object = nil
	elseif shouldBuild and self.object.name == "none" then -- build object
		self.job.object = job:new({tile = self, object = obj, queue = self.map.jobQueue, jobTime = obj.buildTime})
		function self.job.object:jobComplet()
			self.tile.job.object = nil
			self.tile.object = self.object:new({tile = self.tile})
		end
	elseif shouldBuild then -- replace object
		self.job.object = job:new({tile = self,object = obj,queue = self.map.jobQueue, jobTime = self.object.buildTime/2})
		function self.job.object:jobComplet()
			self.tile.job.object = nil
			self.tile.object = objects.none:new()
			self.tile:instalObject(self.object)
		end
	end
end

function tile:changeType(t)
	local j = self.job.type
	if j and t.name == "grass" then --  stop tile build job
		j:cancel()
		self.job.type = nil
	elseif t.name ~= self.name and not j then -- change tile type
		self.job.type = job:new({tile = self,type = t,queue = self.map.jobQueue, jobTime = t.buildTime})
		function self.job.type:jobComplet()
			self.tile.job.type = nil
			self.tile.map:changeTile(self.tile.x,self.tile.y,self.type)
		end
	end
end

function tile:walkeble()
	if self.moveCost == -1 or self.object.moveCost == -1 then
		return false
	end
	return true
end

function tile:hasJob(t)
	if t then
		return self.job[t] ~= nil
	else
		return table.count(self.job) > 0
	end
end

function tile:getNeighbours(diags)
	local diags = diags or false
	local n = {}
	for x = -1,1 do
		for y = -1,1 do
			if math.abs(x) + math.abs(y) == 0 and (not diags or math.abs(x) + math.abs(y) == 2) then
				if self.map[x] and self.map[x][y] then
					n[#n+1] = self.map[x][y]
				end
			end
		end
	end
	return n
end

function tile:getJob(t)
	if t then
		return self.job[t]
	else
		for k in pairs(self.job) do
			return self.job[k]
		end
	end
end

function tile:save()
	local s = "tiles."..self.name..":new({"
	s = s.."x = "..self.x..", y = "..self.y..",map = w"
	if self.object.name ~= "none" then
		s = s..",object = objects."..self.object.name..":new()"
	end
	s = s.."})"
	return s
end

tiles = {}
tiles.grass = tile:new({name = "grass", color = color.green})
tiles.floor = tile:new({name = "floor", color = color.gray})