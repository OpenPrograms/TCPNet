--[[
	TCPNet client API by PixelToast https://github.com/P-T-/TCPNet/
	released in public domain because i know you hate seeing the all caps
]]
local internet=require("internet")
local serial=require("serialization")
local event=require("event")
local computer=require("computer")
local cns={}
local handle={}
event.timer(0.5,function()
	for id,handle in pairs(cns) do
		local err,txt=pcall(handle.socket.read,handle.socket)
		if err then
			local err,dat=pcall(serial.unserialize,txt)
			if err and type(dat)=="table" then
				if dat[1]=="message" then
					computer.pushSignal("tcpnet_message",id,dat.port,dat.data)
				end
			end
		end
	end
end,math.huge)
function handle.send(handle,port,data)
	if type(port):match("^[^sn]") then
		error("Bad argument #1 to handle:send (got "..type(port)")",2)
	end
	if type(data)=="function" then
		error("Bad argument #2 to handle:send (got "..type(data)")",2)
	end
	handle.socket:write(serial.serialize({"send",port=port,data=data}).."\n")
	handle.socket:flush()
end
function handle.open(handle,...)
	local ports={}
	for k,v in pairs({...}) do
		if type(v):match("^[^sn]") then
			error("Bad argument #"..k.." to handle:open (got "..type(v)..")",2)
		end
		ports[v]=true
	end
	handle.socket:write(serial.serialize({"open",ports=ports}).."\n")
	handle.socket:flush()
end
function handle.close(hande,...)
	local ports={}
	for k,v in pairs({...}) do
		if type(v):match("^[^sn]") then
			error("Bad argument #"..k.." to handle:close (got "..type(v)..")",2)
		end
		ports[v]=false
	end
	handle.socket:write(serial.serialize({"open",ports=ports}).."\n")
	handle.socket:flush()
end
function handle.receive(hande,timeout,port)
	local tm=os.clock()+(timeout or 0)
	while not timeout or os.clock()>=tm do
		local ev,hnd,prt,data
		if timeout then
			ev,hnd,prt,data=event.pull(os.clock()-tm,"tcpnet_message")
		else
			ev,hnd,prt,data=event.pull("tcpnet_message")
		end
		if ev and (not port or port==prt) then
			if port then
				return data
			else
				return prt,data
			end
		end
	end
	return false,"timeout"
end
return {
	new=function(ip,port)
		ip=ip or "localhost"
		port=port or 25476
		local sv,err=internet.open(ip,port)
		if not sv then
			return sv,err
		end
		sv:setTimeout(0)
		local new={ip=ip,port=port,socket=sv}
		new.id=tostring(new):match("%x+$")
		for k,v in pairs(handle) do
			new[k]=v
		end
		cns[new.id]=new
		return new
	end,
	id=cns,
}