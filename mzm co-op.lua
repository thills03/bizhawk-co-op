local guiClick = {}

local form1 = nil
local text1, lblRooms, btnGetRooms, ddRooms, btnQuit, btnJoin, btnHost
local txtUser, txtPass, lblUser, lblPass, ddRamCode, lblRamCode
config = {}


function strsplit(inputstr, sep, max)
  if not sep then
    sep = ","
  end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    if max and i > max then
      t[i] = (t[i] or '') .. sep .. str
    else
      t[i] = str
      i = i + 1
    end
  end
  return t
end



local sync = require("mzm_coop\\sync")


--stringList contains the output text
local stringList = {last = 1, first = 10}
for i = stringList.first, stringList.last, -1 do
	stringList[i] = ""
end


--add a new line to the string list
function stringList.push(value)
  stringList.first = stringList.first + 1
  stringList[stringList.first] = value
  stringList[stringList.last] = nil
  stringList.last = stringList.last + 1
end


--get the entire string list as a single string
function stringList.tostring()
	local outputstr = ""
	for i = stringList.first, stringList.last, -1 do
		outputstr = outputstr .. stringList[i] .. "\r\n"
	end

	return outputstr
end


--Add a line to the output. Inserts a timestamp to the string
function printOutput(str) 
	str = string.gsub (str, "\n", "\r\n")
	str = "[" .. os.date("%H:%M:%S", os.time()) .. "] " .. str
	stringList.push(str)

	forms.settext(text1, stringList.tostring())
end


host = require("mzm_coop\\host")


local roomlist = false
function refreshRooms() 
	roomlist = host.getRooms()
	if roomlist then
		forms.setdropdownitems(ddRooms, roomlist)
	else 
		forms.setdropdownitems(ddRooms, {['(No rooms available)']='(No rooms available)'})
	end

	updateGUI()
end


--Reloads all the info on the form. Disables any inappropriate components
function updateGUI()
	if host.status == 'Idle' then
		if forms.setdropdownitems and roomlist then
			forms.setproperty(ddRooms, 'Enabled', true)
		else 
			forms.setproperty(ddRooms, 'Enabled', false)
		end
		forms.setproperty(btnGetRooms, "Enabled", true)
		forms.setproperty(ddRamCode, "Enabled", true)
		forms.setproperty(txtUser, "Enabled", true)
		forms.setproperty(txtPass, "Enabled", true)
		forms.setproperty(btnQuit, "Enabled", false)
		forms.setproperty(btnJoin, "Enabled", true)
		forms.setproperty(btnHost, "Enabled", true)
		forms.settext(btnHost, "Create Room")
	else 
		forms.setproperty(btnGetRooms, "Enabled", false)
		forms.setproperty(ddRamCode, "Enabled", false)
		forms.setproperty(ddRooms, "Enabled", false)
		forms.setproperty(txtUser, "Enabled", false)
		forms.setproperty(txtPass, "Enabled", false)
		forms.setproperty(btnQuit, "Enabled", true)
		forms.setproperty(btnJoin, "Enabled", false)
		forms.setproperty(btnHost, "Enabled", not host.locked)
		forms.settext(btnHost, "Lock Room")
	end
end


--If the script ends, makes sure the sockets and form are closed
event.onexit(function () host.close(); forms.destroy(form1) end)


--furthermore, override error with a function that closes the connection
--before the error is actually thrown
local old_error = error

error = function(str, level)
  host.close()
  old_error(str, 0)
end


--Load the changes from the form and disable any appropriate components
function prepareConnection()
	if roomlist then
		config.room = forms.gettext(ddRooms)
	else 
		config.room = ''
	end
	config.ramcode = forms.gettext(ddRamCode)
	config.user = forms.gettext(txtUser)
	config.pass = forms.gettext(txtPass)
	config.port = 50000
	--config.hostname = forms.gettext(txtIP)
end


--Quit/Disconnect click handle for the quit button
function leaveRoom()
	if (host.connected()) then
		sendMessage["Quit"] = true
	else 
		host.close()
	end
end


--Returns a list of files in a given directory
function os.dir(dir)
	local files = {}
	local f = assert(io.popen('dir \"' .. dir .. '\" /b ', 'r'))
	for file in f:lines() do
		table.insert(files, file)
	end
	f:close()
	return files
end


--Create the form
form1 = forms.newform(310, 310, "Bizhawk Co-op")

text1 = forms.textbox(form1, "", 263, 105, nil, 16, 153, true, false)
forms.setproperty(text1, "ReadOnly", true)
forms.setproperty(text1, "MaxLength", 1028)

if forms.setdropdownitems then -- can't update list prior to bizhawk 1.12.0
	btnGetRooms = forms.button(form1, "Refresh Rooms", refreshRooms, 220, 10, 60, 23)
	ddRooms = forms.dropdown(form1, {['(Fetching rooms...)']='(Fetching rooms...)'}, 80, 11, 135, 20)
	forms.setproperty(ddRooms, 'Enabled', false)
	guiClick["Refresh Rooms"] = refreshRooms;
else
	btnGetRooms = forms.button(form1, "", function() end, 15, 10, 60, 23)
	forms.setproperty(btnGetRooms, 'Enabled', false)

	roomlist = host.getRooms()
	if roomlist then
		ddRooms = forms.dropdown(form1, roomlist, 80, 11, 200, 20)
		forms.setproperty(ddRooms, 'Enabled', true)
	else 
		ddRooms = forms.dropdown(form1, {['(No rooms available)']='(No rooms available)'}, 80, 11, 200, 20)
		forms.setproperty(ddRooms, 'Enabled', false)
	end
end
lblRooms = forms.label(form1, "Rooms:", 34, 13)


txtUser = forms.textbox(form1, "", 200, 20, nil, 80, 40, false, false)
txtPass = forms.textbox(form1, "", 200, 20, nil, 80, 66, false, false)
ddRamCode = forms.dropdown(form1, os.dir("mzm_coop\\ramcontroller"), 80, 93, 200, 10)
lblUser = forms.label(form1, "Username:", 19, 41)
lblPass = forms.label(form1, "Password:", 21, 68)
lblRamCode = forms.label(form1, "RAM Script:", 13, 95)





btnQuit = forms.button(form1, "Leave Room", leaveRoom, 
	15, 120, 85, 25)
forms.setproperty(btnQuit, 'Enabled', false)
btnHost = forms.button(form1, "Create Room", 
	function() prepareConnection(); guiClick["Host Server"] = host.start end, 
	105, 120, 85, 25)
btnJoin = forms.button(form1, "Join Room", 
	function() prepareConnection(); guiClick["Join Server"] = host.join end, 
	195, 120, 85, 25)

sendMessage = {}
local thread

updateGUI()

local threads = {}

emu.yield()
emu.yield()

---------------------
--    Main loop    --
---------------------
while 1 do
	--End script if form is closed
	if forms.gettext(form1) == "" then
		return
	end

	host.listen()

	--Create threads for the function requests from the form
	for k,v in pairs(guiClick) do
		threads[coroutine.create(v)] = k
	end
	guiClick = {}

	--Run the threads
	for k,v in pairs(threads) do
		if coroutine.status(k) == "dead" then
			threads[k] = nil
		else
			local status, err = coroutine.resume(k)
			if (status == false) then
				if (err ~= nil) then
					printOutput("Error during " .. v .. ": " .. err)
				else
					printOutput("Error during " .. v .. ": No error message")
				end
			end						
		end
	end

	--If connected, run the syncinputs thread
	if host.connected() then
		--If the thread didn't yield, then create a new one
		if thread == nil or coroutine.status(thread) == "dead" then
			thread = coroutine.create(sync.syncRAM)
		end
		local status, err = coroutine.resume(thread, host.clients)

		if (status == false and err ~= nil) then
			printOutput("Error during sync inputs: " .. tostring(err))
		end
	end

	-- 2 Emu Yields = 1 Frame Advance
	--If game is paused, then yield will not frame advance
	emu.yield()
	emu.yield()
end