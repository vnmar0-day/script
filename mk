-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]
-- Serviços do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Configurações do Sistema
local LocalPlayer = Players.LocalPlayer
local Sistema_Ativo = false
local Conexao_Agua = nil
local PlataformaAgua = nil

-- Interface Principal
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WaterWalk_System"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

----------------------------------------------------------------
-- 1. DESIGN DO BOTÃO FLUTUANTE (MK)
----------------------------------------------------------------
local BotaoMK = Instance.new("TextButton")
BotaoMK.Name = "BotaoMK"
BotaoMK.Parent = ScreenGui
BotaoMK.Size = UDim2.new(0, 60, 0, 60)
BotaoMK.Position = UDim2.new(0.05, 0, 0.4, 0)
BotaoMK.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Verde Lindo
BotaoMK.Text = "MK"
BotaoMK.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoMK.Font = Enum.Font.GothamBold
BotaoMK.TextSize = 22
BotaoMK.BorderSizePixel = 0
BotaoMK.ZIndex = 10
BotaoMK.Active = true

local CornerBotao = Instance.new("UICorner")
CornerBotao.CornerRadius = UDim.new(1, 0)
CornerBotao.Parent = BotaoMK

local StrokeBotao = Instance.new("UIStroke")
StrokeBotao.Color = Color3.fromRGB(39, 174, 96)
StrokeBotao.Thickness = 3
StrokeBotao.Parent = BotaoMK

----------------------------------------------------------------
-- 2. DESIGN DO MENU PRINCIPAL (WATER WALK)
----------------------------------------------------------------
local MenuPrincipal = Instance.new("Frame")
MenuPrincipal.Name = "MenuPrincipal"
MenuPrincipal.Parent = ScreenGui
MenuPrincipal.Size = UDim2.new(0, 300, 0, 180)
MenuPrincipal.Position = UDim2.new(0.5, -150, 0.5, -90)
MenuPrincipal.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark Mode
MenuPrincipal.Visible = false
MenuPrincipal.BorderSizePixel = 0
MenuPrincipal.ZIndex = 5

local CornerMenu = Instance.new("UICorner")
CornerMenu.CornerRadius = UDim.new(0, 12)
CornerMenu.Parent = MenuPrincipal

-- Título Atualizado
local Titulo = Instance.new("TextLabel")
Titulo.Parent = MenuPrincipal
Titulo.Size = UDim2.new(1, 0, 0, 45)
Titulo.BackgroundTransparency = 1
Titulo.Text = "WATER WALK by MKgabriel"
Titulo.TextColor3 = Color3.fromRGB(46, 204, 113)
Titulo.Font = Enum.Font.GothamBold
Titulo.TextSize = 16
Titulo.ZIndex = 6

-- Botão Start/Stop
local BotaoStart = Instance.new("TextButton")
BotaoStart.Parent = MenuPrincipal
BotaoStart.Size = UDim2.new(0, 200, 0, 45)
BotaoStart.Position = UDim2.new(0.5, -100, 0.6, -10)
BotaoStart.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
BotaoStart.Text = "START"
BotaoStart.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoStart.Font = Enum.Font.GothamBold
BotaoStart.TextSize = 16
BotaoStart.BorderSizePixel = 0
BotaoStart.ZIndex = 6

local CornerStart = Instance.new("UICorner")
CornerStart.CornerRadius = UDim.new(0, 8)
CornerStart.Parent = BotaoStart

----------------------------------------------------------------
-- 3. SISTEMA DE ARRASTE SEM CONFLITO DE CLIQUE
----------------------------------------------------------------
local arrastando = false
local abrindoMenu = true
local posClique, posicaoInicialBotao

BotaoMK.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = true
		abrindoMenu = true
		posClique = input.Position
		posicaoInicialBotao = BotaoMK.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - posClique
		if delta.Magnitude > 8 then
			abrindoMenu = false
			BotaoMK.Position = UDim2.new(posicaoInicialBotao.X.Scale, posicaoInicialBotao.X.Offset + delta.X, posicaoInicialBotao.Y.Scale, posicaoInicialBotao.Y.Offset + delta.Y)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if arrastando then
			arrastando = false
			if abrindoMenu then
				MenuPrincipal.Visible = not MenuPrincipal.Visible
			end
		end
	end
end)

----------------------------------------------------------------
-- 4. NOVO MOTOR DE FILTRO E CAMINHADA SOBRE AS ÁGUAS
----------------------------------------------------------------
local function gerenciarCaminhadaAgua()
	if not Sistema_Ativo then return end

	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	-- Configura os parâmetros do sensor para rastrear o terreno de água abaixo de você
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character, PlataformaAgua}
	raycastParams.IgnoreWater = false -- Detecta estritamente a água do terreno

	-- Lança um raio para baixo a partir do tronco do jogador
	local resultadoRaio = Workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), raycastParams)

	if resultadoRaio and resultadoRaio.Material == Enum.Material.Water then
		-- Cria a plataforma física se ela ainda não existir no frame atual
		if not PlataformaAgua then
			PlataformaAgua = Instance.new("Part")
			PlataformaAgua.Name = "PlataformaWaterWalk_MK"
			PlataformaAgua.Size = Vector3.new(6, 0.4, 6) -- Tamanho ideal para suporte sob os pés
			PlataformaAgua.Transparency = 1 -- Totalmente invisível para manter a estética limpa
			PlataformaAgua.Anchored = true
			PlataformaAgua.CanCollide = true
			PlataformaAgua.TopSurface = Enum.SurfaceType.Smooth
			PlataformaAgua.Parent = Workspace
		end
		
		-- Posiciona a plataforma invisível exatamente no nível da superfície da água
		PlataformaAgua.CFrame = CFrame.new(rootPart.Position.X, resultadoRaio.Position.Y - 0.1, rootPart.Position.Z)
	else
		-- Se você sair de cima da água (for para a terra firme), desativa a colisão temporariamente
		if PlataformaAgua then
			PlataformaAgua:Destroy()
			PlataformaAgua = nil
		end
	end
end

----------------------------------------------------------------
-- 5. GATILHOS DO BOTÃO START / STOP
----------------------------------------------------------------
local function ativarSistema()
	Sistema_Ativo = true
	Conexao_Agua = RunService.Heartbeat:Connect(gerenciarCaminhadaAgua)
end

local function desativarSistema()
	Sistema_Ativo = false
	if Conexao_Agua then
		Conexao_Agua:Disconnect()
		Conexao_Agua = nil
	end
	if PlataformaAgua then
		PlataformaAgua:Destroy()
		PlataformaAgua = nil
	end
end

BotaoStart.MouseButton1Click:Connect(function()
	if not Sistema_Ativo then
		BotaoStart.Text = "STOP"
		BotaoStart.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Transiciona para Vermelho
		ativarSistema()
	else
		BotaoStart.Text = "START"
		BotaoStart.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Retorna para Verde
		desativarSistema()
	end
end)

-- Limpeza protetiva caso o jogador resete ou morra
LocalPlayer.CharacterAdded:Connect(function()
	if Sistema_Ativo then
		desativarSistema()
		BotaoStart.Text = "START"
		BotaoStart.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end
end)
