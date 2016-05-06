
B_FC_VERSION = "1.0"
BINDING_HEADER_FAKECHAT = "FakeChat"


-------------------------------------------------------------------------------


B_FC_MESSAGES = 22

B_FC_Types = {
	"Whisper"
}


-------------------------------------------------------------------------------


B_FC_Index = 1
B_FC_SCM = nil


-------------------------------------------------------------------------------


function B_FC_PrintTable(o)
	if type(o) == 'table' then
		local s = '{'
		for k,v in pairs(o) do
			local kk = k
			if type(kk) ~= 'number' then kk = '"'..kk..'"' end
			s = s .. '['..kk..']=' .. B_FC_PrintTable(v) .. ','
		end
		return s .. '}'
	elseif type(o) == 'string' then
		return '"' .. o .. '"'
	else
		return tostring(o)
	end
end


-------------------------------------------------------------------------------

function B_FC_InitializeSettings()
	B_FC_GS = {}
	B_FC_GS["Name"] = ""
	B_FC_GS["GM"] = false
	B_FC_GS["Messages"] = {}

	for i = 1, B_FC_MESSAGES do
		B_FC_GS["Messages"][i] = {}
		local settings = B_FC_GS["Messages"][i]
		settings[1] = 1
		settings[2] = ""
	end
end

function B_FC_InitializeMessages()

	for i = 1, B_FC_MESSAGES do
		local index = i
		local frameMessage = CreateFrame("frame", "B_FC_Message" .. index, B_FC_Frame, "B_FC_MessageTemplate")
		local frameType, frameText = frameMessage:GetChildren()

		UIDropDownMenu_Initialize(frameType, function()
			local info = UIDropDownMenu_CreateInfo()
			for k,v in B_FC_Types do
				info.text = v
				info.value = v
				info.func = function()
					UIDropDownMenu_SetSelectedID(frameType, this:GetID())
					DEFAULT_CHAT_FRAME:AddMessage(this:GetID())
					B_FC_GS["Messages"][index][1] = this:GetID()
				end
				info.checked = nil
				UIDropDownMenu_AddButton(info, 1)
			end
		end)

		frameText:SetScript("OnTextChanged", function()
			B_FC_GS["Messages"][index][2] = frameText:GetText()
		end)

		frameMessage:SetPoint("TOPLEFT", B_FC_Frame, "TOPLEFT", 20, -20 + index * -16)
		frameMessage:Show()
	end
end

function B_FC_UpdateGUI()

	for i = 1, B_FC_MESSAGES do
		local settings = B_FC_GS["Messages"][i]
		local frameMessage = getglobal("B_FC_Message" .. i)
		local frameType, frameText = frameMessage:GetChildren()

		UIDropDownMenu_SetSelectedValue(frameType, B_FC_Types[settings[1]])
		frameText:SetText(settings[2])
	end

	B_FC_ButtonGM:SetChecked(B_FC_GS["GM"])
	B_FC_InputName:SetText(B_FC_GS["Name"])
end


-------------------------------------------------------------------------------


function B_FC_ShowGUI()
	if B_FC_Frame:IsShown() then
		B_FC_Frame:Hide()
	else
		B_FC_Frame:Show()
	end
end

function B_FC_ChatHandler()
	B_FC_ShowGUI()
end


-------------------------------------------------------------------------------


function B_FC_Reset()
	B_FC_Index = 1
end

function B_FC_DoWhisper(gm, name, text)
	local flag = ""
	if gm then
		flag = "<GM>"
	end
	local info = ChatTypeInfo["WHISPER"]
	local fmsg = format("%s|Hplayer:%s|h[%s]|h whispers: %s", flag, name, name, text)
	DEFAULT_CHAT_FRAME:AddMessage(fmsg, info.r, info.g, info.b, info.id)

	ChatEdit_SetLastTellTarget(DEFAULT_CHAT_FRAME.editBox, name)

	if B_FC_Index == 1 then
		PlaySound("TellMessage")
	end
end

function B_FC_Trigger()
	local done = false
	while done == false do

		if B_FC_Index > B_FC_MESSAGES then
			return
		end

		local msg = B_FC_GS["Messages"][B_FC_Index]
		local typ = msg[1]

		if typ == 1 then
			local text = msg[2]
			if text and text ~= "" then
				B_FC_DoWhisper(B_FC_GS["GM"], B_FC_GS["Name"], text)
				done = true
			end
		end

		B_FC_Index = B_FC_Index + 1
	end
end

function B_FC_NewSCM(msg, chatType, language, channel)
	if B_FC_GS then
		local name = B_FC_GS["Name"]
		if name and name ~= "" and chatType == "WHISPER" and string.lower(channel) == string.lower(name) then
			local flag = B_FC_GS["GM"] and "<GM>" or ""
			local info = ChatTypeInfo["WHISPER"]
			local fmsg = format("To %s|Hplayer:%s|h[%s]|h: %s", flag, name, name, msg)
			DEFAULT_CHAT_FRAME:AddMessage(fmsg, info.r, info.g, info.b, info.id)
			ChatEdit_SetLastToldTarget(DEFAULT_CHAT_FRAME.editBox, name)
			return
		end
	end

	B_FC_SCM(msg, chatType, language, channel)
end


-------------------------------------------------------------------------------


function B_FC_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
end

function B_FC_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "fakechat") then
			if B_FC_GS == nil then
				B_FC_InitializeSettings()
			end

			SLASH_FAKECHAT1 = "/fakechat"
			SLASH_FAKECHAT2 = "/fc"
			SlashCmdList["FAKECHAT"] = B_FC_ChatHandler

			B_FC_InitializeMessages()
			B_FC_UpdateGUI()

			B_FC_SCM = SendChatMessage
			SendChatMessage = B_FC_NewSCM
		end
	end
end