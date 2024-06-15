repeat task.wait() until game:IsLoaded()

--[[

	Yozagra LLC 2024.
	No rights reserved.

  Excuse my rushed coding.

]]

local creator = "yozagra"

print("You are using YOZAGRA-SOFT Auto-teleport. 2024");
print("Press U to stop teleporting.");
print("Press N to skip the current player.");

local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local input = game:GetService("UserInputService")

if not runservice:IsClient() then return end
local player = players.LocalPlayer
local currentPlayer:Player;
local lastPlayer:Player;
local timeout = 999;
local active = false;
local finished = false;
local bind = Enum.KeyCode.O

local connectionInput:RBXScriptConnection;
local switchCycle:thread;
local deathConnection:RBXScriptConnection;
local leaveConnection:RBXScriptConnection;

local mainFunction = function(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if connectionInput then
		connectionInput:Disconnect() -- this is useless
	end

	local attach_thread: thread;
	local timeout_thread: thread;

	connectionInput = input.InputBegan:Connect(function(inp, gameProc)
		if gameProc then return end
		if not active then return end

		if inp.KeyCode == Enum.KeyCode.U then
			print("User has cancelled the attachment via keybind.")

			if switchCycle then
				task.cancel(switchCycle)
				active = false
			end

			if attach_thread then task.cancel(attach_thread) end
			if timeout_thread then task.cancel(timeout_thread) end

			connectionInput:Disconnect()
		elseif inp.KeyCode == Enum.KeyCode.N then

			if not currentPlayer then return end

			finished = true
			print("Skipped player "..currentPlayer.Name..".")
		end

	end)

	switchCycle = task.spawn(function()
		local playerAmount = players:GetPlayers()
		local plr = playerAmount[2];
		active = true
		while task.wait() do
			if not active then break end

			for i, plr in ipairs(players:GetPlayers()) do
				finished = false
				if plr == lastPlayer then continue end
				if plr == player then continue end

				local c = plr.Character; if not c then continue end
				local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then continue end;
				local root : BasePart = c:FindFirstChild("HumanoidRootPart")
				local meRoot : BasePart = character:FindFirstChild("HumanoidRootPart")

				lastPlayer = plr;
				currentPlayer = plr;


				if hum.Health <= 0 then continue end
				attach_thread = task.spawn(function()
					while task.wait() do

						if finished then break end
						if not root then continue end
						if not meRoot then continue end
						local offset = CFrame.new(0, 0, 1)
						local total = offset * CFrame.Angles(0,0,0)

						meRoot.CFrame = root.CFrame * total
						if hum.Health <= 0 then
							print("User has cancelled the attachment. Reason: Death of Victim")
							finished = true
							break
						end
					end
				end)

				if leaveConnection then leaveConnection:Disconnect() end
				leaveConnection = players.PlayerRemoving:Connect(function(plrA: Player)
					if not currentPlayer then return end
					if plrA.UserId == currentPlayer.UserId then finished = true end
				end)

				timeout_thread = task.spawn(function()
					task.wait(timeout);
					finished = true
					print("User has cancelled the attachment. Reason: Timeout")
				end)

				while (not finished) do 
					task.wait() 
				end

				print("Attachment to the player "..plr.Name.." has finished.")
				task.cancel(attach_thread)
				task.cancel(timeout_thread)

			end

			task.wait(0.2)
		end
	end)

	deathConnection = humanoid.Died:Connect(function()
		if switchCycle then
			task.cancel(switchCycle)
			active = false
		end

		if connectionInput then
			connectionInput:Disconnect()
		end
		deathConnection:Disconnect()
		print("User has cancelled the attachment. Reason: Death")
	end)
end

mainFunction(player.Character)
