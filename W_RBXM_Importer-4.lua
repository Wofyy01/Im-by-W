
-- ============================================
-- W (WOFY) - RBXM IMPORTER V14.2
-- ENGINE: W FULL FIXED
-- UI: W PREMIUM BLACK STYLE (PANEL 16:9)
-- SUPPORT: RBXM / RBXMX / RBXL / RBXLX
-- LOADING SCREEN: W "DIAL & PEN"
-- MODIF: Part Stabil (Tidak Roboh) & Bisa Digeser
-- ============================================
if not game:IsLoaded() then game.Loaded:Wait() end
local WofyRBXM = {}
WofyRBXM.__index = WofyRBXM
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local SECRET_KEY = "W1"
local WA_NUMBER = "083185525813"
local isAuthenticated = false
_G.W_RAW_SOURCES = _G.W_RAW_SOURCES or {}
-- ============================================
-- SCREENGUI SETUP (Delta Executor Protection)
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WImporterUI_RBXM"
screenGui.ResetOnSpawn = false
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
elseif gethui then
    screenGui.Parent = gethui()
else
    screenGui.Parent = CoreGui
end
-- ============================================
-- W LOADING SCREEN — "DIAL & PEN"
-- Monogram W digambar seperti goresan pena, dial 72 tick sebagai progress,
-- HUD monospace di sudut layar, dan penutup "tirai belah" bergaris putih.
-- ============================================
local LOADER_MIN_TIME = 3.6  -- durasi minimum loading screen (detik), ubah sesuka hati
local LOADER_MAX_TIME = 12   -- batas aman: setelah ini loading screen pasti menutup
local function createWLoader()
    local now = os.clock
    local api = { finished = false }
    local finishedCallbacks = {}
    local TOTAL_STEPS = 6
    local marks, target, readyFlag = 0, 0, false

    local function attach(g)
        if syn and syn.protect_gui then
            syn.protect_gui(g)
            g.Parent = CoreGui
        elseif gethui then
            g.Parent = gethui()
        else
            g.Parent = CoreGui
        end
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "WLoadingUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    -- Tutup sampai tepi layar (termasuk area poni/notch & gesture bar), bukan hanya safe area
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    attach(gui)
    -- Probe: ukur safe area perangkat supaya HUD (braket & teks) tidak tertutup poni
    local probeGui, probeFrame
    pcall(function()
        local pg = Instance.new("ScreenGui")
        pg.Name = "WLoadingProbe"
        pg.ResetOnSpawn = false
        pg.IgnoreGuiInset = true
        pg.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        pg.DisplayOrder = -1
        local pf = Instance.new("Frame")
        pf.Size = UDim2.new(1, 0, 1, 0)
        pf.BackgroundTransparency = 1
        pf.BorderSizePixel = 0
        pf.Parent = pg
        attach(pg)
        probeGui, probeFrame = pg, pf
    end)

    local function build()
        local WHITE = Color3.fromRGB(255, 255, 255)
        local BLACK = Color3.fromRGB(0, 0, 0)
        local MUTED = Color3.fromRGB(150, 150, 150)
        local TICK_MINOR = Color3.fromRGB(46, 46, 46)
        local TICK_MAJOR = Color3.fromRGB(84, 84, 84)

        local function make(className, props, parentObj)
            local obj = Instance.new(className)
            if obj:IsA("GuiObject") then obj.BorderSizePixel = 0 end
            for key, value in pairs(props or {}) do obj[key] = value end
            if parentObj then obj.Parent = parentObj end
            return obj
        end
        local function clamp01(x) return math.clamp(x, 0, 1) end
        local function easeOut(x) x = clamp01(x); return 1 - (1 - x) ^ 3 end
        local function easeInOut(x)
            x = clamp01(x)
            if x < 0.5 then return 8 * x ^ 4 end
            return 1 - ((-2 * x + 2) ^ 4) / 2
        end
        local function atan2(y, x)
            if math.atan2 then return math.atan2(y, x) end
            return math.atan(y, x)
        end
        local function lerpColor(a, b, k)
            return Color3.fromRGB(
                math.floor(a.R * 255 + (b.R * 255 - a.R * 255) * k + 0.5),
                math.floor(a.G * 255 + (b.G * 255 - a.G * 255) * k + 0.5),
                math.floor(a.B * 255 + (b.B * 255 - a.B * 255) * k + 0.5)
            )
        end
        local fadeSeq = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        })

        -- Tirai (dua sisi hitam) + konten
        local topHalf = make("Frame", {
            Name = "CurtainTop", Size = UDim2.new(1, 0, 0.5, 1), Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = BLACK, Active = true, ZIndex = 1,
        }, gui)
        local bottomHalf = make("Frame", {
            Name = "CurtainBottom", Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = BLACK, Active = true, ZIndex = 1,
        }, gui)
        local content = make("CanvasGroup", {
            Name = "Content", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 2,
        }, gui)

        -- HUD sudut layar (di dalam safe area, latar tetap penuh layar)
        local hudRoot = make("Frame", {
            Name = "HudRoot", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        }, content)
        local hudFrames, hudTexts = {}, {}
        local function bracket(ax, ay)
            local px = (ax == 0) and 16 or -16
            local py = (ay == 0) and 16 or -16
            for _, size in ipairs({UDim2.new(0, 22, 0, 1), UDim2.new(0, 1, 0, 22)}) do
                local line = make("Frame", {
                    AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, px, ay, py),
                    Size = size, BackgroundColor3 = WHITE, BackgroundTransparency = 1,
                }, hudRoot)
                table.insert(hudFrames, line)
            end
        end
        bracket(0, 0); bracket(1, 0); bracket(0, 1); bracket(1, 1)
        local function hudText(text, ax, ay, px, py, align, color)
            local lab = make("TextLabel", {
                Text = text, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, px, ay, py),
                Size = UDim2.new(0.5, -30, 0, 14), BackgroundTransparency = 1,
                TextColor3 = color or WHITE, Font = Enum.Font.Code, TextSize = 10,
                TextXAlignment = align, TextTransparency = 1,
            }, hudRoot)
            table.insert(hudTexts, lab)
            return lab
        end
        hudText("W  IMPORTER", 0, 0, 28, 24, Enum.TextXAlignment.Left)
        hudText("V14.2  /  RBXM · RBXL · XML", 1, 0, -28, 24, Enum.TextXAlignment.Right, MUTED)
        local stageLabel = hudText("", 0, 1, 28, -26, Enum.TextXAlignment.Left)
        local pctLabel = hudText("000%", 1, 1, -28, -26, Enum.TextXAlignment.Right)

        -- Stage (dirancang 380 x 300, diskalakan sesuai layar)
        local stage = make("Frame", {
            Name = "Stage", Size = UDim2.new(0, 380, 0, 300), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
        }, content)
        local stageScale = make("UIScale", {Scale = 1}, stage)
        local baseScale = 1
        local function updateScale()
            local vp = gui.AbsoluteSize
            if vp.X > 50 and vp.Y > 50 then
                baseScale = math.clamp(math.min(vp.Y / 330, vp.X / 420), 0.55, 1.6)
            end
            stageScale.Scale = baseScale
        end
        updateScale()
        gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

        local CX, CY = 190, 132

        -- Cincin
        local function ring(diameter, color)
            local r = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, CX, 0, CY),
                Size = UDim2.new(0, diameter, 0, diameter), BackgroundTransparency = 1,
            }, stage)
            make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, r)
            local st = make("UIStroke", {Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, r)
            return r, st
        end
        ring(146, Color3.fromRGB(34, 34, 34))
        local _, cometStroke = ring(166, WHITE)
        local cometGradient = make("UIGradient", {
            Color = ColorSequence.new(WHITE),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.35, 0.9),
                NumberSequenceKeypoint.new(0.7, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }, cometStroke)

        -- Dial tick (progress)
        local TICKS, RADIUS = 72, 100
        local ticks = {}
        for i = 1, TICKS do
            local ang = (i - 1) / TICKS * math.pi * 2
            local major = ((i - 1) % 6 == 0)
            local len = major and 12 or 6
            local thick = major and 2 or 1
            local rr = RADIUS - len / 2
            local obj = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, CX + rr * math.sin(ang), 0, CY - rr * math.cos(ang)),
                Size = UDim2.new(0, thick, 0, len), Rotation = math.deg(ang),
                BackgroundColor3 = major and TICK_MAJOR or TICK_MINOR, BackgroundTransparency = 1,
            }, stage)
            ticks[i] = { obj = obj, base = major and TICK_MAJOR or TICK_MINOR, appear = 0.15 + (i - 1) / TICKS * 0.9, alpha = -1, lit = -1 }
        end

        -- Monogram W (4 goresan)
        local WW, WH, THICK = 88, 56, 7
        local ox, oy = CX - WW / 2, CY - WH / 2 + 2
        local pts = { {0, 0}, {22, 56}, {44, 14}, {66, 56}, {88, 0} }
        local bars = {}
        for k = 1, 4 do
            local a, b = pts[k], pts[k + 1]
            local dx, dy = b[1] - a[1], b[2] - a[2]
            local len = math.sqrt(dx * dx + dy * dy)
            local bar = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, ox + (a[1] + b[1]) / 2, 0, oy + (a[2] + b[2]) / 2),
                Size = UDim2.new(0, THICK, 0, len + THICK * 0.6),
                Rotation = math.deg(atan2(-dx, dy)), BackgroundTransparency = 1, ZIndex = k,
            }, stage)
            local fill = make("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = WHITE }, bar)
            make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
            bars[k] = { fill = fill, cur = -1 }
        end

        -- Huruf WOFY + caption
        local letters = {}
        for j, ch in ipairs({"W", "O", "F", "Y"}) do
            letters[j] = { cur = -1, obj = make("TextLabel", {
                Text = ch, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, CX + (j - 2.5) * 30, 0, 256),
                Size = UDim2.new(0, 26, 0, 22), BackgroundTransparency = 1, TextColor3 = WHITE,
                Font = Enum.Font.GothamBlack, TextSize = 18, TextTransparency = 1,
            }, stage) }
        end
        local caption = make("TextLabel", {
            Text = "RBXM  ·  RBXL  ·  RBXMX  ·  RBXLX", AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0, CX, 0, 284), Size = UDim2.new(0, 300, 0, 12), BackgroundTransparency = 1,
            TextColor3 = MUTED, Font = Enum.Font.Code, TextSize = 8, TextTransparency = 1,
        }, stage)

        -- Garis scan (intro) & seam (outro)
        local scan = make("Frame", {
            Name = "Scan", Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE,
            BackgroundTransparency = 0.1, ZIndex = 4, Visible = false,
        }, gui)
        make("UIGradient", {Transparency = fadeSeq}, scan)
        local seam = make("Frame", {
            Name = "Seam", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 1), BackgroundColor3 = WHITE, ZIndex = 4, Visible = false,
        }, gui)
        make("UIGradient", {Transparency = fadeSeq}, seam)

        -- Loop animasi
        local labels = {
            "MEMULAI ENGINE", "MEMUAT DECODER LZ4", "MEMUAT PARSER RBXM / RBXL / XML",
            "SINKRON STUDIO LITE", "MENYIAPKAN ANTARMUKA", "SIAP",
        }
        local t0, shown, tOut = now(), 0, nil
        local lastLabel, labelText, typed = 0, "", 0
        local hudCache = -1
        local insL, insT, insR, insB = 0, 0, 0, 0
        local finishFired = false
        local conn

        local function fireFinished()
            if finishFired then return end
            finishFired = true
            api.finished = true
            for _, fn in ipairs(finishedCallbacks) do pcall(fn) end
        end
        local function destroyAll()
            if conn then conn:Disconnect(); conn = nil end
            if probeGui then probeGui:Destroy() end
            gui:Destroy()
        end

        local function update(dt)
            local t = now() - t0
            if t >= LOADER_MAX_TIME then target = 1 end

            -- safe area perangkat -> geser HUD agar tidak tertutup poni / sudut layar
            if probeFrame then
                local ap, as, full = probeFrame.AbsolutePosition, probeFrame.AbsoluteSize, gui.AbsoluteSize
                if as.X > 10 and as.Y > 10 and full.X > 10 and full.Y > 10 then
                    local dx, dy = math.max(full.X - as.X, 0), math.max(full.Y - as.Y, 0)
                    local l, tp
                    if ap.X > 0.5 or ap.Y > 0.5 then l, tp = ap.X, ap.Y else l, tp = dx / 2, dy / 2 end
                    local r, b = math.max(dx - l, 0), math.max(dy - tp, 0)
                    if math.abs(l - insL) > 0.5 or math.abs(tp - insT) > 0.5 or math.abs(r - insR) > 0.5 or math.abs(b - insB) > 0.5 then
                        insL, insT, insR, insB = l, tp, r, b
                        hudRoot.Position = UDim2.new(0, l, 0, tp)
                        hudRoot.Size = UDim2.new(1, -(l + r), 1, -(tp + b))
                    end
                end
            end

            -- progress (dibatasi durasi minimum)
            if not tOut then
                local goal = math.min(target, clamp01(t / LOADER_MIN_TIME))
                shown = shown + (goal - shown) * math.min(1, dt * 8)
                if goal >= 1 and shown > 0.995 then shown = 1 end
                if shown >= 1 and t >= LOADER_MIN_TIME then tOut = t end
            end

            -- scan line
            if t < 1.25 then
                scan.Visible = true
                scan.Position = UDim2.new(0, 0, easeInOut(t / 1.2), 0)
            elseif scan.Visible then
                scan.Visible = false
            end

            -- HUD fade-in
            local hudA = math.floor(clamp01((t - 0.1) / 0.6) * 20)
            if hudA ~= hudCache then
                hudCache = hudA
                local a = hudA / 20
                for _, f in ipairs(hudFrames) do f.BackgroundTransparency = 1 - a * 0.7 end
                for _, l in ipairs(hudTexts) do l.TextTransparency = 1 - a * 0.85 end
            end

            -- tick dial
            local litFloat = shown * TICKS
            for i = 1, TICKS do
                local tk = ticks[i]
                local a = math.floor(clamp01((t - tk.appear) / 0.3) * 10)
                if a ~= tk.alpha then
                    tk.alpha = a
                    tk.obj.BackgroundTransparency = 1 - a / 10
                end
                local v = math.floor(clamp01(litFloat - (i - 1)) * 10)
                if v ~= tk.lit then
                    tk.lit = v
                    tk.obj.BackgroundColor3 = lerpColor(tk.base, WHITE, v / 10)
                end
            end

            -- goresan W
            for k = 1, 4 do
                local f = math.floor(easeOut((t - 0.6 - (k - 1) * 0.32) / 0.34) * 100)
                if f ~= bars[k].cur then
                    bars[k].cur = f
                    bars[k].fill.Size = UDim2.new(1, 0, f / 100, 0)
                end
            end

            -- huruf & caption
            for j = 1, 4 do
                local a = math.floor(easeOut((t - 1.55 - (j - 1) * 0.13) / 0.4) * 20)
                if a ~= letters[j].cur then
                    letters[j].cur = a
                    letters[j].obj.TextTransparency = 1 - a / 20
                    letters[j].obj.Position = UDim2.new(0, CX + (j - 2.5) * 30, 0, 256 + (1 - a / 20) * 10)
                end
            end
            caption.TextTransparency = 1 - clamp01((t - 2.1) / 0.5) * 0.65

            -- komet di cincin
            cometGradient.Rotation = (t * 75) % 360

            -- label tahap + persen
            local idx = math.clamp(math.floor(shown * #labels) + 1, 1, #labels)
            if idx ~= lastLabel then lastLabel = idx; labelText = labels[idx]; typed = 0 end
            typed = math.min(#labelText, typed + dt * 45)
            local cursor = (math.floor(t * 2.5) % 2 == 0) and "_" or " "
            stageLabel.Text = "> " .. string.sub(labelText, 1, math.floor(typed)) .. cursor
            pctLabel.Text = string.format("%03d%%", math.floor(shown * 100 + 0.0001))

            -- outro: denyut -> seam -> tirai membelah
            if tOut then
                local u = t - tOut
                local pulse = (u < 0.4) and (1 + 0.05 * math.sin(math.pi * u / 0.4)) or 1
                stageScale.Scale = baseScale * pulse
                content.GroupTransparency = easeInOut((u - 0.4) / 0.4)
                local seamOn = (u >= 0.4 and u < 0.95)
                seam.Visible = seamOn
                if seamOn then
                    seam.Size = UDim2.new(easeOut((u - 0.4) / 0.4), 0, 0, 1)
                    seam.BackgroundTransparency = clamp01((u - 0.8) / 0.15)
                end
                if u >= 0.8 then fireFinished() end
                local open = easeInOut((u - 0.8) / 0.75)
                topHalf.Position = UDim2.new(0, 0, -0.5 * open, 0)
                bottomHalf.Position = UDim2.new(0, 0, 0.5 + 0.5 * open, 0)
                if u >= 1.6 then destroyAll() end
            end
        end

        conn = RunService.RenderStepped:Connect(function(dt)
            local ok = pcall(update, dt)
            if not ok then
                fireFinished()
                destroyAll()
            end
        end)
    end

    local ok, err = pcall(build)
    if not ok then
        if probeGui then probeGui:Destroy() end
        gui:Destroy()
        error(err, 0)
    end

    function api.mark(n)
        marks = math.max(marks, n)
        target = math.max(target, math.min(1, marks / TOTAL_STEPS))
    end
    function api.ready()
        readyFlag = true
        target = 1
    end
    function api.onFinished(fn)
        if api.finished then pcall(fn) else table.insert(finishedCallbacks, fn) end
    end
    return api
end
local okLoader, WLoader = pcall(createWLoader)
if not okLoader or type(WLoader) ~= "table" then
    warn("[W] Loading screen gagal dibuat: " .. tostring(WLoader))
    WLoader = { finished = true, mark = function() end, ready = function() end, onFinished = function(fn) pcall(fn) end }
end
WLoader.mark(1)
-- ============================================
-- SISTEM STROKE PUTIH PREMIUM (GLOBAL)
-- ============================================
local whiteGradients = {}
local function applyWhiteStroke(parentObj, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parentObj
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    grad.Parent = stroke
    table.insert(whiteGradients, grad)
    return stroke
end
task.spawn(function()
    local rot = 0
    while task.wait(0.03) do
        rot = (rot + 1.2) % 360
        for _, grad in ipairs(whiteGradients) do
            if grad and grad.Parent then
                grad.Rotation = rot
            end
        end
    end
end)
-- ============================================
-- PALETTE & STATE (BLACK + WHITE)
-- ============================================
local PALETTE = {
    Background = Color3.fromRGB(0, 0, 0),
    CardBg = Color3.fromRGB(9, 9, 9),
    InputBg = Color3.fromRGB(13, 13, 13),
    Surface = Color3.fromRGB(22, 22, 22),
    White = Color3.fromRGB(255, 255, 255),
    AccentRed = Color3.fromRGB(230, 70, 80),
    TextWhite = Color3.fromRGB(245, 245, 245),
    TextDark = Color3.fromRGB(0, 0, 0),
    TextMuted = Color3.fromRGB(150, 150, 150),
    InnerBorder = Color3.fromRGB(55, 55, 55),
}
local UIState = {
    loginFrame = nil,
    mainFrame = nil,
    sizeFrame = nil,
    musicFrame = nil,
    toggleButton = nil,
    scrollFrame = nil,
    emptyLabel = nil,
    statusLabel = nil,
    searchBox = nil,
    detectedFiles = {},
    currentFilter = "",
    isScanning = false,
    panelVisible = false,
}
-- ============================================
-- HTTP REQUEST UTILITY (from W)
-- ============================================
local function httpRequest(url, method, headers, data)
    method = method or "GET"
    headers = headers or {}
    headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    local fns = {
        function() if syn and syn.request then local r = syn.request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if request then local r = request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if http_request then local r = http_request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if fluxus and fluxus.request then local r = fluxus.request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() return game:HttpGet(url, true), 200 end,
    }
    for _, fn in ipairs(fns) do
        local ok, body, status = pcall(fn)
        if ok and body and type(body) == "string" and #body > 0 then return body, status or 200 end
    end
    return nil, nil
end
-- ============================================
-- BUFFER UTILITY (from W)
-- ============================================
local function Buffer(str, allowOverflows)
    local Stream = {
        Offset = 0, Source = str,
        Length = #str,
        AllowOverflows = (allowOverflows == nil and true) or allowOverflows
    }
    function Stream:read(len, shift)
        len = len or 1; shift = (shift == nil and true) or shift
        local dat = string.sub(self.Source, self.Offset+1, self.Offset+len)
        if shift then self:seek(len) end
        return dat
    end
    function Stream:seek(len) self.Offset = math.clamp(self.Offset+len, 0, self.Length) end
    function Stream:readNumber(fmt, shift)
        fmt = fmt or "I1"
        local chunk = self:read(string.packsize(fmt), shift)
        return string.unpack(fmt, chunk)
    end
    function Stream:append(s) self.Source = self.Source..s; self.Length = #self.Source end
    function Stream:toEnd() self.Offset = self.Length end
    return Stream
end
local function transformInt(x) return (x%2==0) and (x/2) or (-(x+1)/2) end
local function rbxF32(x) x = bit32.rrotate(x,1); return string.unpack(">f", string.pack(">I4",x)) end
local basicTypes = {}
function basicTypes.String(buf) return buf:read(buf:readNumber("<I4")) end
function basicTypes.Int32(buf) return transformInt(buf:readNumber(">I4")) end
function basicTypes.Int64(buf) return transformInt(buf:readNumber(">I8")) end
function basicTypes.Float32(buf) return rbxF32(buf:readNumber(">I4")) end
function basicTypes.Float64(buf) return buf:readNumber("<d") end
function basicTypes.InterleaveArrayWithSize(buf, count, sizeof)
    if count < 0 then return Buffer("", false) end
    local stream = buf:read(count*sizeof); local out = table.create(count)
    for i = 1, count do
        local chunk = table.create(sizeof)
        for s = 0, sizeof-1 do
            local bitPos = i + (count*s); chunk[s+1] = string.sub(stream, bitPos, bitPos)
        end
        out[i] = table.concat(chunk)
    end
    return Buffer(table.concat(out), false)
end
function basicTypes.unsignedIntArray(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = strings:readNumber("<I4") end
    return o
end
function basicTypes.Int32Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = basicTypes.Int32(strings) end
    return o
end
function basicTypes.Int64Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 8)
    for i = 1, count do o[i] = basicTypes.Int64(strings) end
    return o
end
function basicTypes.RbxF32Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = basicTypes.Float32(strings) end
    return o
end
function basicTypes.RefArray(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local refs = basicTypes.Int32Array(buf, count); local last = 0
    for i = 1, count do local ref = last + refs[i]; o[i] = ref; last = ref end
    return o
end
-- ============================================
-- LZ4 DECOMPRESSOR (from W, full impl)
-- ============================================
local function lz4(lz4data)
    local inputStream = Buffer(lz4data)
    local compressedLen = string.unpack("<I4", inputStream:read(4))
    local decompressedLen= string.unpack("<I4", inputStream:read(4))
    local reserved = string.unpack("<I4", inputStream:read(4))
    if reserved ~= 0 then error("not lz4") end
    if compressedLen == 0 then return inputStream:read(decompressedLen) end
    local outputStream = Buffer("")
    repeat
        local token = string.byte(inputStream:read())
        local litLen = bit32.rshift(token, 4)
        local matLen = bit32.band(token, 15) + 4
        if litLen >= 15 then
            repeat
                local nextByte = string.byte(inputStream:read())
                litLen = litLen + nextByte
            until nextByte ~= 0xFF
        end
        local literal = inputStream:read(litLen)
        outputStream:append(literal); outputStream:toEnd()
        if outputStream.Length < decompressedLen then
            local offset = string.unpack("<I2", inputStream:read(2))
            if matLen >= 19 then
                repeat
                    local nextByte = string.byte(inputStream:read())
                    matLen = matLen + nextByte
                until nextByte ~= 0xFF
            end
            outputStream:seek(-offset)
            local pos = outputStream.Offset
            local match = outputStream:read(matLen)
            local unreadBytes = outputStream.LastUnreadBytes or 0
            local extra
            if unreadBytes then
                repeat
                    outputStream.Offset = pos
                    extra = outputStream:read(unreadBytes)
                    unreadBytes = outputStream.LastUnreadBytes or 0
                    match = match .. extra
                until unreadBytes <= 0
            end
            outputStream:append(match); outputStream:toEnd()
        end
    until outputStream.Length >= decompressedLen
    return outputStream.Source
end
WLoader.mark(2)
-- ============================================
-- ZSTD FALLBACK (from W)
-- ============================================
local function b64encode(str)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local out = {}
    for i = 1, #str, 3 do
        local b0, b1, b2 = string.byte(str, i, i+2)
        local b = bit32.lshift(b0, 16) + bit32.lshift(b1 or 0, 8) + (b2 or 0)
        table.insert(out, chars:sub(bit32.extract(b,18,6)+1, bit32.extract(b,18,6)+1))
        table.insert(out, chars:sub(bit32.extract(b,12,6)+1, bit32.extract(b,12,6)+1))
        table.insert(out, b1 and chars:sub(bit32.extract(b,6,6)+1, bit32.extract(b,6,6)+1) or "=")
        table.insert(out, b2 and chars:sub(bit32.band(b,63)+1, bit32.band(b,63)+1) or "=")
    end
    return table.concat(out)
end
local function zstd(stream)
    local zbase64 = b64encode(stream)
    local json = '{"m":null,"t":"buffer","zbase64":"' .. zbase64 .. '"}'
    local x = HttpService:JSONDecode(json)
    return buffer.tostring(x)
end
-- ============================================
-- RBXM BINARY PARSER — SOURCE EXTRACTOR
-- (from W: parseRBXMForSources)
-- ============================================
local function parseRBXMForSources(data)
    local sources = {}
    local rbxmBuf = Buffer(data, false)
    if rbxmBuf:read(8) ~= "<roblox!" or rbxmBuf:read(6) ~= string.char(137,255,13,10,26,10) then return sources, "Invalid header" end
    if rbxmBuf:read(2) ~= (string.char(0)..string.char(0)) then return sources, "Invalid version" end
    local classCount = rbxmBuf:readNumber("<i4")
    local instCount = rbxmBuf:readNumber("<i4")
    local classRefs, virtualInstances, strings, chunkInfo = {}, {}, {}, {}
    local _EC = "END"..string.char(0)
    local valid = {[_EC]=true,["INST"]=true,["META"]=true,["PRNT"]=true,["PROP"]=true,["SIGN"]=true,["SSTR"]=true}
    for k in pairs(valid) do chunkInfo[k] = {} end
    if rbxmBuf:read(8) ~= string.char(0,0,0,0,0,0,0,0) then return sources, "Invalid header2" end
    local index, last_chunk = 0, nil
    repeat
        index = index + 1
        local chunk = { InternalID = index, Header = rbxmBuf:read(4) }
        if not valid[chunk.Header] then return sources, "Invalid chunk: " .. tostring(chunk.Header) end
        local lz4Header = rbxmBuf:read(16, false)
        local compressed = string.unpack("<I4", string.sub(lz4Header, 1, 4))
        local decompressed = string.unpack("<I4", string.sub(lz4Header, 5, 8))
        local zstd_check = string.sub(lz4Header, 13, 16)
        local dataChunk
        if compressed == 0 then
            -- chunk tidak dikompres: lz4() sudah menangani header 12 byte (compressedLen == 0)
            dataChunk = lz4(rbxmBuf:read(decompressed + 12))
        else
            if zstd_check == string.char(40,181,47,253) then
                rbxmBuf:seek(12); dataChunk = zstd(rbxmBuf:read(compressed))
            else
                dataChunk = lz4(rbxmBuf:read(compressed + 12))
            end
        end
        chunk.Data = Buffer(dataChunk, false)
        table.insert(chunkInfo[chunk.Header], chunk)
        last_chunk = chunk
    until last_chunk and last_chunk.Header == _EC
    for _, chunk in ipairs(chunkInfo["SSTR"] or {}) do
        local buf = chunk.Data
        if buf:readNumber("<I4") == 0 then
            for i = 1, buf:readNumber("<I4") do buf:read(16); strings[i] = basicTypes.String(buf) end
        end
    end
    for _, chunk in ipairs(chunkInfo["INST"] or {}) do
        local buf = chunk.Data
        local classID = buf:readNumber("<I4")
        local className = basicTypes.String(buf)
        buf:read() -- flag service (RBXL berisi service, tetap lanjut parse)
        local count = buf:readNumber("<I4")
        local refs = basicTypes.RefArray(buf, count)
        classRefs[classID] = { Name = className, Sizeof = count, Refs = refs }
        for _, ref in ipairs(refs) do
            virtualInstances[ref] = { ClassId = classID, ClassName = className, Ref = ref, Properties = {}, Children = {} }
        end
    end
    for _, chunk in ipairs(chunkInfo["PROP"] or {}) do
        local buf = chunk.Data
        local classID = buf:readNumber("<I4")
        local classref = classRefs[classID]
        if not classref then return sources, "Missing classref" end
        local refs = classref.Refs
        local sizeof = classref.Sizeof
        local name = basicTypes.String(buf)
        if string.byte(buf:read(1, false)) == 0x1E then buf:seek(1) end
        local typeID = string.byte(buf:read())
        local props = {}
        if typeID == 0x01 or typeID == 0x1D then
            for i = 1, sizeof do props[i] = basicTypes.String(buf) end
        elseif typeID == 0x02 then
            for i = 1, sizeof do props[i] = buf:read() ~= string.char(0) end
        elseif typeID == 0x03 then props = basicTypes.Int32Array(buf, sizeof)
        elseif typeID == 0x04 then props = basicTypes.RbxF32Array(buf, sizeof)
        elseif typeID == 0x05 then
            for i = 1, sizeof do props[i] = basicTypes.Float64(buf) end
        else
            for i = 1, sizeof do
                if typeID == 0x13 then props = basicTypes.RefArray(buf, sizeof); break else buf:read(4) end
            end
        end
        if name == "Source" or name == "ContentText" or name == "Name" then
            for i, v in ipairs(refs) do
                if virtualInstances[v] and props[i] then virtualInstances[v].Properties[name] = props[i] end
            end
        end
    end
    local function buildSourceMap(node, path)
        local src = node.Properties["Source"] or node.Properties["ContentText"]
        if src and type(src) == "string" and #src > 0 then sources[path] = src end
        for _, child in ipairs(node.Children or {}) do
            buildSourceMap(child, path .. "." .. child.ClassName .. ":" .. (child.Properties["Name"] or "unnamed"))
        end
    end
    for _, chunk in ipairs(chunkInfo["PRNT"] or {}) do
        local buf = chunk.Data
        if buf:read() ~= string.char(0) then return sources, "Invalid PRNT" end
        local count = buf:readNumber("<I4")
        local child_refs = basicTypes.RefArray(buf, count)
        local parent_refs = basicTypes.RefArray(buf, count)
        for i = 1, count do
            local child = virtualInstances[child_refs[i]]
            local parent = virtualInstances[parent_refs[i]]
            if child and parent then
                table.insert(parent.Children, child)
                child.HasParent = true
            end
        end
    end
    local roots = {}
    for _, inst in pairs(virtualInstances) do
        if not inst.HasParent then table.insert(roots, inst) end
    end
    for _, root in ipairs(roots) do
        buildSourceMap(root, root.ClassName .. ":" .. (root.Properties["Name"] or "root"))
    end
    return sources, nil
end
-- ============================================
-- XML PARSER (RBXMX / RBXLX) — SOURCE EXTRACTOR
-- Format path sama dengan parser biner: "Class:Name.Class:Name..."
-- ============================================
local function xmlUnescape(text)
    if not string.find(text, "&", 1, true) then return text end
    text = string.gsub(text, "&#[xX](%x+);", function(h)
        local ok, ch = pcall(utf8.char, tonumber(h, 16))
        return ok and ch or ""
    end)
    text = string.gsub(text, "&#(%d+);", function(d)
        local ok, ch = pcall(utf8.char, tonumber(d))
        return ok and ch or ""
    end)
    text = string.gsub(text, "&lt;", "<")
    text = string.gsub(text, "&gt;", ">")
    text = string.gsub(text, "&quot;", '"')
    text = string.gsub(text, "&apos;", "'")
    text = string.gsub(text, "&amp;", "&")
    return text
end
-- Baca isi elemen (teks biasa + CDATA) mulai setelah tag pembuka; return teks & posisi setelah tag penutup
local function readXmlText(data, pos)
    local parts = {}
    local i = pos
    while true do
        local nextLt = string.find(data, "<", i, true)
        if not nextLt then
            if i <= #data then parts[#parts + 1] = xmlUnescape(string.sub(data, i)) end
            return table.concat(parts), #data + 1
        end
        if nextLt > i then parts[#parts + 1] = xmlUnescape(string.sub(data, i, nextLt - 1)) end
        if string.sub(data, nextLt, nextLt + 8) == "<![CDATA[" then
            local e = string.find(data, "]]>", nextLt + 9, true)
            if not e then
                parts[#parts + 1] = string.sub(data, nextLt + 9)
                return table.concat(parts), #data + 1
            end
            parts[#parts + 1] = string.sub(data, nextLt + 9, e - 1)
            i = e + 3
        else
            local gt = string.find(data, ">", nextLt, true)
            return table.concat(parts), (gt or #data) + 1
        end
    end
end
local function parseXMLForSources(data)
    local sources = {}
    local stack, depth = {}, 0
    local pos, tokens = 1, 0
    local function ensurePath(i)
        local e = stack[i]
        if e.path then return e.path end
        local nm = e.name or (i == 1 and "root" or "unnamed")
        if i == 1 then
            e.path = e.class .. ":" .. nm
        else
            e.path = ensurePath(i - 1) .. "." .. e.class .. ":" .. nm
        end
        return e.path
    end
    while true do
        local lt = string.find(data, "<", pos, true)
        if not lt then break end
        tokens = tokens + 1
        if tokens % 20000 == 0 then task.wait() end -- beri napas ke game saat file besar
        local c = string.sub(data, lt + 1, lt + 1)
        if c == "/" then
            local gt = string.find(data, ">", lt, true)
            if not gt then break end
            local closeName = string.gsub(string.sub(data, lt + 2, gt - 1), "%s+", "")
            if closeName == "Item" and depth > 0 then
                local e = stack[depth]
                local src = e.source or e.contentText
                if src and #src > 0 then sources[ensurePath(depth)] = src end
                stack[depth] = nil
                depth = depth - 1
            end
            pos = gt + 1
        elseif c == "!" then
            if string.sub(data, lt, lt + 8) == "<![CDATA[" then
                local e = string.find(data, "]]>", lt + 9, true)
                pos = e and (e + 3) or (#data + 1)
            elseif string.sub(data, lt, lt + 3) == "<!--" then
                local e = string.find(data, "-->", lt + 4, true)
                pos = e and (e + 3) or (#data + 1)
            else
                local gt = string.find(data, ">", lt, true)
                pos = gt and (gt + 1) or (#data + 1)
            end
        elseif c == "?" then
            local e = string.find(data, "?>", lt + 2, true)
            pos = e and (e + 2) or (#data + 1)
        else
            local gt = string.find(data, ">", lt, true)
            if not gt then break end
            local inner = string.sub(data, lt + 1, gt - 1)
            local selfClose = string.sub(inner, -1) == "/"
            local tag = string.match(inner, "^[%w_:%.%-]+")
            pos = gt + 1
            if tag == "Item" then
                if depth > 0 then ensurePath(depth) end
                depth = depth + 1
                stack[depth] = { class = string.match(inner, 'class="([^"]*)"') or "Instance" }
                if selfClose then
                    stack[depth] = nil
                    depth = depth - 1
                end
            elseif depth > 0 and (tag == "string" or tag == "ProtectedString") then
                local pname = string.match(inner, 'name="([^"]*)"')
                if pname == "Name" or pname == "Source" or pname == "ContentText" then
                    local text = ""
                    if not selfClose then text, pos = readXmlText(data, gt + 1) end
                    local e = stack[depth]
                    if pname == "Name" then e.name = text
                    elseif pname == "Source" then e.source = text
                    else e.contentText = text end
                end
            end
        end
    end
    return sources, nil
end
WLoader.mark(3)
-- ============================================
-- STUDIO LITE INTEGRATION (from W)
-- ============================================
local slFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs= slFolder and slFolder:FindFirstChild("ServerFunctions")
local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id then pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end) end
end
local SL_CACHE = {}
-- Path script (sama dengan format parser) dicatat sebelum objek dipindah ke game
local W_PATH_KEYS = setmetatable({}, {__mode = "k"})
local function recordScriptPaths(root)
    local function walk(inst, path)
        if inst:IsA("LuaSourceContainer") then W_PATH_KEYS[inst] = path end
        for _, child in ipairs(inst:GetChildren()) do
            walk(child, path .. "." .. child.ClassName .. ":" .. child.Name)
        end
    end
    walk(root, root.ClassName .. ":" .. root.Name)
end
local function injectStudioLiteUI(scr, sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path = W_PATH_KEYS[scr] or (scr.ClassName .. ":" .. scr.Name)
    local realSource = sourceMap and sourceMap[path]
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then
        realSource = realSource:gsub(string.char(0).."*$", "")
    else
        realSource = "-- [W] Source tidak ditemukan."
    end
    _G.W_RAW_SOURCES[scr] = realSource
    local UI_TEXT = realSource
    if #UI_TEXT > 150000 then
        UI_TEXT = "-- [W Warning] Source terlalu panjang.\n\n" .. string.sub(UI_TEXT, 1, 150000) .. "\n\n... [TERPOTONG]"
    end
    local existingTB = scr:FindFirstChild("SL_CodeTextBox")
    if existingTB then
        existingTB.Text = UI_TEXT
        if scr.ClassName == "ModuleScript" then
            local ro = scr:FindFirstChild("SL_1ReadOnly")
            if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
        end
        return
    end
    if not serverFuncs then return end
    local map = { Script = "InsertScriptScript", LocalScript = "InsertLocalScriptLocalScript", ModuleScript = "InsertModuleScriptModuleScript" }
    local assetName= map[scr.ClassName]
    if not assetName then return end
    if not SL_CACHE[assetName] then
        pcall(function()
            serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            local guiF = PlayerGui:WaitForChild(assetName, 3)
            if guiF then
                SL_CACHE[assetName] = {}
                for _, c in ipairs(guiF:GetChildren()) do table.insert(SL_CACHE[assetName], c:Clone()) end
                serverFuncs:InvokeServer("ClearAssetFromPlayerGui", assetName)
            end
        end)
    end
    if not SL_CACHE[assetName] then return end
    pcall(function()
        for _, c in ipairs(SL_CACHE[assetName]) do c:Clone().Parent = scr end
        local tb = scr:FindFirstChild("SL_CodeTextBox")
        if tb then
            tb.Text = UI_TEXT
            if scr.ClassName == "ModuleScript" then
                local ro = scr:FindFirstChild("SL_1ReadOnly")
                if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
            end
        end
    end)
end
local function injectAllScripts(root, sourceMap)
    if not root then return 0 end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then table.insert(list, d) end
    end
    local count = 0
    for _, s in ipairs(list) do
        pcall(injectStudioLiteUI, s, sourceMap); count = count + 1; task.wait(0.02)
    end
    return count
end
-- ============================================
-- ★★★ MODIFIKASI: STABIL TAPI BISA DIGESER ★★★
-- ============================================
local function ApplyStudioLiteProperties(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            if obj:GetAttribute("SL_Anchored") == nil then
                obj:SetAttribute("SL_Anchored", obj.Anchored)
            end
            if obj:GetAttribute("SL_CanCollide") == nil then
                obj:SetAttribute("SL_CanCollide", obj.CanCollide)
            end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do ApplyStudioLiteProperties(child) end
end
local function LoadAssetsToSLServer(obj)
    local function scan(node)
        pcall(function()
            if node:IsA("MeshPart") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
            elseif node:IsA("Decal") or node:IsA("Texture") then triggerServerLoad(node.Texture)
            elseif node:IsA("SpecialMesh") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
            elseif node:IsA("Clothing") or node:IsA("ShirtGraphic") then
                triggerServerLoad(node.ClassName == "ShirtGraphic" and node.Graphic or node[node.ClassName.."Template"])
            elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then triggerServerLoad(node.AssetId) end
        end)
        for _, child in ipairs(node:GetChildren()) do scan(child) end
    end
    scan(obj)
end
local SVC_MAP = {
    Workspace = workspace,
    ReplicatedStorage = ReplicatedStorage,
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    StarterGui = game:GetService("StarterGui"),
    StarterPack = game:GetService("StarterPack"),
    StarterPlayer = game:GetService("StarterPlayer"),
    Lighting = game:GetService("Lighting"),
    SoundService = game:GetService("SoundService"),
    ServerScriptService = _G.sss or ReplicatedStorage,
    ServerStorage = _G.ss or ReplicatedStorage,
    Teams = ReplicatedStorage,
    Chat = ReplicatedStorage,
}
-- Bagian RBXL yang tidak diimpor (sudah ada di game & tidak bisa diduplikasi)
local RBXL_SKIP = { Terrain = true, Camera = true }
local function isRealService(inst)
    local ok, svc = pcall(function() return game:FindService(inst.ClassName) end)
    return ok and svc ~= nil
end
local function insertObjects(objects, isRbxl, sourceMap)
    local count = 0
    for _, obj in ipairs(objects) do
        pcall(recordScriptPaths, obj)
        pcall(function()
            local target = isRbxl and (SVC_MAP[obj.ClassName] or SVC_MAP[obj.Name]) or nil
            if isRbxl and not target and isRealService(obj) then
                -- Service lain di RBXL (Players, TextChatService, dll) -> folder di ReplicatedStorage
                local holder = Instance.new("Folder")
                holder.Name = "W_" .. obj.ClassName
                holder.Parent = ReplicatedStorage
                target = holder
            end
            if isRbxl and target then
                for _, ch in ipairs(obj:GetChildren()) do
                    if not (target == workspace and RBXL_SKIP[ch.ClassName]) then
                        pcall(function()
                            ch.Parent = target
                            injectAllScripts(ch, sourceMap)
                            ApplyStudioLiteProperties(ch)
                            LoadAssetsToSLServer(ch)
                            count = count + 1
                        end)
                        task.wait(0.01)
                    end
                end
            else
                obj.Parent = workspace
                injectAllScripts(obj, sourceMap)
                ApplyStudioLiteProperties(obj)
                LoadAssetsToSLServer(obj)
                count = count + 1
            end
        end)
    end
    return count
end
-- ============================================
-- SAFE ANCHOR SYSTEM (MODIFIED)
-- Mencegah roboh saat spawn, tapi memungkinkan interaksi
-- ============================================
local function IsPlayerCharacter(inst)
    local char = LocalPlayer.Character
    return char and inst:IsDescendantOf(char)
end
local function SafeAnchor(part)
    if not part:IsA("BasePart") or IsPlayerCharacter(part) then return end
    pcall(function()
        for _, child in ipairs(part:GetDescendants()) do
            if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("BodyMover") then
                child:Destroy()
            end
        end
        part.Anchored = true
        part.CanCollide = true
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("BasePart") then
        task.spawn(function()
            task.wait()
            SafeAnchor(desc)
        end)
    end
end)
-- ============================================
-- FILE SCANNER (W SCAN_PATHS)
-- ============================================
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "../workspace",
    ".",
    "",
    "models",
    "rbxm",
    "rbxl",
    "downloads",
    "fluxus",
    "KRNL Scripts",
    "Electron",
    "Hydrogen",
}
local function safeReadFile(p)
    if not readfile then return nil end
    local ok, d = pcall(readfile, p)
    return ok and d or nil
end
local function safeListFiles(p)
    if not listfiles then return nil end
    local ok, f = pcall(listfiles, p)
    return ok and f or nil
end
local function getFileName(p) return p:match("([^/]+)$") or p end
local function getFileType(n)
    n = n:lower()
    if n:match("%.rbxl$") or n:match("%.rbxlx$") then return "RBXL"
    elseif n:match("%.rbxm$") or n:match("%.rbxmx$") then return "RBXM" end
    return nil
end
local function looksFolder(p) return not getFileName(p):match("%.[%a%d]+") end
local function scanDeep(folder, depth, results, seen)
    if depth > 4 or seen[folder] then return end
    seen[folder] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = getFileName(path)
        local ftype = getFileType(name)
        if ftype and not seen[path] then
            seen[path] = true
            local content = safeReadFile(path)
            if content and #content > 0 then
                local ext = name:lower():match("%.([^%.]+)$") or "rbxm"
                table.insert(results, {
                    name = name,
                    path = path,
                    ftype = ftype,
                    folder = folder,
                    ext = ext,
                    icon = "📦",
                    sizeFormatted = (#content < 1024 and #content.." B") or
                                   (#content < 1048576 and string.format("%.1f KB", #content/1024)) or
                                   string.format("%.1f MB", #content/1048576),
                })
            end
        elseif looksFolder(path) then
            scanDeep(path, depth+1, results, seen)
        end
    end
end
local function scanAll()
    local results, seen = {}, {}
    for _, p in ipairs(SCAN_PATHS) do
        if safeListFiles(p) then scanDeep(p, 0, results, seen) end
    end
    return results
end
-- ============================================
-- LOAD FILE — FULL FALLBACK CHAIN (W logic)
-- ============================================
local MAX_PARSE_BYTES = 25 * 1024 * 1024       -- file biner (rbxm / rbxl)
local MAX_XML_PARSE_BYTES = 30 * 1024 * 1024   -- file XML (rbxmx / rbxlx)
local function tryGetObjects(assetUrl)
    local ok, objs = pcall(function() return game:GetObjects(assetUrl) end)
    if ok and objs and #objs > 0 then return objs end
    -- Fallback terakhir (dipakai kalau GetObjects gagal membaca file)
    local ok2, inst = pcall(function() return InsertService:LoadLocalAsset(assetUrl) end)
    if ok2 and typeof(inst) == "Instance" then return { inst } end
    return nil
end
local function describeRoots(objs)
    local parts = {}
    for i, o in ipairs(objs) do
        if i > 6 then parts[#parts + 1] = "..."; break end
        local okd, txt = pcall(function() return o.ClassName .. ":" .. o.Name .. "(" .. #o:GetChildren() .. ")" end)
        parts[#parts + 1] = okd and txt or "?"
    end
    return table.concat(parts, ", ")
end
local function finishImport(objs, isRbxl, sourceMap)
    local desc = describeRoots(objs)
    local n = insertObjects(objs, isRbxl, sourceMap)
    if n == 0 then
        warn("[W RBXM] 0 objek masuk. Isi file: " .. desc)
        return false, "0 objek masuk (cek Output)"
    end
    return true, n .. " object(s) loaded"
end
local function loadFile(fileInfo)
    local isRbxl = fileInfo.ftype == "RBXL"
    local data = safeReadFile(fileInfo.path)
    if not data or #data == 0 then return false, "readfile gagal: " .. tostring(fileInfo.path) end
    local sourceMap = {}
    -- Ambil source script: biner (RBXM / RBXL) atau XML (RBXMX / RBXLX). File terlalu besar dilewati.
    if string.sub(data, 1, 8) == "<roblox!" then
        if #data <= MAX_PARSE_BYTES then
            local ok, sources = pcall(parseRBXMForSources, data)
            if ok and sources then sourceMap = sources end
        end
    elseif string.find(string.sub(data, 1, 512), "<roblox", 1, true) then
        if #data <= MAX_XML_PARSE_BYTES then
            local ok, sources = pcall(parseXMLForSources, data)
            if ok and sources then sourceMap = sources end
        end
    end
    if getcustomasset then
        local ok1, aid = pcall(getcustomasset, fileInfo.path)
        if ok1 and aid and aid ~= "" then
            local objs = tryGetObjects(aid)
            if objs then return finishImport(objs, isRbxl, sourceMap) end
        end
    end
    local o3 = tryGetObjects("rbxasset://" .. fileInfo.path)
    if o3 then return finishImport(o3, isRbxl, sourceMap) end
    if getcustomasset and writefile then
        local tempName = "w_temp_" .. tostring(tick()):gsub("%.", "") .. "." .. tostring(fileInfo.ext or "rbxm")
        local tempPaths = {
            "workspace/" .. tempName,
            "Delta/workspace/" .. tempName,
            tempName,
        }
        for _, tp in ipairs(tempPaths) do
            local wOk = pcall(writefile, tp, data)
            if wOk then
                local ok4, aid2 = pcall(getcustomasset, tp)
                if ok4 and aid2 and aid2 ~= "" then
                    local objs2 = tryGetObjects(aid2)
                    pcall(delfile or function() end, tp)
                    if objs2 then return finishImport(objs2, isRbxl, sourceMap) end
                else
                    pcall(delfile or function() end, tp)
                end
            end
        end
    end
    return false, "Semua metode load gagal untuk: " .. tostring(fileInfo.path)
end
WLoader.mark(4)
-- ============================================
-- HOOKS — Anti-Putus Studio Lite (from W)
-- ============================================
task.spawn(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not checkcaller() and method == "InvokeServer" then
                if self.Name == "GetScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    for obj, src in pairs(_G.W_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            if src and src ~= "" then return src end
                        end
                    end
                    for _, place in ipairs({
                        workspace, ReplicatedStorage, _G.sss, _G.ss,
                        game:GetService("StarterGui"), game:GetService("StarterPlayer"),
                        LocalPlayer:FindFirstChild("PlayerGui"), LocalPlayer:FindFirstChild("Backpack")
                    }) do
                        if place then
                            for _, obj in ipairs(place:GetDescendants()) do
                                if obj:IsA("LuaSourceContainer") and (obj.ClassName .. obj.Name) == target then
                                    local src = _G.W_RAW_SOURCES[obj]
                                    if src and src ~= "" then return src end
                                end
                            end
                        end
                    end
                end
                if self.Name == "SaveScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    local newSource = tostring(args[2])
                    for obj, _ in pairs(_G.W_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            _G.W_RAW_SOURCES[obj] = newSource; break
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end
    if hookfunction then
        local oldRequire
        oldRequire = hookfunction(getrenv().require or require, function(module)
            if typeof(module) == "Instance" and module:IsA("ModuleScript") then
                local src = _G.W_RAW_SOURCES[module]
                if src and src ~= "" then
                    local func, err = loadstring(src)
                    if func then
                        local success, result = pcall(func)
                        if success then return result end
                    end
                end
            end
            return oldRequire(module)
        end)
        local oldGetObjects
        oldGetObjects = hookfunction(game.GetObjects, function(self, url, ...)
            local assetId = tostring(url):match("%d+")
            if assetId then triggerServerLoad(assetId) end
            local objects = oldGetObjects(self, url, ...)
            if objects then
                for _, obj in ipairs(objects) do
                    pcall(function() injectAllScripts(obj, {}) end)
                    pcall(function() ApplyStudioLiteProperties(obj) end)
                    pcall(function() LoadAssetsToSLServer(obj) end)
                end
            end
            return objects
        end)
        local oldLoadAsset
        oldLoadAsset = hookfunction(InsertService.LoadAsset, function(self, assetId, ...)
            triggerServerLoad(tostring(assetId))
            local obj = oldLoadAsset(self, assetId, ...)
            if obj then
                pcall(function() injectAllScripts(obj, {}) end)
                pcall(function() ApplyStudioLiteProperties(obj) end)
                pcall(function() LoadAssetsToSLServer(obj) end)
            end
            return obj
        end)
    end
end)
-- ============================================
-- UI BUILDER — W (WOFY) PREMIUM BLACK · PANEL 16:9
-- ============================================
local ASPECT_W, ASPECT_H = 16, 9
local PANEL_MIN_W = 240
local PANEL_MAX_W = 460

local function make(className, props, parentObj)
    local obj = Instance.new(className)
    if obj:IsA("GuiObject") then obj.BorderSizePixel = 0 end
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parentObj then obj.Parent = parentObj end
    return obj
end
local function addCorner(parentObj, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius)}, parentObj)
end
local function addStroke(parentObj, color, thickness)
    return make("UIStroke", {
        Color = color or PALETTE.InnerBorder,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parentObj)
end
local function addLabel(parentObj, text, size, pos, textSize, color, font, align)
    return make("TextLabel", {
        Text = text,
        Size = size,
        Position = pos or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = color or PALETTE.TextWhite,
        Font = font or Enum.Font.GothamBold,
        TextSize = textSize or 10,
        TextXAlignment = align or Enum.TextXAlignment.Left,
    }, parentObj)
end
local function addButton(parentObj, text, size, pos, primary, textSize)
    local btn = make("TextButton", {
        Text = text,
        Size = size,
        Position = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = primary and PALETTE.White or PALETTE.Surface,
        TextColor3 = primary and PALETTE.TextDark or PALETTE.TextWhite,
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 10,
    }, parentObj)
    addCorner(btn, 5)
    if not primary then addStroke(btn, PALETTE.InnerBorder, 1) end
    return btn
end
local function addLogo(parentObj, size, pos, textSize)
    local badge = make("TextLabel", {
        Text = "W",
        Size = size,
        Position = pos,
        BackgroundColor3 = PALETTE.White,
        TextColor3 = PALETTE.TextDark,
        Font = Enum.Font.GothamBlack,
        TextSize = textSize,
    }, parentObj)
    addCorner(badge, 6)
    return badge
end
local function addDivider(parentObj, y)
    return make("Frame", {
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, y),
        BackgroundColor3 = PALETTE.InnerBorder,
    }, parentObj)
end

-- Ukuran panel 16:9 otomatis menyesuaikan layar HP
local function heightFromWidth(w)
    return math.floor(w * ASPECT_H / ASPECT_W + 0.5)
end
local function getDefaultPanelWidth()
    local camera = Workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(800, 360)
    if vp.X < 200 or vp.Y < 100 then vp = Vector2.new(800, 360) end
    local w = math.min(vp.X * 0.62, vp.Y * 0.86 * ASPECT_W / ASPECT_H, 340)
    return math.clamp(math.floor(w), PANEL_MIN_W, PANEL_MAX_W)
end
local DEFAULT_W = getDefaultPanelWidth()
local DEFAULT_H = heightFromWidth(DEFAULT_W)

-- 0. TOMBOL GUI "W"
local toggleBtn = make("TextButton", {
    Name = "WToggleBtn",
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(0, 15, 0.45, 0),
    BackgroundColor3 = PALETTE.Background,
    Text = "W",
    TextColor3 = PALETTE.TextWhite,
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
    Active = true,
    Draggable = true,
    Visible = false,
}, screenGui)
addCorner(toggleBtn, 9)
applyWhiteStroke(toggleBtn, 1.5)
UIState.toggleButton = toggleBtn

-- ============================================
-- LOGIN FRAME (KEY) — 16:9
-- ============================================
local loginFrame = make("Frame", {
    Name = "LoginFrame",
    Size = UDim2.new(0, 272, 0, 153),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = PALETTE.Background,
    Active = true,
    Draggable = true,
    Visible = false,
}, screenGui)
addCorner(loginFrame, 10)
applyWhiteStroke(loginFrame, 1.5)
addLogo(loginFrame, UDim2.new(0, 26, 0, 26), UDim2.new(0, 12, 0, 10), 15)
addLabel(loginFrame, "W IMPORTER", UDim2.new(1, -60, 0, 14), UDim2.new(0, 46, 0, 10), 12)
addLabel(loginFrame, "Masukkan key untuk membuka panel", UDim2.new(1, -60, 0, 10), UDim2.new(0, 46, 0, 26), 8, PALETTE.TextMuted, Enum.Font.Gotham)
local pinBox = make("TextBox", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 0, 50),
    BackgroundColor3 = PALETTE.InputBg,
    TextColor3 = PALETTE.TextWhite,
    PlaceholderColor3 = PALETTE.TextMuted,
    PlaceholderText = "Masukkan Key...",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    Text = "",
    ClearTextOnFocus = false,
}, loginFrame)
addCorner(pinBox, 6)
addStroke(pinBox, PALETTE.InnerBorder, 1)
local loginStatus = addLabel(loginFrame, "", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, 81), 8, PALETTE.AccentRed, Enum.Font.Gotham, Enum.TextXAlignment.Center)
loginStatus.TextWrapped = true
local submitBtn = addButton(loginFrame, "UNLOCK PANEL", UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, 104), true, 10)
addLabel(loginFrame, "WA: " .. WA_NUMBER, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 134), 8, PALETTE.TextMuted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
UIState.loginFrame = loginFrame
-- Login baru muncul setelah loading screen membuka tirai
WLoader.onFinished(function()
    if loginFrame and loginFrame.Parent then loginFrame.Visible = true end
end)

-- ============================================
-- 1. PANEL UTAMA (16:9)
-- ============================================
local mainFrame = make("Frame", {
    Name = "MainImporterFrame",
    Size = UDim2.new(0, DEFAULT_W, 0, DEFAULT_H),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = PALETTE.Background,
    Active = true,
    Draggable = true,
    ClipsDescendants = true,
    Visible = false,
}, screenGui)
addCorner(mainFrame, 10)
applyWhiteStroke(mainFrame, 1.5)
UIState.mainFrame = mainFrame

-- Header
local topBarFrame = make("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1}, mainFrame)
addLogo(topBarFrame, UDim2.new(0, 20, 0, 20), UDim2.new(0, 8, 0, 4), 12)
addLabel(topBarFrame, "W IMPORTER", UDim2.new(1, -70, 1, 0), UDim2.new(0, 34, 0, 0), 11)
local closeMainBtn = addButton(topBarFrame, "X", UDim2.new(0, 20, 0, 20), UDim2.new(1, -28, 0, 4), false, 10)
addDivider(mainFrame, 28)
closeMainBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    UIState.panelVisible = false
end)
toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    UIState.panelVisible = mainFrame.Visible
end)

-- Sidebar kiri (tombol navigasi)
local sidebar = make("Frame", {
    Size = UDim2.new(0.27, -10, 1, -62),
    Position = UDim2.new(0, 8, 0, 34),
    BackgroundTransparency = 1,
}, mainFrame)
make("UIListLayout", {Padding = UDim.new(0.05, 0), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local refreshBtn = addButton(sidebar, "SCAN", UDim2.new(1, 0, 0.3, 0), nil, true, 10)
refreshBtn.LayoutOrder = 1
local openSizeBtn = addButton(sidebar, "UKURAN", UDim2.new(1, 0, 0.3, 0), nil, false, 9)
openSizeBtn.LayoutOrder = 2
local openMusicBtn = addButton(sidebar, "MUSIK", UDim2.new(1, 0, 0.3, 0), nil, false, 9)
openMusicBtn.LayoutOrder = 3

-- Area kanan (search + list file)
local listArea = make("Frame", {
    Size = UDim2.new(0.73, -10, 1, -62),
    Position = UDim2.new(0.27, 2, 0, 34),
    BackgroundTransparency = 1,
}, mainFrame)
local searchBox = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = PALETTE.InputBg,
    PlaceholderText = "Cari file...",
    Text = "",
    TextColor3 = PALETTE.TextWhite,
    PlaceholderColor3 = PALETTE.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
}, listArea)
addCorner(searchBox, 5)
addStroke(searchBox, PALETTE.InnerBorder, 1)
make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, searchBox)
UIState.searchBox = searchBox

local scrollList = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -27),
    Position = UDim2.new(0, 0, 0, 27),
    BackgroundColor3 = PALETTE.CardBg,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = PALETTE.White,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, listArea)
addCorner(scrollList, 6)
addStroke(scrollList, PALETTE.InnerBorder, 1)
make("UIPadding", {
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
    PaddingLeft = UDim.new(0, 3),
    PaddingRight = UDim.new(0, 5),
}, scrollList)
local listLayout = make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, scrollList)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end)
UIState.scrollFrame = scrollList

local emptyLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 1, -27),
    Position = UDim2.new(0, 0, 0, 27),
    BackgroundTransparency = 1,
    Text = "Belum ada file RBXM / RBXL / XML\nTekan SCAN untuk mencari.",
    TextColor3 = PALETTE.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextWrapped = true,
    ZIndex = 2,
}, listArea)
UIState.emptyLabel = emptyLabel

-- Footer: status + running text
local statusLabel = addLabel(mainFrame, "Ready", UDim2.new(0.34, 0, 0, 16), UDim2.new(0, 10, 1, -22), 9, PALETTE.TextWhite)
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
UIState.statusLabel = statusLabel

local marqueeContainer = make("Frame", {
    Size = UDim2.new(0.66, -14, 0, 16),
    Position = UDim2.new(0.34, 4, 1, -22),
    BackgroundColor3 = PALETTE.CardBg,
    ClipsDescendants = true,
}, mainFrame)
addCorner(marqueeContainer, 4)
addStroke(marqueeContainer, PALETTE.InnerBorder, 1)
local marqueeText = make("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "★ BY WOFY ★ IMPORT RBXM ★ ",
    TextColor3 = PALETTE.TextWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = false,
}, marqueeContainer)
local marqueeX = 40
local marqueeSpeed = 35
RunService.RenderStepped:Connect(function(dt)
    if not mainFrame.Visible then return end
    local containerW = marqueeContainer.AbsoluteSize.X
    local textW = marqueeText.AbsoluteSize.X
    marqueeX = marqueeX - marqueeSpeed * dt
    if marqueeX < -textW then marqueeX = containerW end
    marqueeText.Position = UDim2.new(0, marqueeX, 0, 0)
end)

-- ============================================
-- 2. MUSIC PANEL (16:9, ukuran sama dengan panel utama)
-- ============================================
local musicFrame = make("Frame", {
    Name = "MusicPlayerSeparate",
    Size = UDim2.new(0, DEFAULT_W, 0, DEFAULT_H),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 18, 0.5, 18),
    BackgroundColor3 = PALETTE.Background,
    Active = true,
    Draggable = true,
    ClipsDescendants = true,
    Visible = false,
}, screenGui)
addCorner(musicFrame, 10)
applyWhiteStroke(musicFrame, 1.5)
UIState.musicFrame = musicFrame

local musicTopBar = make("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1}, musicFrame)
addLabel(musicTopBar, "MUSIK & JADWAL SOLAT", UDim2.new(1, -44, 1, 0), UDim2.new(0, 10, 0, 0), 10)
local closeMusicBtn = addButton(musicTopBar, "X", UDim2.new(0, 20, 0, 20), UDim2.new(1, -28, 0, 4), false, 10)
addDivider(musicFrame, 28)
openMusicBtn.MouseButton1Click:Connect(function()
    musicFrame.Visible = not musicFrame.Visible
end)
closeMusicBtn.MouseButton1Click:Connect(function()
    musicFrame.Visible = false
end)

-- Kartu jam & jadwal solat (kiri)
local infoCard = make("Frame", {
    Size = UDim2.new(0.38, -10, 1, -42),
    Position = UDim2.new(0, 8, 0, 34),
    BackgroundColor3 = PALETTE.CardBg,
}, musicFrame)
addCorner(infoCard, 6)
addStroke(infoCard, PALETTE.InnerBorder, 1)
local clockTimeLabel = addLabel(infoCard, "00:00:00", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 4), 14, PALETTE.TextWhite, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
addLabel(infoCard, "WIB", UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 24), 8, PALETTE.TextMuted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
addDivider(infoCard, 38)
local solatTimesLabel = addLabel(infoCard, "Subuh 04:30\nDzuhur 12:00\nAshar 15:15\nMaghrib 18:00\nIsya 19:15", UDim2.new(1, -8, 1, -44), UDim2.new(0, 4, 0, 42), 8, Color3.fromRGB(190, 190, 190), Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
solatTimesLabel.TextYAlignment = Enum.TextYAlignment.Top
task.spawn(function()
    while task.wait(1) do
        local date = os.date("!*t", os.time() + 7 * 3600)
        clockTimeLabel.Text = string.format("%02d:%02d:%02d", date.hour, date.min, date.sec)
    end
end)

-- Music Player
local currentSound = Instance.new("Sound")
currentSound.Name = "CustomMusicPlayer"
currentSound.Volume = 2
currentSound.Looped = true
currentSound.Parent = SoundService

local musicListScroll = make("ScrollingFrame", {
    Size = UDim2.new(0.62, -10, 1, -72),
    Position = UDim2.new(0.38, 2, 0, 34),
    BackgroundColor3 = PALETTE.CardBg,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = PALETTE.White,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, musicFrame)
addCorner(musicListScroll, 6)
addStroke(musicListScroll, PALETTE.InnerBorder, 1)
make("UIPadding", {
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
    PaddingLeft = UDim.new(0, 3),
    PaddingRight = UDim.new(0, 5),
}, musicListScroll)
local musicLayout = make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, musicListScroll)
musicLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    musicListScroll.CanvasSize = UDim2.new(0, 0, 0, musicLayout.AbsoluteContentSize.Y + 6)
end)

local songs = {
    {Name = "Black Hole", Id = "rbxassetid://118362297271903"}
}
local currentPlayingBtn = nil
local function setPlayState(btn, playing)
    if playing then
        btn.Text = "STOP"
        btn.BackgroundColor3 = PALETTE.Surface
        btn.TextColor3 = PALETTE.TextWhite
    else
        btn.Text = "PLAY"
        btn.BackgroundColor3 = PALETTE.White
        btn.TextColor3 = PALETTE.TextDark
    end
end
for index, songData in ipairs(songs) do
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = PALETTE.Surface,
        LayoutOrder = index,
    }, musicListScroll)
    addCorner(card, 5)
    addStroke(card, PALETTE.InnerBorder, 1)
    local nameLab = addLabel(card, songData.Name, UDim2.new(0.55, -6, 1, 0), UDim2.new(0, 8, 0, 0), 9, PALETTE.TextWhite, Enum.Font.GothamBold)
    nameLab.TextTruncate = Enum.TextTruncate.AtEnd
    local playBtn = addButton(card, "PLAY", UDim2.new(0.4, 0, 0, 20), UDim2.new(0.58, 0, 0.5, -10), true, 9)
    addStroke(playBtn, PALETTE.White, 1)
    playBtn.MouseButton1Click:Connect(function()
        if currentSound.SoundId == songData.Id and currentSound.IsPlaying then
            currentSound:Stop()
            setPlayState(playBtn, false)
            currentPlayingBtn = nil
        else
            if currentPlayingBtn then
                setPlayState(currentPlayingBtn, false)
            end
            currentSound:Stop()
            currentSound.SoundId = songData.Id
            currentSound:Play()
            setPlayState(playBtn, true)
            currentPlayingBtn = playBtn
        end
    end)
end

local stopAllBtn = addButton(musicFrame, "MATIKAN MUSIK", UDim2.new(0.62, -10, 0, 26), UDim2.new(0.38, 2, 1, -34), false, 9)
stopAllBtn.MouseButton1Click:Connect(function()
    currentSound:Stop()
    if currentPlayingBtn then
        setPlayState(currentPlayingBtn, false)
        currentPlayingBtn = nil
    end
end)

-- ============================================
-- 3. SIZE ADJUSTER PANEL (16:9) — satu slider, tinggi otomatis
-- ============================================
local sizeFrame = make("Frame", {
    Name = "SizeAdjusterSeparate",
    Size = UDim2.new(0, 208, 0, 117),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 10),
    BackgroundColor3 = PALETTE.Background,
    Active = true,
    Draggable = true,
    ClipsDescendants = true,
    Visible = false,
}, screenGui)
addCorner(sizeFrame, 10)
applyWhiteStroke(sizeFrame, 1.5)
UIState.sizeFrame = sizeFrame

local sizeTopBar = make("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1}, sizeFrame)
addLabel(sizeTopBar, "UKURAN PANEL", UDim2.new(1, -44, 1, 0), UDim2.new(0, 10, 0, 0), 10)
local closeSizeBtn = addButton(sizeTopBar, "X", UDim2.new(0, 20, 0, 20), UDim2.new(1, -28, 0, 4), false, 10)
addDivider(sizeFrame, 28)
openSizeBtn.MouseButton1Click:Connect(function()
    sizeFrame.Visible = not sizeFrame.Visible
end)
closeSizeBtn.MouseButton1Click:Connect(function()
    sizeFrame.Visible = false
end)

local sizeInfo = addLabel(sizeFrame, "", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 34), 10, PALETTE.TextWhite, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
local sliderHit = make("TextButton", {
    Text = "",
    Size = UDim2.new(1, -24, 0, 26),
    Position = UDim2.new(0, 12, 0, 54),
    BackgroundTransparency = 1,
    AutoButtonColor = false,
}, sizeFrame)
local sliderTrack = make("Frame", {
    Size = UDim2.new(1, 0, 0, 4),
    Position = UDim2.new(0, 0, 0.5, -2),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
}, sliderHit)
addCorner(sliderTrack, 2)
local sliderFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = PALETTE.White,
}, sliderTrack)
addCorner(sliderFill, 2)
local sliderKnob = make("Frame", {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0, -7, 0.5, -7),
    BackgroundColor3 = PALETTE.White,
    ZIndex = 2,
}, sliderTrack)
addCorner(sliderKnob, 7)
addStroke(sliderKnob, PALETTE.Background, 2)

local function setPanelWidth(width)
    width = math.clamp(math.floor(width + 0.5), PANEL_MIN_W, PANEL_MAX_W)
    local height = heightFromWidth(width)
    local newSize = UDim2.new(0, width, 0, height)
    mainFrame.Size = newSize
    musicFrame.Size = newSize
    local pct = (width - PANEL_MIN_W) / (PANEL_MAX_W - PANEL_MIN_W)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderKnob.Position = UDim2.new(pct, -7, 0.5, -7)
    sizeInfo.Text = string.format("%d x %d  (16:9)", width, height)
end
setPanelWidth(DEFAULT_W)

local sliderDragging = false
local function setFromInputX(x)
    local trackW = math.max(sliderTrack.AbsoluteSize.X, 1)
    local pct = math.clamp((x - sliderTrack.AbsolutePosition.X) / trackW, 0, 1)
    setPanelWidth(PANEL_MIN_W + (PANEL_MAX_W - PANEL_MIN_W) * pct)
end
sliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setFromInputX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setFromInputX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

local resetBtn = addButton(sizeFrame, "RESET (AUTO 16:9)", UDim2.new(1, -24, 0, 22), UDim2.new(0, 12, 1, -30), false, 9)
resetBtn.MouseButton1Click:Connect(function()
    setPanelWidth(DEFAULT_W)
end)

-- ============================================
-- LOGIN LOGIC
-- ============================================
local function tryLogin()
    local typed = (string.gsub(pinBox.Text, "%s+", ""))
    if string.upper(typed) == string.upper(SECRET_KEY) then
        isAuthenticated = true
        loginFrame:Destroy()
        toggleBtn.Visible = true
        mainFrame.Visible = true
        UIState.panelVisible = true
    else
        loginStatus.Text = "Key salah!\nHubungi WA: " .. WA_NUMBER
        loginStatus.TextColor3 = PALETTE.AccentRed
        pinBox.Text = ""
    end
end
submitBtn.MouseButton1Click:Connect(tryLogin)
pinBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryLogin() end
end)

WLoader.mark(5)
-- ============================================
-- MAIN CONTROLLER
-- ============================================
function WofyRBXM:TogglePanel(forceState)
    if not isAuthenticated then return end
    if forceState ~= nil then UIState.panelVisible = forceState
    else UIState.panelVisible = not UIState.panelVisible end
    if UIState.mainFrame then UIState.mainFrame.Visible = UIState.panelVisible end
end
function WofyRBXM:ScanFiles()
    if UIState.isScanning then return end
    UIState.isScanning = true
    if UIState.statusLabel then UIState.statusLabel.Text = "Scanning..." end
    task.spawn(function()
        local files = scanAll()
        UIState.detectedFiles = files
        self:RefreshFileList()
        if UIState.statusLabel then
            UIState.statusLabel.Text = "Total: " .. #files .. " File"
        end
        UIState.isScanning = false
    end)
end
function WofyRBXM:RefreshFileList()
    if not UIState.scrollFrame then return end
    for _, child in ipairs(UIState.scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local list = UIState.detectedFiles
    if UIState.currentFilter ~= "" then
        local filtered = {}
        for _, f in ipairs(list) do
            if string.find(string.lower(f.name), string.lower(UIState.currentFilter), 1, true) then
                table.insert(filtered, f)
            end
        end
        list = filtered
    end
    if UIState.emptyLabel then
        UIState.emptyLabel.Visible = (#list == 0)
        if #UIState.detectedFiles == 0 then
            UIState.emptyLabel.Text = "Belum ada file RBXM / RBXL / XML\nTekan SCAN untuk mencari."
        else
            UIState.emptyLabel.Text = "File tidak ditemukan."
        end
    end
    for index, data in ipairs(list) do
        local card = make("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = PALETTE.Surface,
            LayoutOrder = index,
        }, UIState.scrollFrame)
        addCorner(card, 5)
        addStroke(card, PALETTE.InnerBorder, 1)
        local nameLabel = addLabel(card, data.name, UDim2.new(0.6, -6, 1, 0), UDim2.new(0, 8, 0, 0), 9, PALETTE.TextWhite, Enum.Font.GothamMedium)
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        local insertBtn = addButton(card, "INSERT", UDim2.new(0.36, -4, 0, 20), UDim2.new(0.64, 0, 0.5, -10), true, 9)
        insertBtn.MouseButton1Click:Connect(function()
            WofyRBXM:LoadFile(data)
        end)
    end
end
function WofyRBXM:LoadFile(fileData)
    if UIState.statusLabel then UIState.statusLabel.Text = "Importing " .. string.upper(tostring(fileData.ext or fileData.ftype or "")) .. "..." end
    task.spawn(function()
        local success, msg = loadFile(fileData)
        if success then
            if UIState.statusLabel then UIState.statusLabel.Text = "OK: " .. tostring(msg) end
        else
            local shortErr = string.sub(tostring(msg), 1, 30)
            if UIState.statusLabel then UIState.statusLabel.Text = "Gagal: " .. shortErr end
            warn("[W RBXM] Gagal: " .. tostring(msg))
        end
        task.wait(3)
        if UIState.statusLabel then UIState.statusLabel.Text = "Ready" end
    end)
end
-- Search filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UIState.currentFilter = searchBox.Text
    WofyRBXM:RefreshFileList()
end)
-- Scan button
refreshBtn.MouseButton1Click:Connect(function()
    WofyRBXM:ScanFiles()
end)
-- ============================================
-- INIT
-- ============================================
function WofyRBXM:Init()
    print("[W] BY WOFY - RBXM & RBXL Importer V1 ( W Engine )")
end
WofyRBXM:Init()
WLoader.ready()
return WofyRBXM
