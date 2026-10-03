--[[
    WofyyImporter v0.1
    Universal Roblox Importer
    exploit maker
]]

-- ============================================
-- CONFIG
-- ============================================
local CONFIG = {
    VERSION = "v0.1",
    LOADING_NAME = "WofyyExecutor",
    APP_NAME = "WofyyImporter",
    LOGO_URL = "rbxthumb://type=Asset&id=95661605757662&w=420&h=420",
    PANEL_WIDTH = 307,
    PANEL_HEIGHT = 371,
}

local COLORS = {
    pastelBlue = Color3.fromRGB(168, 218, 220),
    pastelGreen = Color3.fromRGB(183, 228, 199),
    softWhite = Color3.fromRGB(241, 250, 238),
    darkText = Color3.fromRGB(36, 59, 59),
    softGray = Color3.fromRGB(107, 124, 124),
    bg = Color3.fromRGB(241, 250, 238),
    headerBg = Color3.fromRGB(168, 218, 220),
    cardBg = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(183, 228, 199),
    success = Color3.fromRGB(100, 200, 100),
    error = Color3.fromRGB(220, 100, 100),
    warning = Color3.fromRGB(220, 200, 80),
    info = Color3.fromRGB(100, 180, 220),
}

-- ============================================
-- SERVICES
-- ============================================
local S = {}
local function initServices()
    local ok = pcall(function()
        S.Players = game:GetService("Players")
        S.RunService = game:GetService("RunService")
        S.UserInputService = game:GetService("UserInputService")
        S.TweenService = game:GetService("TweenService")
        S.CoreGui = game:GetService("CoreGui")
        S.StarterGui = game:GetService("StarterGui")
        S.ReplicatedStorage = game:GetService("ReplicatedStorage")
        S.ServerStorage = game:GetService("ServerStorage")
        S.ServerScriptService = game:GetService("ServerScriptService")
        S.ReplicatedFirst = game:GetService("ReplicatedFirst")
        S.Lighting = game:GetService("Lighting")
        S.SoundService = game:GetService("SoundService")
        S.Teams = game:GetService("Teams")
        S.Chat = game:GetService("Chat")
        S.MarketplaceService = game:GetService("MarketplaceService")
        S.InsertService = game:GetService("InsertService")
        S.ContentProvider = game:GetService("ContentProvider")
        S.HttpService = game:GetService("HttpService")
        S.Player = S.Players and S.Players.LocalPlayer
        S.Camera = workspace.CurrentCamera
    end)
    return ok
end

-- ============================================
-- COMPATIBILITY LAYER
-- ============================================
local ENV = {}

function ENV.detect()
    local env = {
        hasFileSystem = false,
        hasHttp = false,
        hasInsertService = false,
        hasMarketplace = false,
        canWriteSource = false,
        canLoadAsset = false,
        executor = "Unknown",
        fileAPIs = {},
        httpAPIs = {},
    }

    local fileAPIs = {"readfile","writefile","appendfile","isfile","isfolder","makefolder","delfile","delfolder","listfiles"}
    for _, api in ipairs(fileAPIs) do
        if _G[api] ~= nil then
            env.fileAPIs[api] = true
            env.hasFileSystem = true
        end
    end

    if syn and syn.request then
        env.httpAPIs.synRequest = true
        env.hasHttp = true
    end
    if http_request ~= nil then
        env.httpAPIs.http_request = true
        env.hasHttp = true
    end
    if S.HttpService and pcall(function() return S.HttpService:GetAsync end) then
        env.httpAPIs.HttpService = true
        env.hasHttp = true
    end

    if S.InsertService and pcall(function() return S.InsertService:LoadAsset end) then
        env.hasInsertService = true
        env.canLoadAsset = true
    end

    if S.MarketplaceService then
        env.hasMarketplace = true
    end

    local testScript = Instance.new("Script")
    local testSource = "print('test')"
    local writeOk = pcall(function()
        testScript.Source = testSource
        return testScript.Source == testSource
    end)
    env.canWriteSource = writeOk
    testScript:Destroy()

    if syn then env.executor = "Synapse" end
    if KRNL then env.executor = "Krnl" end
    if fluxus then env.executor = "Fluxus" end
    if Delta then env.executor = "Delta" end
    if Arceus then env.executor = "Arceus" end
    if script and script.Name then env.executor = script.Name end

    return env
end

local envData = {}

-- ============================================
-- UTILITY
-- ============================================
local Utils = {}

function Utils.makeDraggable(frame, dragArea, doClamp)
    local dragging = false
    local dragStart, startPos = nil, nil
    local threshold = 8
    local wasDrag = false

    local function clampPos(newX, newY)
        if not doClamp then return newX, newY end
        local viewSize = S.Camera.ViewportSize
        local absSize = frame.AbsoluteSize
        local maxX = math.max(0, viewSize.X - absSize.X)
        local maxY = math.max(0, viewSize.Y - absSize.Y)
        return math.clamp(newX, 0, maxX), math.clamp(newY, 0, maxY)
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDrag = false
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = (input.Position - dragStart).Magnitude
            if delta > threshold then
                wasDrag = true
                local newX = startPos.X.Offset + (input.Position.X - dragStart.X)
                local newY = startPos.Y.Offset + (input.Position.Y - dragStart.Y)
                newX, newY = clampPos(newX, newY)
                frame.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    dragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Utils.clampPosition(frame)
    local viewSize = S.Camera.ViewportSize
    local absSize = frame.AbsoluteSize
    local pos = frame.AbsolutePosition
    local maxX = math.max(0, viewSize.X - absSize.X)
    local maxY = math.max(0, viewSize.Y - absSize.Y)
    local newX = math.clamp(pos.X, 0, maxX)
    local newY = math.clamp(pos.Y, 0, maxY)
    frame.Position = UDim2.new(0, newX, 0, newY)
end

function Utils.newFrame(parent, size, pos, color, trans)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or COLORS.softWhite
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = f
    return f
end

function Utils.newStroke(frame, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.pastelBlue
    s.Thickness = thick or 1
    s.Parent = frame
    return s
end

function Utils.newLabel(parent, size, pos, text, color, textSize, font, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or COLORS.darkText
    l.TextSize = textSize or 14
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

function Utils.newButton(parent, size, pos, text, color, txtColor, cb)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = color or COLORS.accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = txtColor or COLORS.darkText
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    if cb then
        b.MouseButton1Click:Connect(cb)
    end
    return b
end

function Utils.newTextBox(parent, size, pos, placeholder)
    local tb = Instance.new("TextBox")
    tb.Size = size
    tb.Position = pos
    tb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tb.BackgroundTransparency = 0.5
    tb.BorderSizePixel = 0
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = COLORS.softGray
    tb.TextColor3 = COLORS.darkText
    tb.TextSize = 13
    tb.Font = Enum.Font.Gotham
    tb.ClearTextOnFocus = false
    tb.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = tb
    local s = Instance.new("UIStroke")
    s.Color = COLORS.pastelBlue
    s.Thickness = 1
    s.Parent = tb
    return tb
end

function Utils.newImage(parent, size, pos, url)
    local img = Instance.new("ImageLabel")
    img.Size = size
    img.Position = pos
    img.BackgroundTransparency = 1
    img.Image = url
    img.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = img
    return img
end

function Utils.newScroll(parent, size, pos)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = size
    sf.Position = pos
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = COLORS.pastelBlue
    sf.BorderSizePixel = 0
    sf.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = sf
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = sf
    return sf, layout
end

function Utils.now()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
local Notification = {}
local notifParent = nil

function Notification.setParent(p)
    notifParent = p
end

function Notification.show(message, status)
    status = status or "info"
    local statusColors = {
        success = COLORS.success,
        error = COLORS.error,
        warning = COLORS.warning,
        info = COLORS.info,
    }
    local color = statusColors[status] or COLORS.info
    local parent = notifParent or S.CoreGui
    if not parent then return end

    local container = parent:FindFirstChild("WofyyToastContainer")
    if not container then
        container = Instance.new("Frame")
        container.Name = "WofyyToastContainer"
        container.Size = UDim2.new(0, 260, 0, 0)
        container.Position = UDim2.new(1, -280, 0, 50)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ZIndex = 999
        container.Parent = parent
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 34)
    toast.BackgroundColor3 = color
    toast.BackgroundTransparency = 0.15
    toast.BorderSizePixel = 0
    toast.Parent = container

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = toast

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = message
    lbl.TextColor3 = COLORS.softWhite
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    task.delay(4, function()
        if toast and toast.Parent then
            S.TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            toast:Destroy()
        end
    end)

    local count = 0
    for _, v in ipairs(container:GetChildren()) do
        if v:IsA("Frame") then count = count + 1 end
    end
    container.Size = UDim2.new(0, 260, 0, count * 38)
end

-- ============================================
-- OUTPUT MANAGER
-- ============================================
local OutputManager = {
    fileLogs = {},
    toolboxLogs = {},
    maxLogs = 150,
}

function OutputManager.addFileLog(msg, status)
    status = status or "info"
    table.insert(OutputManager.fileLogs, {msg = msg, status = status, time = Utils.now()})
    if #OutputManager.fileLogs > OutputManager.maxLogs then
        table.remove(OutputManager.fileLogs, 1)
    end
    OutputManager.refreshFile()
end

function OutputManager.addToolboxLog(msg, status)
    status = status or "info"
    table.insert(OutputManager.toolboxLogs, {msg = msg, status = status, time = Utils.now()})
    if #OutputManager.toolboxLogs > OutputManager.maxLogs then
        table.remove(OutputManager.toolboxLogs, 1)
    end
    OutputManager.refreshToolbox()
end

function OutputManager.clearFile()
    OutputManager.fileLogs = {}
    OutputManager.refreshFile()
end

function OutputManager.clearToolbox()
    OutputManager.toolboxLogs = {}
    OutputManager.refreshToolbox()
end

function OutputManager.clearAll()
    OutputManager.clearFile()
    OutputManager.clearToolbox()
end

function OutputManager.refreshFile()
    if not OutputManager.fileBox then return end
    for _, v in ipairs(OutputManager.fileBox:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
    end
    if #OutputManager.fileLogs == 0 then
        Utils.newLabel(OutputManager.fileBox, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 4), "No file output yet", COLORS.softGray, 11)
        return
    end
    local statusColors = {info = COLORS.info, success = COLORS.success, error = COLORS.error, warning = COLORS.warning}
    for _, entry in ipairs(OutputManager.fileLogs) do
        local color = statusColors[entry.status] or COLORS.info
        Utils.newLabel(OutputManager.fileBox, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, 0), "[" .. entry.time .. "] " .. entry.msg, color, 9, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    end
end

function OutputManager.refreshToolbox()
    if not OutputManager.toolboxBox then return end
    for _, v in ipairs(OutputManager.toolboxBox:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
    end
    if #OutputManager.toolboxLogs == 0 then
        Utils.newLabel(OutputManager.toolboxBox, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 4), "No toolbox output yet", COLORS.softGray, 11)
        return
    end
    local statusColors = {info = COLORS.info, success = COLORS.success, error = COLORS.error, warning = COLORS.warning}
    for _, entry in ipairs(OutputManager.toolboxLogs) do
        local color = statusColors[entry.status] or COLORS.info
        Utils.newLabel(OutputManager.toolboxBox, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, 0), "[" .. entry.time .. "] " .. entry.msg, color, 9, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    end
end

-- ============================================
-- FILE DETECTOR
-- ============================================
local FileDetector = {}

function FileDetector.getExt(filename)
    if not filename then return nil end
    local ext = filename:match("%.([^%.]+)$")
    return ext and ext:lower() or nil
end

function FileDetector.getFormat(filename)
    local ext = FileDetector.getExt(filename)
    local fmts = {rbxm = "RBXM", rbxmx = "RBXMX", rbxl = "RBXL", rbxlx = "RBXLX", model = "Model", xml = "XML", json = "JSON"}
    return fmts[ext] or "Unknown"
end

function FileDetector.isSupported(filename)
    local supported = {rbxm = true, rbxmx = true, rbxl = true, rbxlx = true, model = true, xml = true, json = true}
    local ext = FileDetector.getExt(filename)
    return ext and supported[ext] or false
end

function FileDetector.scan()
    local files = {}
    if not envData.hasFileSystem then
        OutputManager.addFileLog("Filesystem unavailable in this environment", "error")
        return files
    end
    local ok, fileList = pcall(listfiles, ".")
    if not ok or type(fileList) ~= "table" then
        OutputManager.addFileLog("Failed to list files", "error")
        return files
    end
    for _, fp in ipairs(fileList) do
        local name = fp:match("([^/\\]+)$")
        if name and FileDetector.isSupported(name) then
            local info = {path = fp, name = name, ext = FileDetector.getExt(name), format = FileDetector.getFormat(name), size = 0}
            local sizeOk, sizeData = pcall(function() return #readfile(fp) end)
            if sizeOk then info.size = sizeData end
            table.insert(files, info)
        end
    end
    return files
end

-- ============================================
-- FILE PARSER
-- ============================================
local FileParser = {}

function FileParser.parseRBXM(path)
    OutputManager.addFileLog("RBXM detected: " .. path, "info")
    return {success = false, reason = "RBXM binary parsing unavailable in this environment. Use InsertService if available."}
end

function FileParser.parseRBXMX(path)
    OutputManager.addFileLog("Parsing RBXMX: " .. path, "info")
    if not envData.hasFileSystem then
        return {success = false, reason = "Filesystem unavailable"}
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return {success = false, reason = "Cannot read file"}
    end
    local instances = {}
    local sources = {}
    local parseOk = pcall(function()
        for itemBlock in content:gmatch("<Item class=\"([^\"]+)\"[^>]*>(.-)</Item>") do
            local class = itemBlock
            local data = itemBlock
            local name = data:match("<string name=\"Name\">([^<]+)</string>") or "Unknown"
            local src = data:match("<ProtectedString name=\"Source\">(.-)</ProtectedString>")
            if src then
                src = src:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&apos;", "'")
                sources[name] = src
            end
            table.insert(instances, {class = class, name = name})
        end
    end)
    if not parseOk then
        return {success = false, reason = "Invalid RBXMX file"}
    end
    return {success = true, format = "RBXMX", instances = instances, sources = sources, count = #instances}
end

function FileParser.parseRBXL(path)
    OutputManager.addFileLog("RBXL detected: " .. path, "info")
    return {success = false, reason = "RBXL binary place parsing unavailable in this environment"}
end

function FileParser.parseRBXLX(path)
    OutputManager.addFileLog("Parsing RBXLX: " .. path, "info")
    if not envData.hasFileSystem then
        return {success = false, reason = "Filesystem unavailable"}
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return {success = false, reason = "Cannot read file"}
    end
    local instances = {}
    local sources = {}
    local parseOk = pcall(function()
        for itemBlock in content:gmatch("<Item class=\"([^\"]+)\"[^>]*>(.-)</Item>") do
            local class = itemBlock
            local data = itemBlock
            local name = data:match("<string name=\"Name\">([^<]+)</string>") or "Unknown"
            local src = data:match("<ProtectedString name=\"Source\">(.-)</ProtectedString>")
            if src then
                src = src:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&apos;", "'")
                sources[name] = src
            end
            table.insert(instances, {class = class, name = name})
        end
    end)
    if not parseOk then
        return {success = false, reason = "Invalid RBXLX file"}
    end
    return {success = true, format = "RBXLX", instances = instances, sources = sources, count = #instances}
end

function FileParser.parseXML(path)
    OutputManager.addFileLog("Parsing XML: " .. path, "info")
    if not envData.hasFileSystem then
        return {success = false, reason = "Filesystem unavailable"}
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return {success = false, reason = "Cannot read file"}
    end
    return {success = true, format = "XML", content = content}
end

function FileParser.parseJSON(path)
    OutputManager.addFileLog("Parsing JSON: " .. path, "info")
    if not envData.hasFileSystem then
        return {success = false, reason = "Filesystem unavailable"}
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return {success = false, reason = "Cannot read file"}
    end
    local decOk, data = pcall(S.HttpService.JSONDecode, S.HttpService, content)
    if not decOk then
        return {success = false, reason = "Invalid JSON"}
    end
    return {success = true, format = "JSON", data = data}
end

function FileParser.parse(path)
    local ext = FileDetector.getExt(path)
    local parsers = {
        rbxm = FileParser.parseRBXM,
        rbxmx = FileParser.parseRBXMX,
        rbxl = FileParser.parseRBXL,
        rbxlx = FileParser.parseRBXLX,
        model = FileParser.parseRBXMX,
        xml = FileParser.parseXML,
        json = FileParser.parseJSON,
    }
    local parser = parsers[ext]
    if not parser then
        return {success = false, reason = "Unsupported format: " .. tostring(ext)}
    end
    return parser(path)
end

-- ============================================
-- IMPORT MANAGER
-- ============================================
local ImportManager = {
    imported = {},
}

function ImportManager.createFolder(name, instances, sources)
    local baseName = name:match("([^%.]+)") or "Unknown"
    local rootName = baseName .. " INSERTER WOFYY"
    if workspace:FindFirstChild(rootName) then
        rootName = rootName .. " (2)"
    end
    local root = Instance.new("Folder")
    root.Name = rootName
    root.Parent = workspace

    local folders = {
        Workspace = Instance.new("Folder"),
        SG = Instance.new("Folder"),
        SSS = Instance.new("Folder"),
        SS = Instance.new("Folder"),
        RS = Instance.new("Folder"),
        RF = Instance.new("Folder"),
        Lighting = Instance.new("Folder"),
        SoundService = Instance.new("Folder"),
        Teams = Instance.new("Folder"),
        Chat = Instance.new("Folder"),
        StarterPlayer = Instance.new("Folder"),
        StarterPlayerScripts = Instance.new("Folder"),
        StarterCharacterScripts = Instance.new("Folder"),
        StarterPack = Instance.new("Folder"),
        _Unknown = Instance.new("Folder"),
    }
    for k, v in pairs(folders) do
        v.Name = k
        v.Parent = root
    end

    local totalScripts = 0
    local preserved = 0
    local totalSources = 0

    if instances then
        for _, inst in ipairs(instances) do
            local svc = "_Unknown"
            if inst.class:find("Script") then svc = "SSS"; totalScripts = totalScripts + 1
            elseif inst.class:find("LocalScript") then svc = "SG"; totalScripts = totalScripts + 1
            elseif inst.class:find("ModuleScript") then svc = "RS"; totalScripts = totalScripts + 1
            elseif inst.class:find("Part") or inst.class:find("Model") or inst.class:find("Mesh") then svc = "Workspace"
            end
            local target = folders[svc] or folders._Unknown
            local newInst = Instance.new(inst.class)
            newInst.Name = inst.name
            newInst.Parent = target
            if sources and sources[inst.name] then
                totalSources = totalSources + 1
                if envData.canWriteSource and (newInst:IsA("Script") or newInst:IsA("LocalScript") or newInst:IsA("ModuleScript")) then
                    local srcOk = pcall(function() newInst.Source = sources[inst.name] end)
                    if srcOk then preserved = preserved + 1 end
                end
            end
        end
    end

    ImportManager.imported[rootName] = true
    OutputManager.addFileLog("Folder created: " .. rootName, "success")
    OutputManager.addFileLog("Instances: " .. tostring(#(instances or {})) .. ", Scripts: " .. tostring(totalScripts) .. ", Sources: " .. tostring(preserved) .. "/" .. tostring(totalSources), preserved == totalSources and "success" or "warning")
    Notification.show("Imported: " .. name, "success")
    return true
end

function ImportManager.importFile(fileInfo)
    local result = FileParser.parse(fileInfo.path)
    if not result.success then
        OutputManager.addFileLog("Failed: " .. fileInfo.name .. " - " .. (result.reason or "?"), "error")
        Notification.show("Failed: " .. fileInfo.name, "error")
        return false
    end
    OutputManager.addFileLog("Parsed: " .. fileInfo.name .. " (" .. result.format .. ")", "success")
    return ImportManager.createFolder(fileInfo.name, result.instances, result.sources)
end

-- ============================================
-- TOOLBOX MANAGER
-- ============================================
local ToolboxManager = {
    cache = {},
    categories = {"All","Models","Audio","Images","Decals","Plugins","Meshes","Packages","Other Assets"},
}

function ToolboxManager.search(query, category, cb)
    if not envData.hasHttp then
        OutputManager.addToolboxLog("HTTP unavailable - Toolbox search requires HTTP", "error")
        Notification.show("Toolbox unavailable (no HTTP)", "error")
        if cb then cb({}) end
        return
    end
    local cacheKey = query .. "|" .. category
    if ToolboxManager.cache[cacheKey] then
        if cb then cb(ToolboxManager.cache[cacheKey]) end
        return
    end
    OutputManager.addToolboxLog("Searching: " .. query, "info")
    local url = "https://catalog.roblox.com/v1/search/items/details"
    local params = "?Keyword=" .. S.HttpService:UrlEncode(query) .. "&Limit=15"
    if category and category ~= "All" then
        local catMap = {Models = 1, Audio = 3, Images = 4, Decals = 13, Plugins = 10, Meshes = 6, Packages = 19}
        local catId = catMap[category]
        if catId then params = params .. "&Category=" .. tostring(catId) end
    end
    local ok, data = pcall(function()
        local resp = S.HttpService:GetAsync(url .. params, true)
        return S.HttpService:JSONDecode(resp)
    end)
    if not ok then
        OutputManager.addToolboxLog("Search failed", "error")
        if cb then cb({}) end
        return
    end
    local results = data and data.data or {}
    ToolboxManager.cache[cacheKey] = results
    OutputManager.addToolboxLog("Found " .. tostring(#results) .. " results", "success")
    if cb then cb(results) end
end

function ToolboxManager.getThumb(id, aType)
    return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
end

function ToolboxManager.insertAsset(assetId)
    if not envData.canLoadAsset then
        OutputManager.addToolboxLog("Insert failed: Asset loading unavailable", "error")
        Notification.show("Insert failed: Asset loading unavailable", "error")
        return false
    end
    OutputManager.addToolboxLog("Inserting asset: " .. tostring(assetId), "info")
    local ok, model = pcall(S.InsertService.LoadAsset, S.InsertService, assetId)
    if ok and model then
        model.Parent = workspace
        OutputManager.addToolboxLog("Successfully inserted: " .. tostring(assetId), "success")
        Notification.show("Asset inserted", "success")
        return true
    end
    OutputManager.addToolboxLog("Failed to insert: " .. tostring(assetId), "error")
    Notification.show("Insert failed", "error")
    return false
end

-- ============================================
-- UI BUILD
-- ============================================
local gui, win, floatingIcon = nil, nil, nil
local UI = {}

function UI.buildLoading()
    local sg = Instance.new("ScreenGui")
    sg.Name = CONFIG.LOADING_NAME
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    local playerGui = S.Player and S.Player:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = Instance.new("PlayerGui")
        playerGui.Name = "PlayerGui"
        playerGui.Parent = S.Player
    end
    sg.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = COLORS.pastelBlue
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.pastelBlue),
        ColorSequenceKeypoint.new(1, COLORS.pastelGreen),
    })
    grad.Rotation = 45
    grad.Parent = bg

    local logo = Utils.newImage(bg, UDim2.new(0, 72, 0, 72), UDim2.new(0.5, -36, 0.3, -36), CONFIG.LOGO_URL)
    local title = Utils.newLabel(bg, UDim2.new(0, 280, 0, 36), UDim2.new(0.5, -140, 0.48, -18), CONFIG.LOADING_NAME, COLORS.darkText, 26, Enum.Font.GothamBold)
    local sub = Utils.newLabel(bg, UDim2.new(0, 200, 0, 20), UDim2.new(0.5, -100, 0.56, 0), CONFIG.APP_NAME .. " " .. CONFIG.VERSION, COLORS.softGray, 13)

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 180, 0, 4)
    barBg.Position = UDim2.new(0.5, -90, 0.66, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    barBg.BackgroundTransparency = 0.5
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 2)
    bc.Parent = barBg

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = COLORS.pastelGreen
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    local bfc = Instance.new("UICorner")
    bfc.CornerRadius = UDim.new(0, 2)
    bfc.Parent = bar

    local status = Utils.newLabel(bg, UDim2.new(0, 280, 0, 18), UDim2.new(0.5, -140, 0.72, 0), "Initializing...", COLORS.softGray, 11)
    return sg, bar, status
end

function UI.buildMain()
    gui = Instance.new("ScreenGui")
    gui.Name = CONFIG.APP_NAME
    gui.ResetOnSpawn = false
    gui.Parent = S.CoreGui

    win = Instance.new("Frame")
    win.Size = UDim2.new(0, CONFIG.PANEL_WIDTH, 0, CONFIG.PANEL_HEIGHT)
    win.Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH/2, 0.5, -CONFIG.PANEL_HEIGHT/2)
    win.BackgroundColor3 = COLORS.bg
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui

    local wc = Instance.new("UICorner")
    wc.CornerRadius = UDim.new(0, 12)
    wc.Parent = win

    local ws = Instance.new("UIStroke")
    ws.Color = COLORS.pastelBlue
    ws.Thickness = 1.5
    ws.Parent = win

    -- Header
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 38)
    hdr.BackgroundColor3 = COLORS.pastelBlue
    hdr.BackgroundTransparency = 0.2
    hdr.BorderSizePixel = 0
    hdr.Parent = win

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 12)
    hc.Parent = hdr

    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(1, 0, 0, 12)
    mask.Position = UDim2.new(0, 0, 1, -12)
    mask.BackgroundColor3 = COLORS.bg
    mask.BorderSizePixel = 0
    mask.Parent = hdr

    local hLogo = Utils.newImage(hdr, UDim2.new(0, 24, 0, 24), UDim2.new(0, 10, 0.5, -12), CONFIG.LOGO_URL)
    local hTitle = Utils.newLabel(hdr, UDim2.new(0, 140, 1, 0), UDim2.new(0, 38, 0, 0), CONFIG.APP_NAME, COLORS.darkText, 13, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    local hVer = Utils.newLabel(hdr, UDim2.new(0, 36, 1, 0), UDim2.new(0, 165, 0, 0), CONFIG.VERSION, COLORS.softGray, 9, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    local hCredit = Utils.newLabel(hdr, UDim2.new(0, 44, 1, 0), UDim2.new(1, -98, 0, 0), "Wofyy", COLORS.darkText, 9, Enum.Font.Gotham, Enum.TextXAlignment.Right)
    hCredit.TextTransparency = 0.4

    local minBtn = Utils.newButton(hdr, UDim2.new(0, 22, 0, 22), UDim2.new(1, -58, 0.5, -11), "-", COLORS.cardBg, COLORS.darkText, function()
        if win then win.Visible = false end
        if floatingIcon then floatingIcon.Visible = true end
    end)

    local closeBtn = Utils.newButton(hdr, UDim2.new(0, 22, 0, 22), UDim2.new(1, -30, 0.5, -11), "X", Color3.fromRGB(220, 100, 100), Color3.fromRGB(255, 255, 255), function()
        UI.cleanup()
    end)

    -- Drag via header
    Utils.makeDraggable(win, hdr, true)

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -16, 0, 34)
    tabBar.Position = UDim2.new(0, 8, 0, 40)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = win

    local tabs = {"Importer", "Toolbox", "Output"}
    local tabBtns = {}
    local tabContents = {}
    local activeTab = 1
    local tw = (CONFIG.PANEL_WIDTH - 16) / 3

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, tw - 4, 0, 28)
        btn.Position = UDim2.new(0, (i-1) * tw + 2, 0, 3)
        btn.BackgroundColor3 = i == 1 and COLORS.accent or Color3.fromRGB(230, 230, 230)
        btn.BackgroundTransparency = i == 1 and 0 or 0.3
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = i == 1 and COLORS.darkText or COLORS.softGray
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = tabBar
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = btn
        tabBtns[i] = btn
        btn.MouseButton1Click:Connect(function()
            activeTab = i
            for j, b in ipairs(tabBtns) do
                b.BackgroundColor3 = j == i and COLORS.accent or Color3.fromRGB(230, 230, 230)
                b.BackgroundTransparency = j == i and 0 or 0.3
                b.TextColor3 = j == i and COLORS.darkText or COLORS.softGray
            end
            for j, c in ipairs(tabContents) do
                c.Visible = (j == i)
            end
        end)
    end

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -8, 1, -86)
    contentArea.Position = UDim2.new(0, 4, 0, 78)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = win

    -- Build tabs
    tabContents[1] = UI.buildImporter(contentArea)
    tabContents[2] = UI.buildToolbox(contentArea)
    tabContents[3] = UI.buildOutput(contentArea)

    -- Floating icon
    UI.buildFloating()

    -- Viewport handler
    S.RunService:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if win and win.Visible then Utils.clampPosition(win) end
        if floatingIcon and floatingIcon.Visible then Utils.clampPosition(floatingIcon) end
    end)

    -- Keybind
    S.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            if win and floatingIcon then
                if win.Visible then
                    win.Visible = false
                    floatingIcon.Visible = true
                else
                    win.Visible = true
                    floatingIcon.Visible = false
                end
            end
        end
    end)

    return win
end

function UI.buildImporter(container)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = true
    frame.Parent = container

    local search = Utils.newTextBox(frame, UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 2), "Search files...")
    local scanBtn = Utils.newButton(frame, UDim2.new(0, 72, 0, 26), UDim2.new(1, -88, 0, 2), "SCAN", COLORS.accent, COLORS.darkText)
    local statusLbl = Utils.newLabel(frame, UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 36), "No files scanned", COLORS.softGray, 10, Enum.Font.Gotham, Enum.TextXAlignment.Left)

    local fileList, flLayout = Utils.newScroll(frame, UDim2.new(1, -16, 1, -80), UDim2.new(0, 8, 0, 58))
    local scannedFiles = {}

    local function doScan()
        statusLbl.Text = "Scanning..."
        scanBtn.Text = "..."
        scanBtn.Active = false
        task.delay(0.5, function()
            scannedFiles = FileDetector.scan()
            for _, v in ipairs(fileList:GetChildren()) do
                if v:IsA("Frame") then v:Destroy() end
            end
            if #scannedFiles == 0 then
                statusLbl.Text = envData.hasFileSystem and "No supported files found" or "Filesystem unavailable"
            else
                statusLbl.Text = "Found " .. tostring(#scannedFiles) .. " files"
                for _, fi in ipairs(scannedFiles) do
                    local card = Utils.newFrame(fileList, UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 0, 0), COLORS.cardBg)
                    Utils.newStroke(card, COLORS.pastelBlue, 1)
                    Utils.newLabel(card, UDim2.new(1, -80, 0, 18), UDim2.new(0, 8, 0, 3), fi.name, COLORS.darkText, 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
                    Utils.newLabel(card, UDim2.new(1, -80, 0, 16), UDim2.new(0, 8, 0, 22), fi.format, COLORS.softGray, 9, Enum.Font.Gotham, Enum.TextXAlignment.Left)
                    local sz = fi.size > 0 and string.format("%.1fKB", fi.size/1024) or ""
                    Utils.newLabel(card, UDim2.new(0, 60, 0, 14), UDim2.new(1, -72, 0, 2), sz, COLORS.softGray, 8, Enum.Font.Gotham, Enum.TextXAlignment.Right)
                    Utils.newButton(card, UDim2.new(0, 60, 0, 22), UDim2.new(1, -70, 0, 18), "INSERT", COLORS.accent, COLORS.darkText, function()
                        ImportManager.importFile(fi)
                    end)
                end
            end
            scanBtn.Text = "SCAN"
            scanBtn.Active = true
        end)
    end

    scanBtn.MouseButton1Click:Connect(doScan)

    local searchDeb = false
    search:GetPropertyChangedSignal("Text"):Connect(function()
        if searchDeb then return end
        searchDeb = true
        task.delay(0.3, function()
            searchDeb = false
            local q = search.Text:lower()
            for _, v in ipairs(fileList:GetChildren()) do
                if v:IsA("Frame") then
                    local lbl = v:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        v.Visible = q == "" or (lbl.Text:lower():find(q) ~= nil)
                    end
                end
            end
        end)
    end)

    return frame
end

function UI.buildToolbox(container)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = container

    local search = Utils.newTextBox(frame, UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 2), "Search Toolbox...")

    -- Category bar
    local catScroll = Instance.new("ScrollingFrame")
    catScroll.Size = UDim2.new(1, -16, 0, 30)
    catScroll.Position = UDim2.new(0, 8, 0, 36)
    catScroll.BackgroundTransparency = 1
    catScroll.ScrollBarThickness = 0
    catScroll.BorderSizePixel = 0
    catScroll.Parent = frame

    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 4)
    catLayout.Parent = catScroll

    local selCat = "All"
    local catBtns = {}

    for _, cat in ipairs(ToolboxManager.categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 0, 24)
        btn.BackgroundColor3 = cat == "All" and COLORS.accent or Color3.fromRGB(230, 230, 230)
        btn.BackgroundTransparency = cat == "All" and 0 or 0.3
        btn.BorderSizePixel = 0
        btn.Text = cat
        btn.TextColor3 = cat == "All" and COLORS.darkText or COLORS.softGray
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamBold
        btn.Parent = catScroll
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 4)
        bc.Parent = btn
        btn.Size = UDim2.new(0, btn.TextBounds.X + 14, 0, 24)
        catBtns[cat] = btn
        btn.MouseButton1Click:Connect(function()
            selCat = cat
            for k, b in pairs(catBtns) do
                b.BackgroundColor3 = k == cat and COLORS.accent or Color3.fromRGB(230, 230, 230)
                b.BackgroundTransparency = k == cat and 0 or 0.3
                b.TextColor3 = k == cat and COLORS.darkText or COLORS.softGray
            end
            if search.Text ~= "" then doSearch() end
        end)
    end

    catScroll.CanvasSize = UDim2.new(0, #ToolboxManager.categories * 90, 0, 0)

    local resScroll, resLayout = Utils.newScroll(frame, UDim2.new(1, -16, 1, -80), UDim2.new(0, 8, 0, 70))
    local emptyLbl = Utils.newLabel(resScroll, UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 16), "Search Toolbox\nFind models, audio, images, plugins and other assets.", COLORS.softGray, 10)

    local searchDeb = false

    local function doSearch()
        local q = search.Text
        if q == "" then
            for _, v in ipairs(resScroll:GetChildren()) do
                if v:IsA("Frame") then v:Destroy() end
            end
            emptyLbl.Visible = true
            return
        end
        emptyLbl.Visible = false
        for _, v in ipairs(resScroll:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        ToolboxManager.search(q, selCat, function(results)
            if #results == 0 then
                Utils.newLabel(resScroll, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 8), "No results found", COLORS.softGray, 11)
                return
            end
            for _, asset in ipairs(results) do
                local card = Utils.newFrame(resScroll, UDim2.new(1, -16, 0, 58), UDim2.new(0, 8, 0, 0), COLORS.cardBg)
                Utils.newStroke(card, COLORS.pastelBlue, 1)
                local thumb = Utils.newImage(card, UDim2.new(0, 42, 0, 42), UDim2.new(0, 6, 0.5, -21), ToolboxManager.getThumb(asset.id, asset.assetTypeString))
                Utils.newLabel(card, UDim2.new(1, -120, 0, 16), UDim2.new(0, 54, 0, 2), asset.name or "Unknown", COLORS.darkText, 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
                Utils.newLabel(card, UDim2.new(1, -120, 0, 14), UDim2.new(0, 54, 0, 18), asset.assetTypeString or "Asset", COLORS.softGray, 9, Enum.Font.Gotham, Enum.TextXAlignment.Left)
                Utils.newLabel(card, UDim2.new(1, -120, 0, 14), UDim2.new(0, 54, 0, 32), "ID: " .. tostring(asset.id), COLORS.softGray, 8, Enum.Font.Gotham, Enum.TextXAlignment.Left)
                Utils.newButton(card, UDim2.new(0, 54, 0, 22), UDim2.new(1, -64, 0.5, -11), "INSERT", COLORS.accent, COLORS.darkText, function()
                    ToolboxManager.insertAsset(asset.id)
                end)
            end
        end)
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        if searchDeb then return end
        searchDeb = true
        task.delay(0.5, function()
            searchDeb = false
            doSearch()
        end)
    end)

    return frame
end

function UI.buildOutput(container)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = container

    Utils.newLabel(frame, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 2), "FILE INSERT OUTPUT", COLORS.darkText, 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

    local fileScroll, fl = Utils.newScroll(frame, UDim2.new(1, -16, 0, 110), UDim2.new(0, 8, 0, 24))
    OutputManager.fileBox = fileScroll

    Utils.newButton(frame, UDim2.new(0, 120, 0, 20), UDim2.new(0, 8, 0, 138), "Clear File Output", COLORS.softGray, COLORS.softWhite, function()
        OutputManager.clearFile()
    end)

    Utils.newLabel(frame, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 164), "TOOLBOX INSERT OUTPUT", COLORS.darkText, 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

    local tbScroll, tl = Utils.newScroll(frame, UDim2.new(1, -16, 0, 110), UDim2.new(0, 8, 0, 186))
    OutputManager.toolboxBox = tbScroll

    Utils.newButton(frame, UDim2.new(0, 140, 0, 20), UDim2.new(0, 8, 0, 300), "Clear Toolbox Output", COLORS.softGray, COLORS.softWhite, function()
        OutputManager.clearToolbox()
    end)

    Utils.newButton(frame, UDim2.new(0, 72, 0, 20), UDim2.new(1, -88, 0, 300), "Clear All", COLORS.softGray, COLORS.softWhite, function()
        OutputManager.clearAll()
    end)

    OutputManager.refreshFile()
    OutputManager.refreshToolbox()
    return frame
end

function UI.buildFloating()
    floatingIcon = Instance.new("ImageButton")
    floatingIcon.Size = UDim2.new(0, 40, 0, 40)
    floatingIcon.Position = UDim2.new(0, 10, 0.5, -20)
    floatingIcon.BackgroundColor3 = COLORS.pastelBlue
    floatingIcon.BackgroundTransparency = 0.2
    floatingIcon.BorderColor3 = COLORS.pastelGreen
    floatingIcon.BorderSizePixel = 2
    floatingIcon.Image = CONFIG.LOGO_URL
    floatingIcon.Visible = false
    floatingIcon.ZIndex = 999
    floatingIcon.Parent = gui

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 20)
    fc.Parent = floatingIcon

    Utils.makeDraggable(floatingIcon, floatingIcon, true)

    floatingIcon.MouseButton1Click:Connect(function()
        if win then win.Visible = true end
        if floatingIcon then floatingIcon.Visible = false end
    end)
end

function UI.cleanup()
    if gui then
        gui:Destroy()
        gui = nil
    end
    local loadSg = S.Player and S.Player:FindFirstChild("PlayerGui") and S.Player.PlayerGui:FindFirstChild(CONFIG.LOADING_NAME)
    if loadSg then loadSg:Destroy() end
end

-- ============================================
-- INIT
-- ============================================
local function main()
    initServices()
    envData = ENV.detect()

    Notification.setParent(S.CoreGui)

    local loadSg, loadBar, loadStatus = UI.buildLoading()

    S.TweenService:Create(loadSg:FindFirstChildOfClass("Frame"), TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

    local steps = {
        "Detecting environment...",
        "Detecting executor capabilities...",
        "Initializing compatibility layer...",
        "Initializing file system...",
        "Initializing file detector...",
        "Initializing file parser...",
        "Initializing import manager...",
        "Initializing folder mode...",
        "Initializing source preservation...",
        "Initializing toolbox...",
        "Initializing output...",
        "Building UI...",
        "Connecting services...",
        "Finalizing...",
    }

    for i, step in ipairs(steps) do
        loadStatus.Text = step
        local pct = (i / #steps) * 100
        S.TweenService:Create(loadBar, TweenInfo.new(0.25), {Size = UDim2.new(0, pct * 1.8, 1, 0)}):Play()
        task.wait(0.12)
    end

    UI.buildMain()

    S.TweenService:Create(loadSg:FindFirstChildOfClass("Frame"), TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    loadSg:Destroy()

    task.wait(0.1)
    if win then Utils.clampPosition(win) end
    if floatingIcon then Utils.clampPosition(floatingIcon) end

    OutputManager.addFileLog("WofyyImporter " .. CONFIG.VERSION .. " ready", "success")
    OutputManager.addFileLog("Env: " .. envData.executor .. " | FS: " .. tostring(envData.hasFileSystem) .. " | HTTP: " .. tostring(envData.hasHttp) .. " | Source: " .. tostring(envData.canWriteSource), "info")
    Notification.show("WofyyImporter v0.1 ready", "success")
end

local ok, err = pcall(main)
if not ok then
    warn("[WofyyImporter] Error: " .. tostring(err))
    local errGui = Instance.new("ScreenGui")
    errGui.Name = "WofyyImporter_Error"
    errGui.ResetOnSpawn = false
    errGui.Parent = S.CoreGui or game:GetService("CoreGui")
    local errLbl = Instance.new("TextLabel")
    errLbl.Size = UDim2.new(0, 360, 0, 80)
    errLbl.Position = UDim2.new(0.5, -180, 0.5, -40)
    errLbl.BackgroundColor3 = COLORS.bg
    errLbl.BorderSizePixel = 0
    errLbl.Text = "WofyyImporter failed to init.\n" .. tostring(err)
    errLbl.TextColor3 = COLORS.error
    errLbl.TextSize = 13
    errLbl.Font = Enum.Font.Gotham
    errLbl.Parent = errGui
    local ec = Instance.new("UICorner")
    ec.CornerRadius = UDim.new(0, 8)
    ec.Parent = errLbl
end

print("[WofyyImporter] " .. CONFIG.VERSION .. " loaded")
print("[WofyyImporter] Press Insert to toggle")