-- Retro 2013 Modular ESP System (Fixed - Dropdown & Keybind Issues + Toggle State Bug)
-- Panel settings and appearance choices are saved locally between sessions.
-- NOW WITH: Plugin Save/Load API & Enhanced Player Access

-- CHANGELOG SETTINGS: edit these for each release.
local PANEL_VERSION = "1.3.8"
local PANEL_CHANGELOG = {
    Added = {},
    Changed = {},
    Fixed = {"Fixed Remove favorite in the plugin right-click menu so it actually clears the saved favorite and refreshes Favorites"},
    Removed = {},
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Explicit callback types keep plugin callbacks separate from UI text and setting paths.
type ToggleCallback = (boolean) -> ()
type SliderCallback = (number) -> ()
type DropdownCallback = (string) -> ()
type ButtonCallback = () -> ()
type ThemePalette = {[string]: Color3}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RetroESPSystem"
ScreenGui.DisplayOrder = 999999999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local registerThemeObject
local registerThemeGradient
local startupLoadingScreen
local Settings

local function setStartupProgress(progress, status, detail)
    local loader = startupLoadingScreen
    if not loader or not loader.Frame.Parent then
        return
    end
    progress = math.clamp(progress, 0, 1)
    loader.ProgressBarFill.Size = UDim2.new(progress, 0, 1, 0)
    loader.PercentLabel.Text = string.format("%d%%", math.floor(progress * 100 + 0.5))
    if status then loader.StatusLabel.Text = status end
    if detail then loader.CountLabel.Text = detail end
end

local function finishStartupLoading(detail)
    local loader = startupLoadingScreen
    if not loader then
        return
    end
    setStartupProgress(1, "Ready", detail or "The interface is ready.")
    task.delay(0.35, function()
        if startupLoadingScreen == loader then
            loader.Cleanup()
            startupLoadingScreen = nil
        end
    end)
end

local function createStartupLoadingScreen()
    local overlay = Instance.new("Frame")
    overlay.Name = "StartupLoadingScreen"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(15, 24, 37)
    overlay.BorderSizePixel = 0
    overlay.Active = true
    overlay.ZIndex = 250000
    overlay.Parent = ScreenGui

    local backdropGradient = Instance.new("UIGradient")
    backdropGradient.Rotation = 90
    backdropGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 51, 77)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 30, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 16, 25)),
    })
    backdropGradient.Parent = overlay

    local topRule = Instance.new("Frame")
    topRule.Size = UDim2.new(1, 0, 0, 4)
    topRule.BackgroundColor3 = Color3.fromRGB(72, 149, 211)
    topRule.BorderSizePixel = 0
    topRule.ZIndex = 250001
    topRule.Parent = overlay

    local footer = Instance.new("TextLabel")
    footer.Name = "LoadingFooter"
    footer.Size = UDim2.new(1, -32, 0, 20)
    footer.Position = UDim2.new(0, 16, 1, -24)
    footer.BackgroundTransparency = 1
    footer.Text = "SIMBA'S CONTROL PANEL  |  PLUGIN INITIALIZATION"
    footer.TextColor3 = Color3.fromRGB(152, 170, 190)
    footer.TextSize = 10
    footer.Font = Enum.Font.Code
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.ZIndex = 250001
    footer.Parent = overlay

    local shadow = Instance.new("Frame")
    shadow.Name = "LoadingCardShadow"
    shadow.Size = UDim2.new(0, 610, 0, 274)
    shadow.Position = UDim2.new(0.5, -301, 0.5, -130)
    shadow.BackgroundColor3 = Color3.fromRGB(5, 9, 14)
    shadow.BackgroundTransparency = 0.18
    shadow.BorderColor3 = Color3.fromRGB(7, 13, 21)
    shadow.BorderSizePixel = 2
    shadow.ZIndex = 250001
    shadow.Parent = overlay

    local card = Instance.new("Frame")
    card.Name = "LoadingCard"
    card.Size = UDim2.new(0, 600, 0, 262)
    card.Position = UDim2.new(0.5, -300, 0.5, -135)
    card.BackgroundColor3 = Color3.fromRGB(48, 51, 55)
    card.BorderColor3 = Color3.fromRGB(104, 119, 134)
    card.BorderSizePixel = 2
    card.ZIndex = 250002
    card.Parent = overlay

    local cardGradient = Instance.new("UIGradient")
    cardGradient.Rotation = 90
    cardGradient.Color = ColorSequence.new(
        Color3.fromRGB(59, 64, 70),
        Color3.fromRGB(37, 41, 46)
    )
    cardGradient.Parent = card

    local header = Instance.new("Frame")
    header.Name = "LoadingHeader"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(32, 110, 177)
    header.BorderSizePixel = 0
    header.ZIndex = 250003
    header.Parent = card

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Rotation = 90
    headerGradient.Color = ColorSequence.new(
        Color3.fromRGB(47, 137, 205),
        Color3.fromRGB(21, 77, 139)
    )
    headerGradient.Parent = header

    local inset = Instance.new("Frame")
    inset.Name = "CardInset"
    inset.Size = UDim2.new(1, -2, 1, -42)
    inset.Position = UDim2.new(0, 1, 0, 41)
    inset.BackgroundColor3 = Color3.fromRGB(39, 42, 46)
    inset.BorderColor3 = Color3.fromRGB(83, 90, 97)
    inset.BorderSizePixel = 1
    inset.ZIndex = 250003
    inset.Parent = card

    local accent = Instance.new("Frame")
    accent.Name = "AccentLine"
    accent.Size = UDim2.new(1, -2, 0, 3)
    accent.Position = UDim2.new(0, 1, 0, 40)
    accent.BackgroundColor3 = Color3.fromRGB(97, 175, 229)
    accent.BorderSizePixel = 0
    accent.ZIndex = 250004
    accent.Parent = card

    local badge = Instance.new("Frame")
    badge.Name = "LoadingBadge"
    badge.Size = UDim2.new(0, 86, 0, 86)
    badge.Position = UDim2.new(0, 22, 0, 73)
    badge.BackgroundColor3 = Color3.fromRGB(32, 110, 177)
    badge.BorderColor3 = Color3.fromRGB(116, 143, 167)
    badge.BorderSizePixel = 2
    badge.ZIndex = 250004
    badge.Parent = card

    local badgeGradient = Instance.new("UIGradient")
    badgeGradient.Rotation = 45
    badgeGradient.Color = ColorSequence.new(
        Color3.fromRGB(69, 152, 211),
        Color3.fromRGB(24, 79, 132)
    )
    badgeGradient.Parent = badge

    local badgeText = Instance.new("TextLabel")
    badgeText.Name = "LoadingBadgeText"
    badgeText.Size = UDim2.new(1, 0, 0, 56)
    badgeText.Position = UDim2.new(0, 0, 0, 4)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "S"
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.TextSize = 42
    badgeText.Font = Enum.Font.ArialBold
    badgeText.ZIndex = 250005
    badgeText.Parent = badge

    local badgeCaption = Instance.new("TextLabel")
    badgeCaption.Size = UDim2.new(1, 0, 0, 18)
    badgeCaption.Position = UDim2.new(0, 0, 1, -21)
    badgeCaption.BackgroundTransparency = 1
    badgeCaption.Text = "2013"
    badgeCaption.TextColor3 = Color3.fromRGB(224, 236, 247)
    badgeCaption.TextSize = 11
    badgeCaption.Font = Enum.Font.ArialBold
    badgeCaption.ZIndex = 250005
    badgeCaption.Parent = badge

    local title = Instance.new("TextLabel")
    title.Name = "LoadingTitle"
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Simba's Control Panel Reborn"
    title.TextColor3 = Color3.fromRGB(245, 245, 245)
    title.TextSize = 14
    title.Font = Enum.Font.ArialBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 250004
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "LoadingSubtitle"
    subtitle.Size = UDim2.new(1, -146, 0, 23)
    subtitle.Position = UDim2.new(0, 126, 0, 59)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Preparing your workspace"
    subtitle.TextColor3 = Color3.fromRGB(177, 185, 193)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Arial
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 250004
    subtitle.Parent = card

    local status = Instance.new("TextLabel")
    status.Name = "LoadingStatus"
    status.Size = UDim2.new(1, -164, 0, 30)
    status.Position = UDim2.new(0, 126, 0, 86)
    status.BackgroundTransparency = 1
    status.Text = "Preparing settings..."
    status.TextColor3 = Color3.fromRGB(230, 230, 230)
    status.TextSize = 15
    status.Font = Enum.Font.ArialBold
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.ZIndex = 250004
    status.Parent = card

    local activityLight = Instance.new("Frame")
    activityLight.Name = "ActivityLight"
    activityLight.Size = UDim2.new(0, 9, 0, 9)
    activityLight.Position = UDim2.new(0, 126, 0, 127)
    activityLight.BackgroundColor3 = Color3.fromRGB(93, 188, 129)
    activityLight.BorderColor3 = Color3.fromRGB(33, 76, 50)
    activityLight.BorderSizePixel = 1
    activityLight.ZIndex = 250004
    activityLight.Parent = card

    local activityText = Instance.new("TextLabel")
    activityText.Name = "ActivityText"
    activityText.Size = UDim2.new(1, -151, 0, 18)
    activityText.Position = UDim2.new(0, 142, 0, 123)
    activityText.BackgroundTransparency = 1
    activityText.Text = "WORKING"
    activityText.TextColor3 = Color3.fromRGB(163, 176, 186)
    activityText.TextSize = 10
    activityText.Font = Enum.Font.Code
    activityText.TextXAlignment = Enum.TextXAlignment.Left
    activityText.ZIndex = 250004
    activityText.Parent = card

    local pulseTween = TweenService:Create(
        activityLight,
        TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.65}
    )
    pulseTween:Play()

    local bar = Instance.new("Frame")
    bar.Name = "ProgressBar"
    bar.Size = UDim2.new(1, -164, 0, 22)
    bar.Position = UDim2.new(0, 126, 0, 148)
    bar.BackgroundColor3 = Color3.fromRGB(22, 25, 29)
    bar.BorderColor3 = Color3.fromRGB(15, 18, 22)
    bar.BorderSizePixel = 2
    bar.ClipsDescendants = true
    bar.ZIndex = 250004
    bar.Parent = card

    local barInset = Instance.new("Frame")
    barInset.Size = UDim2.new(1, -2, 1, -2)
    barInset.Position = UDim2.new(0, 1, 0, 1)
    barInset.BackgroundColor3 = Color3.fromRGB(31, 35, 39)
    barInset.BorderSizePixel = 0
    barInset.ZIndex = 250004
    barInset.Parent = bar

    local fill = Instance.new("Frame")
    fill.Name = "ProgressFill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(61, 145, 207)
    fill.BorderSizePixel = 0
    fill.ZIndex = 250005
    fill.Parent = barInset

    local fillGradient = Instance.new("UIGradient")
    fillGradient.Rotation = 90
    fillGradient.Color = ColorSequence.new(
        Color3.fromRGB(104, 188, 238),
        Color3.fromRGB(45, 116, 176)
    )
    fillGradient.Parent = fill

    local percent = Instance.new("TextLabel")
    percent.Name = "LoadingPercent"
    percent.Size = UDim2.new(0, 58, 0, 20)
    percent.Position = UDim2.new(1, -72, 0, 178)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.TextColor3 = Color3.fromRGB(220, 226, 231)
    percent.TextSize = 12
    percent.Font = Enum.Font.ArialBold
    percent.TextXAlignment = Enum.TextXAlignment.Right
    percent.ZIndex = 250004
    percent.Parent = card

    local detail = Instance.new("TextLabel")
    detail.Name = "LoadingDetail"
    detail.Size = UDim2.new(1, -224, 0, 23)
    detail.Position = UDim2.new(0, 126, 0, 178)
    detail.BackgroundTransparency = 1
    detail.Text = "Preparing the interface"
    detail.TextColor3 = Color3.fromRGB(171, 180, 188)
    detail.TextSize = 11
    detail.Font = Enum.Font.Arial
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextTruncate = Enum.TextTruncate.AtEnd
    detail.ZIndex = 250004
    detail.Parent = card

    local cardFooter = Instance.new("TextLabel")
    cardFooter.Name = "CardFooter"
    cardFooter.Size = UDim2.new(1, -32, 0, 20)
    cardFooter.Position = UDim2.new(0, 16, 1, -26)
    cardFooter.BackgroundTransparency = 1
    cardFooter.Text = "Please wait while the panel and plugins are prepared."
    cardFooter.TextColor3 = Color3.fromRGB(148, 157, 166)
    cardFooter.TextSize = 10
    cardFooter.Font = Enum.Font.Arial
    cardFooter.TextXAlignment = Enum.TextXAlignment.Left
    cardFooter.ZIndex = 250004
    cardFooter.Parent = card

    return {
        Frame = overlay,
        Card = card,
        Header = header,
        Inset = inset,
        Accent = accent,
        Badge = badge,
        BadgeText = badgeText,
        Subtitle = subtitle,
        Footer = footer,
        CardFooter = cardFooter,
        ActivityLight = activityLight,
        ActivityText = activityText,
        Title = title,
        StatusLabel = status,
        ProgressBarFill = fill,
        PercentLabel = percent,
        CountLabel = detail,
        ErrorLabel = detail,
        Cleanup = function()
            pulseTween:Cancel()
            if overlay.Parent then overlay:Destroy() end
        end,
    }
end

local function findSensitiveReferences(source)
    local categories = {
        ["FILESYSTEM"] = {
            "readfile", "writefile", "appendfile", "delfile", "deletefile",
            "removefile", "isfile", "isfolder", "makefolder", "listfiles",
            "delfolder", "deletefolder", "removefolder", "renamefile", "copyfile",
            "loadfile", "dofile", "io.open", "io.popen", "io.lines", "io.input",
            "io.output", "io.read", "io.write", "io.tmpfile", "os.tmpname",
            "os.execute", "os.remove", "os.rename",
        },
        ["EXTERNAL CODE EXECUTION"] = {
            "loadstring", "loadfile", "dofile", "load", "loadbuffer", "loadmodule",
        },
        ["HTTP REQUESTS"] = {
            "request", "http_request", "syn.request", "fluxus.request", "http.request",
            "HttpGet", "HttpGetAsync", "HttpPost", "HttpPostAsync", "GetAsync",
            "PostAsync", "RequestAsync", "httpget", "httppost", "httpgetasync",
            "httppostasync", "http.get", "http.post", "httpservice.request",
        },
        ["WEBSOCKETS"] = {
            "WebSocket.connect", "WebSocket.connectAsync", "websocket.connect",
            "syn.websocket.connect", "WebSocket.Connect", "websocket.Connect",
        },
        ["EXTERNAL ASSETS / MODULES"] = {
            "game:GetObjects", "InsertService:LoadAsset", "require", "GetObjects",
            "LoadAsset", "LoadAssetAsync", "LoadLocalAsset",
        },
        ["BASE64 ENCODING / DECODING"] = {
            "base64.decode", "base64.encode", "base64_decode", "base64_encode",
            "crypt.base64decode", "crypt.base64encode", "syn.crypt.base64.decode",
            "syn.crypt.base64.encode", "HttpService:Base64Decode", "HttpService:Base64Encode",
        },
        ["BINARY / BYTE DECODING"] = {
            "string.char", "string.byte", "string.pack", "string.unpack", "string.packsize",
            "buffer.readu8", "buffer.readu16", "buffer.readu32", "buffer.readstring",
            "bit32.bxor", "bit32.band", "bit32.bor", "bit32.lshift", "bit32.rshift",
        },
        ["HEX / ESCAPED STRINGS"] = {
            "hexdecode", "fromhex", "hexToString", "string.gsub", "string.format",
        },
        ["DYNAMIC EXECUTION"] = {
            "loadstring", "load", "loadfile", "dofile", "loadbuffer", "loadmodule",
        },
    }

    local sourceLines = {}
    for line in (source .. "\n"):gmatch("(.-)\n") do
        table.insert(sourceLines, line:lower())
    end

    local references = {}
    for category, apiNames in pairs(categories) do
        local categoryMatches = {}
        for _, apiName in ipairs(apiNames) do
            local escapedName = apiName:lower():gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
            local identifierPattern = "%f[%w_]" .. escapedName .. "%f[^%w_]"
            for lineNumber, line in ipairs(sourceLines) do
                if line:find(identifierPattern) then
                    table.insert(categoryMatches, string.format("%s (line %d)", apiName, lineNumber))
                end
            end
        end
        if #categoryMatches > 0 then
            table.sort(categoryMatches)
            references[category] = categoryMatches
        end
    end

    local function addReference(category, label, lineNumber)
        references[category] = references[category] or {}
        table.insert(references[category], string.format("%s (line %d)", label, lineNumber))
    end

    local escapedStringPatterns = {
        {pattern = "\\x%x%x", label = "\\xNN"},
        {pattern = "\\%d%d%d", label = "\\ddd"},
        {pattern = "\\u%{[^}]+%}", label = "\\u{...}"},
    }
    local excessiveEscapes = 0
    local firstEscapeLine = nil
    local xorCount = 0
    local firstXorLine = nil
    local longIdentifierNames = {}
    local luaKeywords = {
        and_ = true, break_ = true, do_ = true, else_ = true, elseif_ = true,
        end_ = true, false_ = true, for_ = true, function_ = true, if_ = true,
        in_ = true, local_ = true, nil_ = true, not_ = true, or_ = true,
        repeat_ = true, return_ = true, then_ = true, true_ = true, until_ = true,
        while_ = true,
    }

    local function entropy(text)
        local frequencies = {}
        for index = 1, #text do
            local character = text:sub(index, index)
            frequencies[character] = (frequencies[character] or 0) + 1
        end
        local score = 0
        for _, count in pairs(frequencies) do
            local probability = count / #text
            score = score - probability * (math.log(probability) / math.log(2))
        end
        return score
    end

    for lineNumber, line in ipairs(sourceLines) do
        if #line >= 500 then
            addReference("OBFUSCATION INDICATORS", string.format("Extremely long line (%d characters)", #line), lineNumber)
        end

        for _, escapedPattern in ipairs(escapedStringPatterns) do
            local _, count = line:gsub(escapedPattern.pattern, "")
            excessiveEscapes = excessiveEscapes + count
            if count > 0 then
                firstEscapeLine = firstEscapeLine or lineNumber
                addReference("HEX / ESCAPED STRINGS", escapedPattern.label, lineNumber)
            end
        end

        local _, lineXorCount = line:gsub("bxor", "")
        xorCount = xorCount + lineXorCount
        if lineXorCount > 0 and not firstXorLine then
            firstXorLine = lineNumber
        end

        -- Inspect ordinary quoted literals for long, encoded-looking, high-entropy data.
        local cursor = 1
        while cursor <= #line do
            local quoteStart = line:find("['\"]", cursor)
            if not quoteStart then break end
            local quote = line:sub(quoteStart, quoteStart)
            local index = quoteStart + 1
            local escaped = false
            while index <= #line do
                local character = line:sub(index, index)
                if escaped then
                    escaped = false
                elseif character == "\\" then
                    escaped = true
                elseif character == quote then
                    break
                end
                index = index + 1
            end
            if index > #line then break end

            local literal = line:sub(quoteStart + 1, index - 1)
            if #literal >= 48 and entropy(literal) >= 4.5 then
                addReference("OBFUSCATION INDICATORS", string.format("High-entropy string (%d characters)", #literal), lineNumber)
            end
            if #literal >= 256 then
                local compact = literal:gsub("%s", "")
                local nonEncodedCharacters = select(2, compact:gsub("[^%w%+/=]", ""))
                local encodedRatio = #compact > 0 and (1 - nonEncodedCharacters / #compact) or 0
                if encodedRatio >= 0.9 then
                    addReference("OBFUSCATION INDICATORS", string.format("Large encoded-looking string (%d characters)", #literal), lineNumber)
                end
            end
            cursor = index + 1
        end

        local numericCount = 0
        for _ in line:gmatch("%f[%d]%d+%f[^%d]") do
            numericCount = numericCount + 1
        end
        local commaCount = select(2, line:gsub(",", ""))
        if numericCount >= 24 and commaCount >= 20 then
            addReference("OBFUSCATION INDICATORS", string.format("Large numeric array (%d numbers on one line)", numericCount), lineNumber)
        end

        local decoderCalls = 0
        for _, decoderName in ipairs({"base64.decode", "base64_decode", "crypt.base64decode", "hexdecode", "fromhex", "string.char"}) do
            local escapedName = decoderName:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
            local _, count = line:gsub(escapedName, "")
            decoderCalls = decoderCalls + count
        end
        if decoderCalls >= 2 then
            addReference("OBFUSCATION INDICATORS", "Multiple decoding/construction calls on one line", lineNumber)
        end

        if line:find("string%.char") and (line:find("table%.concat") or line:find("%.%.")) then
            addReference("OBFUSCATION INDICATORS", "Runtime string construction", lineNumber)
        elseif line:find("string%.format") and line:find("loadstring") then
            addReference("OBFUSCATION INDICATORS", "Runtime-generated code string", lineNumber)
        end

        if line:find("while%s+true%s+do") or line:find("goto%s+[%a_]") then
            addReference("OBFUSCATION INDICATORS", "Unusual control-flow construct", lineNumber)
        end

        local identifierSeen = {}
        for identifier in line:gmatch("[%a_][%w_]*") do
            local normalized = identifier:lower()
            local vowels = select(2, normalized:gsub("[aeiou]", ""))
            local letters = select(2, normalized:gsub("[a-z]", ""))
            if #normalized >= 9 and letters >= 8 and vowels / letters <= 0.18 and not luaKeywords[normalized .. "_"] then
                identifierSeen[identifier] = true
            end
        end
        for identifier in pairs(identifierSeen) do
            longIdentifierNames[identifier] = longIdentifierNames[identifier] or lineNumber
        end
    end

    if excessiveEscapes >= 8 then
        addReference("OBFUSCATION INDICATORS", string.format("Excessive escaped characters (%d sequences)", excessiveEscapes), firstEscapeLine or 1)
    end
    if xorCount >= 3 then
        addReference("OBFUSCATION INDICATORS", string.format("Repeated XOR operations (%d bxor references)", xorCount), firstXorLine or 1)
    end

    local suspiciousNameCount = 0
    for identifier in pairs(longIdentifierNames) do
        suspiciousNameCount = suspiciousNameCount + 1
        if suspiciousNameCount >= 4 then break end
    end
    if suspiciousNameCount >= 4 then
        local firstNameLine = nil
        for _, lineNumber in pairs(longIdentifierNames) do
            firstNameLine = not firstNameLine and lineNumber or math.min(firstNameLine, lineNumber)
        end
        addReference("OBFUSCATION INDICATORS", string.format("Several randomized-looking identifiers (%d+ names)", suspiciousNameCount), firstNameLine or 1)
    end

    local lowerSource = source:lower()
    local virtualizationTerms = {"opcode", "dispatch", "instruction", "registers", "stack"}
    local virtualizationHits = 0
    for _, term in ipairs(virtualizationTerms) do
        if lowerSource:find(term, 1, true) then virtualizationHits = virtualizationHits + 1 end
    end
    if virtualizationHits >= 3 then
        addReference("OBFUSCATION INDICATORS", "Possible virtualized interpreter structure", 1)
    end

    for lineNumber, line in ipairs(sourceLines) do
        if line:find("loadstring", 1, true) and line:find("game:httpget", 1, true) then
            addReference("DYNAMIC EXECUTION", "loadstring(game:HttpGet(...)) pattern", lineNumber)
        end
    end

    for _, categoryMatches in pairs(references) do
        table.sort(categoryMatches)
    end
    return references
end

local function hasPermissionForCategory(pluginName, category)
    local saved = Settings.PluginPermissions[pluginName]
    if saved == true then
        -- Migrate the earlier filename-wide filesystem approval without extending it
        -- to the newly added network, execution, websocket, or asset checks.
        return category == "FILESYSTEM"
    end
    return type(saved) == "table" and saved[category] == true
end

local function createPluginDecisionDialog(titleText, subtitleText, bodyText, choices)
    local overlay = Instance.new("Frame")
    overlay.Name = "PluginDecisionDialog"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(8, 10, 13)
    overlay.BackgroundTransparency = 0.28
    overlay.BorderSizePixel = 0
    overlay.Active = true
    overlay.ZIndex = 260000
    overlay.Parent = ScreenGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 540, 0, 320)
    card.Position = UDim2.new(0.5, -270, 0.5, -160)
    card.BackgroundColor3 = Color3.fromRGB(48, 51, 55)
    card.BorderColor3 = Color3.fromRGB(22, 35, 48)
    card.BorderSizePixel = 2
    card.ZIndex = 260001
    card.Parent = overlay

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 34)
    header.BackgroundColor3 = Color3.fromRGB(32, 110, 177)
    header.BorderSizePixel = 0
    header.ZIndex = 260002
    header.Parent = card

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Rotation = 90
    headerGradient.Color = ColorSequence.new(Color3.fromRGB(47, 137, 205), Color3.fromRGB(21, 77, 139))
    headerGradient.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(250, 250, 250)
    title.TextSize = 14
    title.Font = Enum.Font.ArialBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 260003
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -32, 0, 42)
    subtitle.Position = UDim2.new(0, 16, 0, 46)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = subtitleText
    subtitle.TextColor3 = Color3.fromRGB(230, 230, 230)
    subtitle.TextSize = 13
    subtitle.Font = Enum.Font.ArialBold
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextYAlignment = Enum.TextYAlignment.Top
    subtitle.TextWrapped = true
    subtitle.ZIndex = 260002
    subtitle.Parent = card

    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -32, 0, 150)
    body.Position = UDim2.new(0, 16, 0, 92)
    body.BackgroundColor3 = Color3.fromRGB(31, 33, 36)
    body.BorderColor3 = Color3.fromRGB(73, 77, 82)
    body.BorderSizePixel = 1
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ScrollBarThickness = 6
    body.Active = true
    body.ZIndex = 260002
    body.Parent = card

    local bodyTextLabel = Instance.new("TextLabel")
    bodyTextLabel.Size = UDim2.new(1, -12, 0, 0)
    bodyTextLabel.AutomaticSize = Enum.AutomaticSize.Y
    bodyTextLabel.Position = UDim2.new(0, 6, 0, 6)
    bodyTextLabel.BackgroundTransparency = 1
    bodyTextLabel.Text = bodyText
    bodyTextLabel.TextColor3 = Color3.fromRGB(200, 205, 210)
    bodyTextLabel.TextSize = 12
    bodyTextLabel.Font = Enum.Font.Code
    bodyTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyTextLabel.TextYAlignment = Enum.TextYAlignment.Top
    bodyTextLabel.TextWrapped = true
    bodyTextLabel.ZIndex = 260003
    bodyTextLabel.Parent = body

    local choiceEvent = Instance.new("BindableEvent")
    local gap = 8
    local horizontalPadding = 16
    local buttonWidth = (540 - horizontalPadding * 2 - gap * (#choices - 1)) / #choices
    for index, choice in ipairs(choices) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, buttonWidth, 0, 34)
        button.Position = UDim2.new(0, horizontalPadding + (index - 1) * (buttonWidth + gap), 1, -50)
        button.BackgroundColor3 = choice.color or Color3.fromRGB(57, 125, 181)
        button.BorderColor3 = Color3.fromRGB(25, 35, 45)
        button.BorderSizePixel = 1
        button.Text = choice.label
        button.TextColor3 = Color3.fromRGB(250, 250, 250)
        button.TextSize = 12
        button.Font = Enum.Font.ArialBold
        button.ZIndex = 260003
        button.Parent = card
        button.MouseButton1Click:Connect(function()
            choiceEvent:Fire(choice.value)
        end)
    end

    registerThemeObject(card, "Surface")
    registerThemeObject(header, "Header")
    registerThemeObject(title, "Text")
    registerThemeObject(subtitle, "Text")
    registerThemeObject(body, "Input")
    registerThemeObject(bodyTextLabel, "MutedText")
    registerThemeGradient(headerGradient)

    local selectedChoice = choiceEvent.Event:Wait()
    choiceEvent:Destroy()
    overlay:Destroy()
    return selectedChoice
end

local function showPluginDiagnostic(pluginName, stage, message)
    local rawMessage = tostring(message or "Unknown error")
    local lineNumber = rawMessage:match("[Ll]ine%s+(%d+)") or rawMessage:match(":(%d+):")
    local location = lineNumber and ("Line " .. lineNumber) or "Location not provided by compiler"
    createPluginDecisionDialog(
        "Plugin " .. stage .. " error",
        pluginName .. " could not continue. " .. location,
        rawMessage,
        {{label = "Continue", value = "continue", color = Color3.fromRGB(57, 125, 181)}}
    )
end

startupLoadingScreen = createStartupLoadingScreen()
task.wait()

-- Settings and UI preferences are stored locally in the executor's file system.
Settings = {
    ESP = {
        Enabled = false,
        ShowBoxes = false,
        ShowNames = false,
        ShowDistance = false,
        ShowHealth = false,
        ShowTracers = false,
        TeamCheck = false,
        MaxDistance = 1000
    },
    PluginSettings = {} :: {[string]: any},
    PluginPermissions = {} :: {[string]: any},
    HideBind = {kind = "KeyCode", name = "RightShift"},
}

local PLUGIN_DATA_FOLDER = "RetroESP_PluginData"
local CONFIG_FILE = PLUGIN_DATA_FOLDER .. "/panel-settings.json"
local settingsRefreshers = {}

local function copySerializable(value, seen)
    local valueType = type(value)
    if valueType == "string" or valueType == "boolean" then
        return value
    elseif valueType == "number" then
        if value == value and value ~= math.huge and value ~= -math.huge then
            return value
        end
        return nil
    elseif valueType ~= "table" then
        return nil
    end

    seen = seen or {}
    if seen[value] then
        return nil
    end
    seen[value] = true

    local result = {}
    for key, child in pairs(value) do
        if type(key) == "string" or (type(key) == "number" and key == math.floor(key)) then
            local safeChild = copySerializable(child, seen)
            if safeChild ~= nil then
                result[key] = safeChild
            end
        end
    end

    seen[value] = nil
    return result
end

local function mergeSavedSettings(target, saved)
    if type(target) ~= "table" or type(saved) ~= "table" then
        return
    end

    for key, value in pairs(saved) do
        if type(key) == "string" or type(key) == "number" then
            local current = target[key]
            if type(current) == "table" and type(value) == "table" then
                mergeSavedSettings(current, value)
            elseif current == nil or type(current) == type(value) then
                if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                    target[key] = value
                elseif current == nil and type(value) == "table" then
                    target[key] = copySerializable(value)
                end
            end
        end
    end
end

local function readSettingPath(root, path)
    local value = root
    for _, key in ipairs(path) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
    end
    return value
end

local function writeSettingPath(root, path, newValue)
    local parent = root
    for index = 1, #path - 1 do
        local key = path[index]
        if type(parent[key]) ~= "table" then
            parent[key] = {}
        end
        parent = parent[key]
    end
    if #path > 0 then
        parent[path[#path]] = newValue
    end
end

local function readPanelConfig()
    if not isfile or not readfile then
        return nil
    end

    local ok, config = pcall(function()
        if not isfile(CONFIG_FILE) then
            return nil
        end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(config) == "table" then
        return config
    end
    return nil
end

local loadedConfig = readPanelConfig()
if loadedConfig and type(loadedConfig.settings) == "table" then
    mergeSavedSettings(Settings, loadedConfig.settings)
end
setStartupProgress(0.12, "Loading saved preferences...", "Preparing theme and plugin settings")
task.wait()

local Plugins = {}
local pluginAPIs: {[string]: any} = {}
local ESPObjects = {}
local connections = {}
local windowZIndex = 100

-- Dragging follows the cursor with a frame-rate independent easing factor.
-- The target continues to settle even when the mouse stops moving.
local function attachSmoothDrag(handle, frame, connectionList, onStart)
    local draggingNow = false
    local startMouse = nil
    local startPosition = nil
    local targetPosition = frame.Position
    local responsiveness = 17

    -- Work in the same coordinate system as the ScreenGui. Respect the
    -- frame's AnchorPoint and scale-based Position when clamping offsets.
    local function clampToScreen(position)
        local viewport = ScreenGui.AbsoluteSize
        local frameSize = frame.AbsoluteSize
        if viewport.X <= 0 or viewport.Y <= 0 then return position end

        local anchor = frame.AnchorPoint
        local minX = frameSize.X * anchor.X
        local maxX = viewport.X - frameSize.X * (1 - anchor.X)
        local minY = frameSize.Y * anchor.Y
        local maxY = viewport.Y - frameSize.Y * (1 - anchor.Y)

        -- For windows larger than the screen, keep their top-left corner
        -- accessible rather than allowing the entire window to disappear.
        if maxX < minX then maxX = minX end
        if maxY < minY then maxY = minY end

        local x = math.clamp(viewport.X * position.X.Scale + position.X.Offset, minX, maxX)
        local y = math.clamp(viewport.Y * position.Y.Scale + position.Y.Offset, minY, maxY)
        return UDim2.new(
            position.X.Scale, x - viewport.X * position.X.Scale,
            position.Y.Scale, y - viewport.Y * position.Y.Scale
        )
    end

    local began = handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if frame:GetAttribute("SimbaResizing") then return end
        if onStart then onStart() end
        draggingNow = true
        startMouse = input.Position
        startPosition = clampToScreen(frame.Position)
        targetPosition = startPosition
    end)

    local moved = UserInputService.InputChanged:Connect(function(input)
        if not draggingNow or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - startMouse
        targetPosition = clampToScreen(UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        ))
    end)

    local ended = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingNow = false
        end
    end)

    local render = RunService.RenderStepped:Connect(function(dt)
        if not frame.Parent then return end
        if frame:GetAttribute("SimbaResizing") then
            draggingNow = false
            targetPosition = frame.Position
            return
        end
        targetPosition = clampToScreen(targetPosition)
        local alpha = 1 - math.exp(-responsiveness * math.min(dt, 0.1))
        frame.Position = clampToScreen(frame.Position:Lerp(targetPosition, alpha))
    end)

    local localConnections = {began, moved, ended, render}
    if connectionList then
        for _, connection in ipairs(localConnections) do
            table.insert(connectionList, connection)
        end
    end
    frame.Destroying:Connect(function()
        for _, connection in ipairs(localConnections) do
            connection:Disconnect()
        end
    end)
end



-- Windows-style eight-direction resizing. Handles live inside the window,
-- with their hit areas inset from the edges so they remain on-screen.
local function attachWindowResize(frame, minWidth, minHeight, connectionList, onResize, onStart)
    local edge = 7
    local corner = 13
    local handles = {
        {"Top", 0, -1, UDim2.new(0, corner, 0, 0), UDim2.new(1, -2*corner, 0, edge)},
        {"Bottom", 0, 1, UDim2.new(0, corner, 1, -edge), UDim2.new(1, -2*corner, 0, edge)},
        {"Left", -1, 0, UDim2.new(0, 0, 0, corner), UDim2.new(0, edge, 1, -2*corner)},
        {"Right", 1, 0, UDim2.new(1, -edge, 0, corner), UDim2.new(0, edge, 1, -2*corner)},
        {"TopLeft", -1, -1, UDim2.fromOffset(0, 0), UDim2.fromOffset(corner, corner)},
        {"TopRight", 1, -1, UDim2.new(1, -corner, 0, 0), UDim2.fromOffset(corner, corner)},
        {"BottomLeft", -1, 1, UDim2.new(0, 0, 1, -corner), UDim2.fromOffset(corner, corner)},
        {"BottomRight", 1, 1, UDim2.new(1, -corner, 1, -corner), UDim2.fromOffset(corner, corner)},
    }
    local active, startMouse, startLeft, startTop, startW, startH
    local function viewport()
        return ScreenGui.AbsoluteSize
    end
    local function resizeAt(mouse)
        if not active or not frame.Parent then return end
        local bounds = viewport()
        if bounds.X <= 0 or bounds.Y <= 0 then return end
        local dx = mouse.X - startMouse.X
        local dy = mouse.Y - startMouse.Y
        local x1, y1 = startLeft, startTop
        local x2, y2 = startLeft + startW, startTop + startH
        local maxW = math.max(1, bounds.X)
        local maxH = math.max(1, bounds.Y)
        local minW = math.min(minWidth, maxW)
        local minH = math.min(minHeight, maxH)
        if active.x == -1 then x1 = math.clamp(startLeft + dx, 0, x2 - minW) end
        if active.x == 1 then x2 = math.clamp(startLeft + startW + dx, x1 + minW, maxW) end
        if active.y == -1 then y1 = math.clamp(startTop + dy, 0, y2 - minH) end
        if active.y == 1 then y2 = math.clamp(startTop + startH + dy, y1 + minH, maxH) end
        local w, h = x2 - x1, y2 - y1
        local anchor = frame.AnchorPoint
        frame.Position = UDim2.fromOffset(x1 + anchor.X * w, y1 + anchor.Y * h)
        frame.Size = UDim2.fromOffset(w, h)
        if onResize then onResize(w, h) end
    end
    local localConnections = {}
    for _, spec in ipairs(handles) do
        local handle = Instance.new("TextButton")
        handle.Name = "Resize" .. spec[1]
        handle.BackgroundTransparency = 1
        handle.Text = ""
        handle.AutoButtonColor = false
        handle.BorderSizePixel = 0
        handle.Position = spec[4]
        handle.Size = spec[5]
        handle.ZIndex = 100000
        handle.Parent = frame
        local c = handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if frame:GetAttribute("SimbaResizeDisabled") then return end
            if onStart then onStart() end
            local abs = frame.AbsolutePosition
            local size = frame.AbsoluteSize
            active = {x = spec[2], y = spec[3]}
            startMouse = input.Position
            startLeft, startTop = abs.X, abs.Y
            startW, startH = size.X, size.Y
            frame:SetAttribute("SimbaResizing", true)
        end)
        table.insert(localConnections, c)
    end
    table.insert(localConnections, UserInputService.InputChanged:Connect(function(input)
        if active and input.UserInputType == Enum.UserInputType.MouseMovement then
            resizeAt(input.Position)
        end
    end))
    table.insert(localConnections, UserInputService.InputEnded:Connect(function(input)
        if active and input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizeAt(input.Position)
            active = nil
            frame:SetAttribute("SimbaResizing", false)
        end
    end))
    if connectionList then
        for _, c in ipairs(localConnections) do table.insert(connectionList, c) end
    end
    frame.Destroying:Connect(function()
        for _, c in ipairs(localConnections) do c:Disconnect() end
    end)
end

-- Plugin data and panel configuration share a dedicated local folder.
pcall(function()
    if not isfolder(PLUGIN_DATA_FOLDER) then
        makefolder(PLUGIN_DATA_FOLDER)
    end
end)

-- Notification System
local pruneThemeObjects
local refreshThemeGradients
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 1, 0)
NotificationContainer.Position = UDim2.new(1, -310, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ZIndex = 10000
NotificationContainer.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Padding = UDim.new(0, 5)
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Parent = NotificationContainer

local notificationQueue = {}

local function createNotification(title, message, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(45, 49, 53)
    NotifFrame.BorderColor3 = Color3.fromRGB(77, 82, 88)
    NotifFrame.BorderSizePixel = 2
    NotifFrame.ClipsDescendants = true
    NotifFrame.ZIndex = 10001
    NotifFrame.Parent = NotificationContainer
    registerThemeObject(NotifFrame, "Surface")
    
    -- Color based on type
    local accentColor = Color3.fromRGB(47, 123, 185)
    if notifType == "success" then
        accentColor = Color3.fromRGB(50, 200, 100)
    elseif notifType == "warning" then
        accentColor = Color3.fromRGB(255, 180, 50)
    elseif notifType == "error" then
        accentColor = Color3.fromRGB(220, 60, 60)
    end
    
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BackgroundColor3 = accentColor
    AccentBar.BorderSizePixel = 0
    AccentBar.ZIndex = 10002
    AccentBar.Parent = NotifFrame
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -10, 1, -10)
    ContentFrame.Position = UDim2.new(0, 8, 0, 5)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 10002
    ContentFrame.Parent = NotifFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.ArialBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextYAlignment = Enum.TextYAlignment.Top
    TitleLabel.ZIndex = 10003
    TitleLabel.Parent = ContentFrame
    registerThemeObject(TitleLabel, "Text")
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, 0, 1, -18)
    MessageLabel.Position = UDim2.new(0, 0, 0, 18)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    MessageLabel.TextSize = 11
    MessageLabel.Font = Enum.Font.Arial
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.TextWrapped = true
    MessageLabel.ZIndex = 10003
    MessageLabel.Parent = ContentFrame
    registerThemeObject(MessageLabel, "MutedText")
    
    -- Calculate height based on text
    local textHeight = math.max(50, MessageLabel.TextBounds.Y + 28)
    
    -- Animate in
    NotifFrame:TweenSize(
        UDim2.new(1, 0, 0, textHeight),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    
    -- Auto-remove after duration
    task.delay(duration, function()
        NotifFrame:TweenSize(
            UDim2.new(1, 0, 0, 0),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.2,
            true,
            function()
                NotifFrame:Destroy()
            end
        )
    end)
    
    return NotifFrame
end

-- Screen UI System (for creating custom HUD elements)
local ScreenUIContainer = Instance.new("Frame")
ScreenUIContainer.Name = "ScreenUIContainer"
ScreenUIContainer.Size = UDim2.new(1, 0, 1, 0)
ScreenUIContainer.BackgroundTransparency = 1
ScreenUIContainer.ZIndex = 5000
ScreenUIContainer.Parent = ScreenGui

local screenUIElements = {}

local function createScreenUI(name, position, size)
    if screenUIElements[name] then
        screenUIElements[name]:Destroy()
        pruneThemeObjects({})
    end
    
    local UIFrame = Instance.new("Frame")
    UIFrame.Name = name
    UIFrame.Size = size or UDim2.new(0, 200, 0, 100)
    UIFrame.Position = position or UDim2.new(0.5, -100, 0.5, -50)
    UIFrame.BackgroundColor3 = Color3.fromRGB(42, 46, 51)
    UIFrame.BackgroundTransparency = 0.3
    UIFrame.BorderColor3 = Color3.fromRGB(47, 123, 185)
    UIFrame.BorderSizePixel = 2
    UIFrame.ZIndex = 5001
    UIFrame.Parent = ScreenUIContainer
    registerThemeObject(UIFrame, "Surface")
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 2)
    ContentLayout.Parent = UIFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.Parent = UIFrame
    
    screenUIElements[name] = UIFrame
    
    -- API for the UI element
    local UIElementAPI = {
        Frame = UIFrame,
        
        AddText = function(text, size, color)
            local TextLabel = Instance.new("TextLabel")
            TextLabel.Size = UDim2.new(1, 0, 0, size or 20)
            TextLabel.BackgroundTransparency = 1
            TextLabel.Text = text
            TextLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
            TextLabel.TextSize = size or 14
            TextLabel.Font = Enum.Font.Arial
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.ZIndex = 5002
            TextLabel.Parent = UIFrame
            if color == nil then
                registerThemeObject(TextLabel, "Text")
            end
            return TextLabel
        end,
        
        AddBar = function(text, maxValue, currentValue, color)
            local BarFrame = Instance.new("Frame")
            BarFrame.Size = UDim2.new(1, 0, 0, 25)
            BarFrame.BackgroundTransparency = 1
            BarFrame.ZIndex = 5002
            BarFrame.Parent = UIFrame
            
            local BarLabel = Instance.new("TextLabel")
            BarLabel.Size = UDim2.new(1, 0, 0, 12)
            BarLabel.BackgroundTransparency = 1
            BarLabel.Text = text
            BarLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            BarLabel.TextSize = 11
            BarLabel.Font = Enum.Font.Arial
            BarLabel.TextXAlignment = Enum.TextXAlignment.Left
            BarLabel.ZIndex = 5003
            BarLabel.Parent = BarFrame
            registerThemeObject(BarLabel, "MutedText")
            
            local BarBG = Instance.new("Frame")
            BarBG.Size = UDim2.new(1, 0, 0, 10)
            BarBG.Position = UDim2.new(0, 0, 0, 13)
            BarBG.BackgroundColor3 = Color3.fromRGB(45, 49, 53)
            BarBG.BorderSizePixel = 0
            BarBG.ZIndex = 5003
            BarBG.Parent = BarFrame
            registerThemeObject(BarBG, "Input")
            
            local BarFill = Instance.new("Frame")
            BarFill.Size = UDim2.new((currentValue or 0) / (maxValue or 100), 0, 1, 0)
            BarFill.BackgroundColor3 = color or Color3.fromRGB(47, 123, 185)
            BarFill.BorderSizePixel = 0
            BarFill.ZIndex = 5004
            BarFill.Parent = BarBG
            if color == nil then
                registerThemeObject(BarFill, "Primary")
            end
            
            return BarFrame, BarFill, BarLabel
        end,
        
        Clear = function()
            for _, child in ipairs(UIFrame:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
        end,
        
        Show = function()
            UIFrame.Visible = true
        end,
        
        Hide = function()
            UIFrame.Visible = false
        end,
        
        Destroy = function()
            UIFrame:Destroy()
            screenUIElements[name] = nil
            pruneThemeObjects({})
        end
    }
    
    return UIElementAPI
end

-- Plugin System
-- Use only the current plugin data filename format.
local function getPluginDataPath(pluginName)
    if pluginName == nil then return nil end
    local safeName = tostring(pluginName):lower():gsub("%s+", "_"):gsub("[^%w%._%-]", "_")
    if safeName == "" or safeName == "." or safeName == ".." or safeName:match("^%.") then
        safeName = "plugin_" .. safeName:gsub("^%.*", "")
    end
    return PLUGIN_DATA_FOLDER .. "/" .. safeName .. ".json"
end

local PluginAPI = {
    Settings = Settings,
    ESPObjects = ESPObjects,
    CreateTab = nil,
    CreateToggle = nil,
    CreateSlider = nil,
    CreateButton = nil,
    CreateDropdown = nil,
    CreateLabel = nil,
    CreateWindow = nil,
    
    -- Player/Game Access
    GetLocalPlayer = function() return LocalPlayer end,
    GetPlayers = function() return Players:GetPlayers() end,
    GetCamera = function() return workspace.CurrentCamera end,
    GetWorkspace = function() return workspace end,
    
    -- Notification System (NEW!)
    Notify = function(title, message, duration, notifType)
        return createNotification(title, message, duration, notifType)
    end,
    
    -- Screen UI System (NEW!)
    CreateScreenUI = function(name, position, size)
        return createScreenUI(name, position, size)
    end,
    
    GetScreenUI = function(name)
        return screenUIElements[name]
    end,
    
    -- Connection Management
    PluginConnections = {},
    PluginData = {},
    
    -- Save/Load Functions (per-plugin storage)
    SavePluginData = function(pluginName, key, value)
        if pluginName == nil or key == nil then 
            warn("SavePluginData requires pluginName and key")
            return false
        end
        
        local filePath = getPluginDataPath(pluginName)
        local data = {}
        
        -- Load existing data
        if isfile and isfile(filePath) then
            local success, result = pcall(function()
                return HttpService:JSONDecode(readfile(filePath))
            end)
            if success and type(result) == "table" then
                data = result
            else
                warn("[Plugin data] Existing saved file could not be decoded; refusing to overwrite: " .. filePath)
                return false
            end
        end
        
        -- Store only values JSON can represent; nil removes the selected key.
        local safeValue = copySerializable(value)
        data[tostring(key)] = safeValue
        if safeValue == nil then
            data[tostring(key)] = nil
        end
        
        -- Write to file
        local success, err = pcall(function()
            if not isfolder(PLUGIN_DATA_FOLDER) then
                makefolder(PLUGIN_DATA_FOLDER)
            end
            writefile(filePath, HttpService:JSONEncode(data))
        end)
        
        if not success then
            warn("Failed to save plugin data: " .. tostring(err))
            return false
        end
        
        return true
    end,
    
    LoadPluginData = function(pluginName, key, defaultValue)
        if pluginName == nil or key == nil then 
            warn("LoadPluginData requires pluginName and key")
            return defaultValue
        end
        
        local filePath = getPluginDataPath(pluginName)
        
        if not isfile or not isfile(filePath) then
            return defaultValue
        end
        
        local success, result = pcall(function()
            local data = HttpService:JSONDecode(readfile(filePath))
            return type(data) == "table" and data[tostring(key)] or nil
        end)
        
        if success and result ~= nil then
            return result
        end
        
        return defaultValue
    end,
    
    GetAllPluginData = function(pluginName)
        if not pluginName then 
            warn("GetAllPluginData requires pluginName")
            return {}
        end
        
        local filePath = getPluginDataPath(pluginName)
        
        if not isfile or not isfile(filePath) then
            return {}
        end
        
        local success, result = pcall(function()
            local data = HttpService:JSONDecode(readfile(filePath))
            return type(data) == "table" and data or {}
        end)
        
        if success then
            return result
        end
        
        return {}
    end,
    
    ClearPluginData = function(pluginName)
        if not pluginName then 
            warn("ClearPluginData requires pluginName")
            return false
        end
        
        local filePath = getPluginDataPath(pluginName)
        
        if isfile and isfile(filePath) and delfile then
            return pcall(delfile, filePath)
        end
        
        return false
    end
}

-- Define RegisterConnection AFTER PluginAPI is created
PluginAPI.RegisterConnection = function(connection)
    if not PluginAPI.PluginConnections then
        warn("PluginConnections table not initialized!")
        PluginAPI.PluginConnections = {}
    end
    if connection then
        table.insert(PluginAPI.PluginConnections, connection)
    end
    return connection
end

-- Plugin folder path
local PLUGIN_FOLDER = "RetroESP_Plugins"

if not isfolder(PLUGIN_FOLDER) then
    makefolder(PLUGIN_FOLDER)
    print("Created plugin folder: " .. PLUGIN_FOLDER)
end

-- Loading Screen
local function createLoadingScreen()
    local LoadFrame = Instance.new("Frame")
    LoadFrame.Name = "LoadingScreen"
    LoadFrame.Size = UDim2.new(0, 320, 0, 130)
    LoadFrame.Position = UDim2.new(0.5, -160, 0.5, -65)
    LoadFrame.BackgroundColor3 = Color3.fromRGB(45, 49, 53)
    LoadFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
    LoadFrame.BorderSizePixel = 3
    LoadFrame.ZIndex = 200000
    LoadFrame.Parent = ScreenGui
    registerThemeObject(LoadFrame, "Surface")

    local LoadGradient = Instance.new("UIGradient")
    LoadGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(77, 81, 86)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 49, 53))
    })
    LoadGradient.Rotation = 90
    LoadGradient.Parent = LoadFrame
    registerThemeGradient(LoadGradient)

    -- Top bar
    local LoadTopBar = Instance.new("Frame")
    LoadTopBar.Size = UDim2.new(1, 0, 0, 25)
    LoadTopBar.BackgroundColor3 = Color3.fromRGB(32, 125, 205)
    LoadTopBar.BorderSizePixel = 0
    LoadTopBar.ZIndex = 200001
    LoadTopBar.Parent = LoadFrame
    registerThemeObject(LoadTopBar, "Header")

    local LoadTopGradient = Instance.new("UIGradient")
    LoadTopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 145, 225)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 105, 175))
    })
    LoadTopGradient.Rotation = 90
    LoadTopGradient.Parent = LoadTopBar
    registerThemeGradient(LoadTopGradient)

    local LoadTitle = Instance.new("TextLabel")
    LoadTitle.Size = UDim2.new(1, -50, 1, 0)
    LoadTitle.Position = UDim2.new(0, 5, 0, 0)
    LoadTitle.BackgroundTransparency = 1
    LoadTitle.Text = "Loading plugins..."
    LoadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadTitle.TextSize = 13
    LoadTitle.Font = Enum.Font.ArialBold
    LoadTitle.TextXAlignment = Enum.TextXAlignment.Left
    LoadTitle.ZIndex = 200002
    LoadTitle.Parent = LoadTopBar
    registerThemeObject(LoadTitle, "Text")

    -- Close button
    local LoadCloseBtn = Instance.new("TextButton")
    LoadCloseBtn.Size = UDim2.new(0, 20, 0, 18)
    LoadCloseBtn.Position = UDim2.new(1, -23, 0, 3)
    LoadCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    LoadCloseBtn.BorderColor3 = Color3.fromRGB(150, 40, 40)
    LoadCloseBtn.Text = "X"
    LoadCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadCloseBtn.TextSize = 12
    LoadCloseBtn.Font = Enum.Font.ArialBold
    LoadCloseBtn.ZIndex = 200002
    LoadCloseBtn.Parent = LoadTopBar
    registerThemeObject(LoadCloseBtn, "Danger")

    -- Minimize button
    local LoadMinBtn = Instance.new("TextButton")
    LoadMinBtn.Size = UDim2.new(0, 20, 0, 18)
    LoadMinBtn.Position = UDim2.new(1, -46, 0, 3)
    LoadMinBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 180)
    LoadMinBtn.BorderColor3 = Color3.fromRGB(70, 110, 150)
    LoadMinBtn.Text = "_"
    LoadMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadMinBtn.TextSize = 12
    LoadMinBtn.Font = Enum.Font.ArialBold
    LoadMinBtn.ZIndex = 200002
    LoadMinBtn.Parent = LoadTopBar
    registerThemeObject(LoadMinBtn, "Secondary")

    -- Content area
    local LoadContent = Instance.new("Frame")
    LoadContent.Size = UDim2.new(1, -20, 1, -35)
    LoadContent.Position = UDim2.new(0, 10, 0, 30)
    LoadContent.BackgroundTransparency = 1
    LoadContent.ZIndex = 200001
    LoadContent.Parent = LoadFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Scanning plugin folder..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Arial
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.ZIndex = 200002
    StatusLabel.Parent = LoadContent
    registerThemeObject(StatusLabel, "Text")

    local ProgressBarBG = Instance.new("Frame")
    ProgressBarBG.Size = UDim2.new(1, 0, 0, 12)
    ProgressBarBG.Position = UDim2.new(0, 0, 0, 26)
    ProgressBarBG.BackgroundColor3 = Color3.fromRGB(42, 46, 51)
    ProgressBarBG.BorderColor3 = Color3.fromRGB(77, 81, 86)
    ProgressBarBG.BorderSizePixel = 1
    ProgressBarBG.ZIndex = 200002
    ProgressBarBG.Parent = LoadContent
    registerThemeObject(ProgressBarBG, "Input")

    local ProgressBarFill = Instance.new("Frame")
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressBarFill.BackgroundColor3 = Color3.fromRGB(47, 123, 185)
    ProgressBarFill.BorderSizePixel = 0
    ProgressBarFill.ZIndex = 200003
    ProgressBarFill.Parent = ProgressBarBG
    registerThemeObject(ProgressBarFill, "Primary")

    local CountLabel = Instance.new("TextLabel")
    CountLabel.Size = UDim2.new(1, 0, 0, 18)
    CountLabel.Position = UDim2.new(0, 0, 0, 44)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Text = ""
    CountLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    CountLabel.TextSize = 10
    CountLabel.Font = Enum.Font.Arial
    CountLabel.TextXAlignment = Enum.TextXAlignment.Left
    CountLabel.ZIndex = 200002
    CountLabel.Parent = LoadContent
    registerThemeObject(CountLabel, "MutedText")

    local ErrorLabel = Instance.new("TextLabel")
    ErrorLabel.Size = UDim2.new(1, 0, 0, 18)
    ErrorLabel.Position = UDim2.new(0, 0, 0, 62)
    ErrorLabel.BackgroundTransparency = 1
    ErrorLabel.Text = ""
    ErrorLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
    ErrorLabel.TextSize = 10
    ErrorLabel.Font = Enum.Font.Arial
    ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
    ErrorLabel.ZIndex = 200002
    ErrorLabel.Parent = LoadContent

    -- Smooth drag for the plugin loader.
    attachSmoothDrag(LoadTopBar, LoadFrame, connections)

    -- Minimize
    local loadMinimized = false
    LoadMinBtn.MouseButton1Click:Connect(function()
        loadMinimized = not loadMinimized
        if loadMinimized then
            LoadFrame.Size = UDim2.new(0, 320, 0, 25)
            LoadContent.Visible = false
            LoadMinBtn.Text = "+"
        else
            LoadFrame.Size = UDim2.new(0, 320, 0, 130)
            LoadContent.Visible = true
            LoadMinBtn.Text = "_"
        end
    end)

    local isCleaned = false
    local function cleanupLoader()
        if isCleaned then return end
        isCleaned = true
        if LoadFrame and LoadFrame.Parent then
            LoadFrame:Destroy()
            pruneThemeObjects({})
            refreshThemeGradients()
        end
    end

    LoadCloseBtn.MouseButton1Click:Connect(cleanupLoader)

    return {
        Frame = LoadFrame,
        StatusLabel = StatusLabel,
        ProgressBarFill = ProgressBarFill,
        CountLabel = CountLabel,
        ErrorLabel = ErrorLabel,
        Cleanup = cleanupLoader,
    }
end

-- Load plugins from folder (runs in its own task so it never blocks the main script)
local INIT_TIMEOUT = 20 -- Allow slower plugins to finish initialization
local updatePluginHub
local createPluginAPI
local schedulePanelSave
local cleanupPluginRuntime
local pluginSourcePaths = {}

local function loadPlugins(useStartupOverlay, onlyFilePath)
    task.spawn(function()
        if not isfolder(PLUGIN_FOLDER) then
            if useStartupOverlay then
                finishStartupLoading("Plugin folder is unavailable; the panel is ready.")
            end
            return
        end

        local pluginFiles = listfiles(PLUGIN_FOLDER)
        local luaFiles = {}
        for _, filePath in ipairs(pluginFiles) do
            if filePath:match("%.lua$") and (not onlyFilePath or filePath:gsub("\\", "/") == onlyFilePath:gsub("\\", "/")) then
                table.insert(luaFiles, filePath)
            end
        end

        local total = #luaFiles
        if total == 0 then
            if useStartupOverlay then
                finishStartupLoading("No plugins found. The panel is ready.")
            end
            return
        end

        -- Keep the full-screen startup view until the panel and plugins are ready.
        local loader = useStartupOverlay and startupLoadingScreen or createLoadingScreen()
        local loaded = 0
        local failed = 0

        for i, filePath in ipairs(luaFiles) do
            local shortName = filePath:match("([^/\\]+)$") or filePath

            -- Update UI
            loader.StatusLabel.Text = useStartupOverlay
                and string.format("Loading plugin %d of %d: %s", i, total, shortName)
                or ("Loading: " .. shortName)
            loader.CountLabel.Text = string.format("Plugin %d / %d  |  %d loaded  |  %d skipped", i, total, loaded, failed)
            local pluginProgress = (i - 1) / total
            loader.ProgressBarFill.Size = UDim2.new(pluginProgress, 0, 1, 0)
            if useStartupOverlay then
                setStartupProgress(0.76 + pluginProgress * 0.22, loader.StatusLabel.Text, loader.CountLabel.Text)
            end
            loader.ErrorLabel.Text = ""
            task.wait() -- yield one frame so progress can render without a fixed delay

            -- Stage 1: Read file
            local readOk, pluginCode = pcall(readfile, filePath)
            if not readOk then
                warn("[" .. shortName .. "] Could not read file: " .. tostring(pluginCode))
                loader.ErrorLabel.Text = "Could not read: " .. shortName
                failed = failed + 1
                showPluginDiagnostic(shortName, "read", pluginCode)
                continue
            end
            if type(pluginCode) ~= "string" then
                local message = "readfile returned " .. typeof(pluginCode) .. " instead of plugin source text."
                loader.ErrorLabel.Text = "Invalid source: " .. shortName
                failed = failed + 1
                showPluginDiagnostic(shortName, "read", message)
                continue
            end

            -- Check source for capability-related identifiers before compiling.
            -- This is a text scan, not a sandbox against indirect or obfuscated calls.
            local sensitiveReferences = findSensitiveReferences(pluginCode)
            local requiresApproval = false
            for category in pairs(sensitiveReferences) do
                if not hasPermissionForCategory(shortName, category) then
                    requiresApproval = true
                    break
                end
            end

            if requiresApproval then
                local categoryOrder = {
                    "FILESYSTEM", "EXTERNAL CODE EXECUTION", "HTTP REQUESTS",
                    "WEBSOCKETS", "EXTERNAL ASSETS / MODULES",
                    "BASE64 ENCODING / DECODING", "BINARY / BYTE DECODING",
                    "HEX / ESCAPED STRINGS", "DYNAMIC EXECUTION", "OBFUSCATION INDICATORS",
                }
                local referenceLines = {}
                for _, category in ipairs(categoryOrder) do
                    local categoryMatches = sensitiveReferences[category]
                    if categoryMatches then
                        table.insert(referenceLines, category .. ":")
                        for _, match in ipairs(categoryMatches) do
                            table.insert(referenceLines, "  " .. match)
                        end
                    end
                end
                local decision = createPluginDecisionDialog(
                    "Plugin capability warning",
                    shortName .. " contains API references or code patterns associated with file access, decoding, dynamic execution, network use, or obfuscation.",
                    "Detected source references:\n" .. table.concat(referenceLines, "\n")
                        .. "\n\nAllow once loads it this time. Always allow saves approval for this filename and the categories shown. Deny skips this plugin.\n\nThis scan may match comments or strings. Obfuscation checks are heuristics, can flag harmless code, and cannot catch every indirect or obfuscated call.",
                    {
                        {label = "Allow Once", value = "once", color = Color3.fromRGB(57, 125, 181)},
                        {label = "Always Allow", value = "always", color = Color3.fromRGB(57, 145, 92)},
                        {label = "Deny", value = "deny", color = Color3.fromRGB(160, 63, 57)},
                    }
                )
                if decision ~= "once" and decision ~= "always" then
                    loader.ErrorLabel.Text = "Access denied: " .. shortName
                    failed = failed + 1
                    continue
                elseif decision == "always" then
                    local savedPermissions = Settings.PluginPermissions[shortName]
                    if savedPermissions == true then
                        savedPermissions = {FILESYSTEM = true}
                    elseif type(savedPermissions) ~= "table" then
                        savedPermissions = {}
                    end
                    for category in pairs(sensitiveReferences) do
                        savedPermissions[category] = true
                    end
                    Settings.PluginPermissions[shortName] = savedPermissions
                    if schedulePanelSave then
                        schedulePanelSave()
                    end
                end
            end

            -- Stage 2: Compile
            -- Wrap the compiler call so Luau does not treat the compiler function
            -- itself as the source string argument when inferring pcall's types.
            local compileOk, pluginFunc, compilerMessage = pcall(function()
                return loadstring(pluginCode)
            end)
            if not compileOk or not pluginFunc then
                local err = compileOk
                    and tostring(compilerMessage or "loadstring returned nil without a diagnostic")
                    or tostring(pluginFunc)
                warn("[" .. shortName .. "] Compile error: " .. err)
                loader.ErrorLabel.Text = "Compile error: " .. shortName
                failed = failed + 1
                showPluginDiagnostic(shortName, "compile", err)
                continue
            end

            -- Stage 3: Execute plugin table
            local execOk, plugin = pcall(pluginFunc)
            if not execOk or not plugin then
                warn("[" .. shortName .. "] Execution error: " .. tostring(plugin))
                loader.ErrorLabel.Text = "Execution error: " .. shortName
                failed = failed + 1
                showPluginDiagnostic(shortName, "execution", plugin)
                continue
            end

            if not plugin.Name or not plugin.Init then
                local message = "Plugin must return a table with both Name and Init fields."
                warn("[" .. shortName .. "] " .. message)
                loader.ErrorLabel.Text = "Missing Name/Init: " .. shortName
                failed = failed + 1
                showPluginDiagnostic(shortName, "validation", message)
                continue
            end

            if Plugins[plugin.Name] then
                continue -- already loaded
            end

            -- Stage 4: Init with timeout
            -- Spawn Init in its own task so a hanging or yielding plugin can't block the loader
            local initDone = false
            local initFailed = false
            local initErrMsg = ""

            local initThread = task.spawn(function()
                local pluginAPI = createPluginAPI and createPluginAPI(plugin.Name) or PluginAPI
                local ok, err = pcall(plugin.Init, pluginAPI)
                if ok and pluginAPI.PendingRestores then
                    -- Apply saved toggles only after the plugin has finished creating
                    -- its runtime state, connections and UI.
                    for _, restore in ipairs(pluginAPI.PendingRestores) do
                        restore()
                    end
                    table.clear(pluginAPI.PendingRestores)
                end
                initDone = true
                if not ok then
                    initFailed = true
                    initErrMsg = tostring(err)
                end
            end)

            -- Wait for Init to finish, but give up after INIT_TIMEOUT seconds
            local elapsed = 0
            local step = 0.016
            while not initDone and elapsed < INIT_TIMEOUT do
                task.wait(step)
                elapsed = elapsed + step

                -- Show a live timer so the user sees progress not a freeze
                loader.StatusLabel.Text = string.format(
                    "Loading: %s  (%.1fs)", shortName, elapsed
                )
                if useStartupOverlay then
                    local initProgress = (i - 1 + math.min(elapsed / INIT_TIMEOUT, 0.9)) / total
                    setStartupProgress(
                        0.76 + initProgress * 0.22,
                        string.format("Initializing plugin %d of %d: %s", i, total, shortName),
                        string.format("%d loaded  |  %d skipped  |  %.1fs", loaded, failed, elapsed)
                    )
                end
            end

            if not initDone then
                pcall(task.cancel, initThread)
                cleanupPluginRuntime(plugin.Name, plugin)
                local timeoutMessage = "Init timed out after " .. INIT_TIMEOUT .. " seconds."
                warn("[" .. plugin.Name .. "] " .. timeoutMessage .. " Skipping plugin.")
                loader.ErrorLabel.Text = "Timed out: " .. plugin.Name
                failed = failed + 1
                showPluginDiagnostic(plugin.Name, "initialization", timeoutMessage)
                continue
            end

            if initFailed then
                cleanupPluginRuntime(plugin.Name, plugin)
                warn("[" .. plugin.Name .. "] Init error: " .. initErrMsg)
                loader.ErrorLabel.Text = "Init failed: " .. plugin.Name
                failed = failed + 1
                showPluginDiagnostic(plugin.Name, "initialization", initErrMsg)
                continue
            end

            Plugins[plugin.Name] = plugin
            pluginSourcePaths[plugin.Name] = filePath
            loaded = loaded + 1
            if schedulePanelSave then
                schedulePanelSave()
            end
            print("Loaded plugin: " .. plugin.Name)
        end

        -- Final state
        loader.ProgressBarFill.Size = UDim2.new(1, 0, 1, 0)
        loader.ProgressBarFill.BackgroundColor3 = failed > 0
            and Color3.fromRGB(200, 160, 40)
            or  Color3.fromRGB(50, 200, 100)
        loader.StatusLabel.Text = "Done"
        loader.CountLabel.Text = string.format("Loaded %d / %d  |  %d  |  %d skipped", total, total, loaded, failed)
        loader.ErrorLabel.Text = failed > 0 and (tostring(failed) .. " plugin(s) were skipped") or ""

        updatePluginHub()

        if useStartupOverlay then
            finishStartupLoading(string.format("Loaded %d plugin(s); %d skipped.", loaded, failed))
        else
            -- Auto-dismiss after 2.5 seconds, even if the cleanup handler errors.
            task.delay(2.5, function()
                pcall(loader.Cleanup)
            end)
        end
    end)
end

-- Theme presets keep the original compact layout available alongside the larger
-- classic layout and two modern color treatments.
local ThemePresets = {
    ["Original"] = {
        width = 450, height = 350, headerHeight = 25, sidebarWidth = 112,
        modern = false, font = Enum.Font.Arial, boldFont = Enum.Font.ArialBold,
        colors = {
            Panel = Color3.fromRGB(48, 51, 55), Header = Color3.fromRGB(32, 110, 177),
            TabRail = Color3.fromRGB(42, 46, 51), Content = Color3.fromRGB(57, 60, 64),
            Tab = Color3.fromRGB(66, 70, 75), TabActive = Color3.fromRGB(46, 105, 151),
            Surface = Color3.fromRGB(72, 76, 81), Text = Color3.fromRGB(230, 230, 230),
            MutedText = Color3.fromRGB(200, 200, 200), Primary = Color3.fromRGB(47, 123, 185),
            Secondary = Color3.fromRGB(58, 62, 67), Input = Color3.fromRGB(30, 32, 35),
            Border = Color3.fromRGB(35, 39, 44), Danger = Color3.fromRGB(190, 61, 61),
        },
    },
    ["Original Bigger"] = {
        width = 520, height = 400, headerHeight = 30, sidebarWidth = 126,
        modern = false, font = Enum.Font.Arial, boldFont = Enum.Font.ArialBold,
        colors = {
            Panel = Color3.fromRGB(48, 51, 55), Header = Color3.fromRGB(32, 110, 177),
            TabRail = Color3.fromRGB(42, 46, 51), Content = Color3.fromRGB(57, 60, 64),
            Tab = Color3.fromRGB(66, 70, 75), TabActive = Color3.fromRGB(46, 105, 151),
            Surface = Color3.fromRGB(72, 76, 81), Text = Color3.fromRGB(230, 230, 230),
            MutedText = Color3.fromRGB(200, 200, 200), Primary = Color3.fromRGB(47, 123, 185),
            Secondary = Color3.fromRGB(58, 62, 67), Input = Color3.fromRGB(30, 32, 35),
            Border = Color3.fromRGB(35, 39, 44), Danger = Color3.fromRGB(190, 61, 61),
        },
    },
    ["Modern Small"] = {
        width = 450, height = 350, headerHeight = 34, sidebarWidth = 118,
        modern = true, font = Enum.Font.Gotham, boldFont = Enum.Font.GothamSemibold,
        colors = {
            Panel = Color3.fromRGB(24, 29, 38), Header = Color3.fromRGB(31, 42, 58),
            TabRail = Color3.fromRGB(20, 25, 33), Content = Color3.fromRGB(27, 33, 43),
            Tab = Color3.fromRGB(36, 44, 57), TabActive = Color3.fromRGB(48, 101, 158),
            Surface = Color3.fromRGB(37, 46, 60), Text = Color3.fromRGB(238, 243, 250),
            MutedText = Color3.fromRGB(177, 190, 207), Primary = Color3.fromRGB(48, 119, 190),
            Secondary = Color3.fromRGB(43, 54, 70), Input = Color3.fromRGB(17, 22, 30),
            Border = Color3.fromRGB(54, 67, 85), Danger = Color3.fromRGB(169, 66, 72),
        },
    },
    ["Modern Big"] = {
        width = 520, height = 400, headerHeight = 36, sidebarWidth = 132,
        modern = true, font = Enum.Font.Gotham, boldFont = Enum.Font.GothamSemibold,
        colors = {
            Panel = Color3.fromRGB(24, 29, 38), Header = Color3.fromRGB(31, 42, 58),
            TabRail = Color3.fromRGB(20, 25, 33), Content = Color3.fromRGB(27, 33, 43),
            Tab = Color3.fromRGB(36, 44, 57), TabActive = Color3.fromRGB(48, 101, 158),
            Surface = Color3.fromRGB(37, 46, 60), Text = Color3.fromRGB(238, 243, 250),
            MutedText = Color3.fromRGB(177, 190, 207), Primary = Color3.fromRGB(48, 119, 190),
            Secondary = Color3.fromRGB(43, 54, 70), Input = Color3.fromRGB(17, 22, 30),
            Border = Color3.fromRGB(54, 67, 85), Danger = Color3.fromRGB(169, 66, 72),
        },
    },
}
local requestedTheme = loadedConfig and loadedConfig.theme
local activeThemeName = (type(requestedTheme) == "string" and ThemePresets[requestedTheme]) and requestedTheme or "Original"
local activeTheme = ThemePresets[activeThemeName]
local ColorSchemes = {
    ["Blue"] = {},
    ["Ocean"] = {
        Header = Color3.fromRGB(18, 84, 105), TabRail = Color3.fromRGB(19, 31, 38),
        Content = Color3.fromRGB(25, 41, 49), Tab = Color3.fromRGB(36, 57, 66),
        TabActive = Color3.fromRGB(24, 119, 144), Surface = Color3.fromRGB(36, 56, 65),
        Primary = Color3.fromRGB(24, 145, 168), Secondary = Color3.fromRGB(32, 69, 80),
        Input = Color3.fromRGB(16, 27, 32), Border = Color3.fromRGB(38, 80, 91),
    },
    ["Forest"] = {
        Header = Color3.fromRGB(42, 91, 60), TabRail = Color3.fromRGB(25, 37, 30),
        Content = Color3.fromRGB(32, 46, 37), Tab = Color3.fromRGB(45, 63, 50),
        TabActive = Color3.fromRGB(57, 123, 75), Surface = Color3.fromRGB(48, 66, 52),
        Primary = Color3.fromRGB(65, 150, 83), Secondary = Color3.fromRGB(48, 77, 54),
        Input = Color3.fromRGB(19, 29, 22), Border = Color3.fromRGB(62, 91, 66),
    },
    ["Violet"] = {
        Header = Color3.fromRGB(76, 57, 112), TabRail = Color3.fromRGB(34, 29, 43),
        Content = Color3.fromRGB(44, 37, 55), Tab = Color3.fromRGB(58, 49, 72),
        TabActive = Color3.fromRGB(105, 75, 154), Surface = Color3.fromRGB(62, 52, 77),
        Primary = Color3.fromRGB(127, 83, 190), Secondary = Color3.fromRGB(70, 57, 89),
        Input = Color3.fromRGB(24, 20, 31), Border = Color3.fromRGB(83, 68, 103),
    },
    ["Ember"] = {
        Header = Color3.fromRGB(130, 74, 39), TabRail = Color3.fromRGB(43, 33, 28),
        Content = Color3.fromRGB(54, 42, 34), Tab = Color3.fromRGB(72, 55, 43),
        TabActive = Color3.fromRGB(157, 89, 43), Surface = Color3.fromRGB(77, 59, 45),
        Primary = Color3.fromRGB(196, 111, 48), Secondary = Color3.fromRGB(88, 63, 43),
        Input = Color3.fromRGB(31, 23, 18), Border = Color3.fromRGB(107, 75, 50),
    },
}
local requestedColorScheme = loadedConfig and loadedConfig.colorScheme
local activeColorSchemeName = (type(requestedColorScheme) == "string" and ColorSchemes[requestedColorScheme]) and requestedColorScheme or "Blue"
local activeColors: ThemePalette = {}
local function buildActiveColors(theme: any): ThemePalette
    local palette: ThemePalette = {}
    for key, color in pairs(theme.colors) do
        palette[key] = color
    end
    for key, color in pairs(ColorSchemes[activeColorSchemeName] or {}) do
        palette[key] = color
    end
    return palette
end
activeColors = buildActiveColors(activeTheme)
local themeObjects = setmetatable({}, {__mode = "k"})
local themeGradients = {}
local lastSavedConfigJson = nil
local saveRequestId = 0

local function savePanelConfig(force)
    if not writefile then
        return false
    end

    local config = {
        version = 1,
        theme = activeThemeName,
        colorScheme = activeColorSchemeName,
        settings = copySerializable(Settings),
    }
    local encodeOk, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    if not encodeOk then
        warn("Could not encode panel settings: " .. tostring(encoded))
        return false
    end
    if not force and encoded == lastSavedConfigJson then
        return true
    end

    local writeOk, writeErr = pcall(function()
        if not isfolder(PLUGIN_DATA_FOLDER) then
            makefolder(PLUGIN_DATA_FOLDER)
        end
        writefile(CONFIG_FILE, encoded)
    end)
    if not writeOk then
        warn("Could not save panel settings: " .. tostring(writeErr))
        return false
    end

    lastSavedConfigJson = encoded
    return true
end

schedulePanelSave = function()
    saveRequestId = saveRequestId + 1
    local requestId = saveRequestId
    task.delay(0.4, function()
        if requestId == saveRequestId and ScreenGui.Parent then
            savePanelConfig()
        end
    end)
end

local function styleThemeObject(object, role)
    local palette = activeColors
    local color = palette[role]
    if role == "Toggle" then
        color = object.Text == "ON" and palette.Primary or palette.Danger
    end
    if color then
        if object:IsA("GuiObject") and role ~= "Text" and role ~= "MutedText" then
            object.BackgroundColor3 = color
        end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            if role == "Text" or role == "MutedText" then
                object.TextColor3 = color
            end
            if role == "Primary" or role == "Secondary" or role == "Danger" or role == "Tab" or role == "Toggle" then
                object.TextColor3 = palette.Text
            end
            if not object:IsA("TextBox") then
                object.Font = (role == "Text" or role == "MutedText" or role == "Tab") and activeTheme.font or activeTheme.boldFont
            end
        end
        if object:IsA("GuiObject") and role ~= "Text" and role ~= "MutedText" then
            object.BorderColor3 = palette.Border
        end
    end

    if object:IsA("GuiObject") and role ~= "Text" and role ~= "MutedText" then
        local corner = object:FindFirstChild("ThemeCorner")
        if activeTheme.modern then
            if not corner then
                corner = Instance.new("UICorner")
                corner.Name = "ThemeCorner"
                corner.CornerRadius = UDim.new(0, 5)
                corner.Parent = object
            end
        elseif corner then
            corner:Destroy()
        end
    end
end

registerThemeObject = function(object, role)
    themeObjects[object] = role
    styleThemeObject(object, role)
    return object
end

refreshThemeGradients = function()
    for index = #themeGradients, 1, -1 do
        local gradient = themeGradients[index]
        if not gradient or not gradient.Parent then
            table.remove(themeGradients, index)
        else
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activeColors.Header:Lerp(activeColors.Primary, activeTheme.modern and 0.45 or 0.28)),
                ColorSequenceKeypoint.new(1, activeColors.Header),
            })
        end
    end
end

registerThemeGradient = function(gradient)
    table.insert(themeGradients, gradient)
    refreshThemeGradients()
    return gradient
end

pruneThemeObjects = function(roots)
    local function belongsToRoot(object)
        for _, root in ipairs(roots) do
            local current = object
            while current do
                if current == root then
                    return true
                end
                current = current.Parent
            end
        end
        return false
    end

    for object in pairs(themeObjects) do
        if not object.Parent or belongsToRoot(object) then
            themeObjects[object] = nil
        end
    end
    for index = #settingsRefreshers, 1, -1 do
        local owner = settingsRefreshers[index].owner
        if not owner or not owner.Parent or belongsToRoot(owner) then
            table.remove(settingsRefreshers, index)
        end
    end
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 400)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(48, 51, 55)
MainFrame.BorderColor3 = Color3.fromRGB(22, 35, 48)
MainFrame.BorderSizePixel = 2
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
registerThemeObject(MainFrame, "Panel")

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(32, 110, 177)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
registerThemeObject(TopBar, "Header")

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 137, 205)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 77, 139))
})
TopGradient.Rotation = 90
TopGradient.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -68, 1, 0)
Title.Position = UDim2.new(0, 9, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Simba's Control Panel Reborn"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.ArialBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar
registerThemeObject(Title, "Text")
Title.Font = activeTheme.boldFont

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 22)
MinimizeBtn.Position = UDim2.new(1, -53, 0, 4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(77, 117, 153)
MinimizeBtn.BorderColor3 = Color3.fromRGB(42, 76, 108)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(230, 236, 245)
MinimizeBtn.TextSize = 12
MinimizeBtn.Font = Enum.Font.ArialBold
MinimizeBtn.Parent = TopBar
registerThemeObject(MinimizeBtn, "Secondary")

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 22)
CloseBtn.Position = UDim2.new(1, -27, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 61, 61)
CloseBtn.BorderColor3 = Color3.fromRGB(121, 35, 35)
CloseBtn.BorderSizePixel = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 245, 245)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.ArialBold
CloseBtn.Parent = TopBar
registerThemeObject(CloseBtn, "Danger")

-- Tab bar (ScrollingFrame so tabs don't overflow off-screen when many plugins are loaded)
local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(0, 126, 1, -30)
TabBar.Position = UDim2.new(0, 0, 0, 30)
TabBar.BackgroundColor3 = Color3.fromRGB(42, 46, 51)
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 4
TabBar.ScrollBarImageColor3 = Color3.fromRGB(89, 138, 177)
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.Parent = MainFrame
registerThemeObject(TabBar, "TabRail")

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 2)
TabLayout.Parent = TabBar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 3)
TabPadding.PaddingLeft = UDim.new(0, 6)
TabPadding.PaddingRight = UDim.new(0, 6)
TabPadding.Parent = TabBar

-- Sidebar search. The search field stays outside the scrolling tab list.
local SidebarSearch = Instance.new("TextBox")
SidebarSearch.Name = "PluginSearch"
SidebarSearch.Size = UDim2.new(0, 114, 0, 24)
SidebarSearch.Position = UDim2.new(0, 6, 0, 35)
SidebarSearch.BackgroundColor3 = Color3.fromRGB(31, 35, 41)
SidebarSearch.BorderColor3 = Color3.fromRGB(84, 99, 115)
SidebarSearch.BorderSizePixel = 1
SidebarSearch.TextColor3 = Color3.fromRGB(245, 245, 245)
SidebarSearch.PlaceholderColor3 = Color3.fromRGB(160, 169, 181)
SidebarSearch.PlaceholderText = "Search..."
SidebarSearch.Text = ""
SidebarSearch.ClearTextOnFocus = false
SidebarSearch.TextSize = 12
SidebarSearch.Font = Enum.Font.Arial
SidebarSearch.ZIndex = 8
SidebarSearch.Parent = MainFrame
registerThemeObject(SidebarSearch, "Input")
TabBar.Position = UDim2.new(0, 0, 0, 90)
TabBar.Size = UDim2.new(0, 126, 1, -90)

-- Auto-resize the tab bar canvas when tabs are added/removed
TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabBar.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
end)

-- Content area
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -136, 1, -40)
ContentFrame.Position = UDim2.new(0, 132, 0, 34)
ContentFrame.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
ContentFrame.BorderColor3 = Color3.fromRGB(35, 39, 44)
ContentFrame.BorderSizePixel = 1
ContentFrame.ScrollBarThickness = 6
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(96, 132, 164)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = MainFrame
registerThemeObject(ContentFrame, "Content")

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = ContentFrame

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 6)
ContentPadding.PaddingLeft = UDim.new(0, 6)
ContentPadding.PaddingRight = UDim.new(0, 6)
ContentPadding.Parent = ContentFrame

setStartupProgress(0.3, "Building the main window...", "Creating tabs and content areas")
task.wait()

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end)

local currentTab = nil
local tabs = {}
local favoritePlugins = type(Settings.FavoritePlugins) == "table" and Settings.FavoritePlugins or {}
Settings.FavoritePlugins = favoritePlugins
local refreshFavoriteWidgets
local refreshPluginSearch
local openPluginContextMenu
local selectPanelTab
local pluginContextOverlay
local pluginFolders = type(Settings.PluginFolders) == "table" and Settings.PluginFolders or {}
local pluginFolderAssignments = type(Settings.PluginFolderAssignments) == "table" and Settings.PluginFolderAssignments or {}
Settings.PluginFolders = pluginFolders
Settings.PluginFolderAssignments = pluginFolderAssignments
local currentFolder = nil
local refreshFolderNavigation
local showCreateFolderDialog
local folderButton
local loadstringsButton
local executorButton
local folderBackButton
local folderHeading
local folderContextMenu
local reservedTabs = {Plugins = true, Settings = true, Favorites = true}

local isMinimized = false
local function applyTheme(themeName)
    local selectedTheme = ThemePresets[themeName]
    if not selectedTheme then
        return
    end

    pruneThemeObjects({})
    activeThemeName = themeName
    activeTheme = selectedTheme
    activeColors = buildActiveColors(selectedTheme)
    local headerHeight = selectedTheme.headerHeight
    local panelHeight = isMinimized and headerHeight or selectedTheme.height
    MainFrame.Size = UDim2.new(0, selectedTheme.width, 0, panelHeight)
    MainFrame.Position = UDim2.new(0.5, -selectedTheme.width / 2, 0.5, -panelHeight / 2)
    TopBar.Size = UDim2.new(1, 0, 0, headerHeight)
    Title.Font = selectedTheme.boldFont
    Title.TextSize = selectedTheme.modern and 13 or 14
    MinimizeBtn.Size = UDim2.new(0, 24, 0, 22)
    MinimizeBtn.Position = UDim2.new(1, -53, 0, math.floor((headerHeight - 22) / 2))
    CloseBtn.Size = UDim2.new(0, 24, 0, 22)
    CloseBtn.Position = UDim2.new(1, -27, 0, math.floor((headerHeight - 22) / 2))
    TabBar.Size = UDim2.new(0, selectedTheme.sidebarWidth, 1, -(headerHeight + 60))
    TabBar.Position = UDim2.new(0, 0, 0, headerHeight + 60)
    SidebarSearch.Position = UDim2.new(0, 6, 0, headerHeight + 5)
    SidebarSearch.Size = UDim2.new(0, selectedTheme.sidebarWidth - 12, 0, 24)
    if folderButton then folderButton.Position = UDim2.fromOffset(selectedTheme.sidebarWidth - 29, headerHeight + 32) end
    if loadstringsButton then loadstringsButton.Position = UDim2.fromOffset(6, headerHeight + 32) end
    if folderBackButton then folderBackButton.Position = UDim2.fromOffset(31, headerHeight + 32) end
    if folderHeading then folderHeading.Position = UDim2.fromOffset(folderBackButton and folderBackButton.Visible and 35 or 8, headerHeight + 34); folderHeading.Size = UDim2.new(0, math.max(0, selectedTheme.sidebarWidth - (folderBackButton and folderBackButton.Visible and 69 or 42)), 0, 19) end
    ContentFrame.Size = UDim2.new(1, -(selectedTheme.sidebarWidth + 10), 1, -(headerHeight + 10))
    ContentFrame.Position = UDim2.new(0, selectedTheme.sidebarWidth + 6, 0, headerHeight + 4)
    TabLayout.Padding = UDim.new(0, selectedTheme.modern and 3 or 2)
    ContentLayout.Padding = UDim.new(0, selectedTheme.modern and 8 or 6)
    ContentPadding.PaddingTop = UDim.new(0, selectedTheme.modern and 8 or 6)
    ContentPadding.PaddingLeft = UDim.new(0, selectedTheme.modern and 8 or 6)
    ContentPadding.PaddingRight = UDim.new(0, selectedTheme.modern and 8 or 6)
    TopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, activeColors.Header:Lerp(activeColors.Primary, selectedTheme.modern and 0.45 or 0.28)),
        ColorSequenceKeypoint.new(1, activeColors.Header),
    })
    for _, object in ipairs(ScreenGui:GetDescendants()) do
        if object:IsA("ScrollingFrame") then
            object.ScrollBarImageColor3 = activeColors.Primary:Lerp(activeColors.Text, 0.18)
        end
    end

    for object, role in pairs(themeObjects) do
        if object.Parent then
            styleThemeObject(object, role)
        end
    end
    refreshThemeGradients()
    Title.Font = selectedTheme.boldFont

    for name, tab in pairs(tabs) do
        tab.button.BackgroundColor3 = (currentTab == name) and activeColors.TabActive or activeColors.Tab
        tab.button.TextColor3 = activeColors.Text
        tab.button.Font = selectedTheme.font
    end
    schedulePanelSave()
end

local function applyColorScheme(schemeName)
    if not ColorSchemes[schemeName] then
        return
    end

    pruneThemeObjects({})
    activeColorSchemeName = schemeName
    activeColors = buildActiveColors(activeTheme)
    TopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, activeColors.Header:Lerp(activeColors.Primary, activeTheme.modern and 0.45 or 0.28)),
        ColorSequenceKeypoint.new(1, activeColors.Header),
    })
    for _, object in ipairs(ScreenGui:GetDescendants()) do
        if object:IsA("ScrollingFrame") then
            object.ScrollBarImageColor3 = activeColors.Primary:Lerp(activeColors.Text, 0.18)
        end
    end

    for object, role in pairs(themeObjects) do
        if object.Parent then
            styleThemeObject(object, role)
        end
    end
    refreshThemeGradients()
    Title.Font = activeTheme.boldFont

    for name, tab in pairs(tabs) do
        tab.button.BackgroundColor3 = (currentTab == name) and activeColors.TabActive or activeColors.Tab
        tab.button.TextColor3 = activeColors.Text
    end
    schedulePanelSave()
end

local function loadPanelConfig()
    local config = readPanelConfig()
    if not config then
        return false, "No readable settings file was found."
    end

    if type(config.settings) == "table" then
        mergeSavedSettings(Settings, config.settings)
    end

    local savedTheme = config.theme
    if type(savedTheme) == "string" and ThemePresets[savedTheme] then
        applyTheme(savedTheme)
    end
    local savedColorScheme = config.colorScheme
    if type(savedColorScheme) == "string" and ColorSchemes[savedColorScheme] then
        applyColorScheme(savedColorScheme)
    end

    for index = #settingsRefreshers, 1, -1 do
        local refresher = settingsRefreshers[index]
        if not refresher.owner or not refresher.owner.Parent then
            table.remove(settingsRefreshers, index)
        elseif refresher.refresh then
            pcall(refresher.refresh)
        end
    end
    return true
end

-- Manual canvas update function (fallback for when auto-update fails)
local function updateCanvasSize()
    task.spawn(function()
        task.wait(0.05)
        if ContentLayout and ContentFrame then
            local newSize = ContentLayout.AbsoluteContentSize.Y + 20
            ContentFrame.CanvasSize = UDim2.new(0, 0, 0, newSize)
        end
    end)
end

-- Tab system

local function createTab(name, icon)
    if tabs[name] then
        return tabs[name].button
    end
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 27)
    TabButton.BackgroundColor3 = Color3.fromRGB(66, 70, 75)
    TabButton.BorderColor3 = Color3.fromRGB(38, 42, 47)
    TabButton.BorderSizePixel = 1
    TabButton.Text = icon and icon ~= "" and (icon .. "  " .. name) or name
    TabButton.TextColor3 = Color3.fromRGB(222, 222, 222)
    TabButton.TextSize = 12
    TabButton.Font = Enum.Font.Arial
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.AutoButtonColor = false
    TabButton.Parent = TabBar
    registerThemeObject(TabButton, "Tab")
    TabButton.Font = activeTheme.font

    local TabButtonPadding = Instance.new("UIPadding")
    TabButtonPadding.PaddingLeft = UDim.new(0, 11)
    TabButtonPadding.Parent = TabButton
    
    tabs[name] = {button = TabButton, widgets = {}}
    
    TabButton.MouseButton1Click:Connect(function()
        selectPanelTab(name)
    end)
    TabButton.MouseButton2Click:Connect(function()
        if not reservedTabs[name] and openPluginContextMenu then
            openPluginContextMenu(name)
        end
    end)

    TabButton.MouseEnter:Connect(function()
        if currentTab ~= name then
            TabButton.BackgroundColor3 = activeColors.Surface
        end
    end)

    TabButton.MouseLeave:Connect(function()
        if currentTab ~= name then
            TabButton.BackgroundColor3 = activeColors.Tab
        end
    end)
    if refreshFavoriteWidgets and name ~= "Favorites" and name ~= "Loadstrings" and name ~= "Executor" then task.defer(refreshFavoriteWidgets) end
    if refreshPluginSearch then task.defer(refreshPluginSearch) end
    if refreshFolderNavigation then task.defer(refreshFolderNavigation) end
    return TabButton
end

-- Central tab navigation, favorites, and search. Keep plugin widgets in their original tabs.
selectPanelTab = function(name)
    if not tabs[name] then return end
    if not reservedTabs[name] and pluginFolderAssignments[name] and pluginFolders[pluginFolderAssignments[name]] then
        currentFolder = pluginFolderAssignments[name]
    end
    if refreshFolderNavigation then refreshFolderNavigation() end
    for tabName, tab in pairs(tabs) do
        tab.button.BackgroundColor3 = (tabName == name) and activeColors.TabActive or activeColors.Tab
        tab.button.TextColor3 = (tabName == name) and Color3.fromRGB(255,255,255) or activeColors.Text
        for _, widget in ipairs(tab.widgets) do
            if widget and widget.Parent then widget.Visible = tabName == name end
        end
    end
    currentTab = name
    ContentFrame.CanvasPosition = Vector2.new(0,0)
end

refreshFavoriteWidgets = function()
    local favTab = tabs["Favorites"]
    if not favTab then return end
    for _, widget in ipairs(favTab.widgets) do
        if widget and widget.Parent then widget:Destroy() end
    end
    table.clear(favTab.widgets)
    local names = {}
    for name, enabled in pairs(favoritePlugins) do
        if enabled and tabs[name] then table.insert(names, name) end
    end
    table.sort(names)
    if #names == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,0,0,56)
        empty.BackgroundTransparency = 1
        empty.Text = "No favorites yet.\nRight-click a plugin tab to add one."
        empty.TextWrapped = true
        empty.TextColor3 = activeColors.Text
        empty.TextSize = 12
        empty.Parent = ContentFrame
        table.insert(favTab.widgets, empty)
    else
        for _, name in ipairs(names) do
            local shortcut = Instance.new("TextButton")
            shortcut.Size = UDim2.new(1,0,0,34)
            shortcut.BackgroundColor3 = activeColors.Surface
            shortcut.BorderColor3 = activeColors.Primary
            shortcut.TextColor3 = activeColors.Text
            shortcut.TextSize = 12
            shortcut.Font = activeTheme.font
            shortcut.Text = "★  " .. name .. "    ›"
            shortcut.Parent = ContentFrame
            shortcut.MouseButton1Click:Connect(function()
                selectPanelTab(name)
            end)
            shortcut.MouseButton2Click:Connect(function()
                openPluginContextMenu(name)
            end)
            table.insert(favTab.widgets, shortcut)
        end
    end
    for _, widget in ipairs(favTab.widgets) do widget.Visible = currentTab == "Favorites" end
end

openPluginContextMenu = function(name)
    if not tabs[name] or name == "Favorites" or name == "Settings" or name == "Plugins" then return end
    if pluginContextOverlay and pluginContextOverlay.Parent then pluginContextOverlay:Destroy() end

    local cover = Instance.new("TextButton")
    cover.Name = "PluginContextDismiss"
    cover.Text = ""
    cover.AutoButtonColor = false
    cover.BackgroundTransparency = 1
    cover.BorderSizePixel = 0
    cover.Size = UDim2.fromScale(1, 1)
    cover.ZIndex = 19000
    cover.Parent = MainFrame
    pluginContextOverlay = cover

    local menuWidth, menuHeight = 190, 154
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    local mouse = UserInputService:GetMouseLocation() - guiInset
    local relative = mouse - MainFrame.AbsolutePosition
    local menu = Instance.new("Frame")
    menu.Name = "PluginContextMenu"
    menu.Size = UDim2.fromOffset(menuWidth, menuHeight)
    menu.Position = UDim2.fromOffset(
        math.clamp(relative.X, 0, math.max(0, MainFrame.AbsoluteSize.X - menuWidth)),
        math.clamp(relative.Y, 0, math.max(0, MainFrame.AbsoluteSize.Y - menuHeight))
    )
    menu.BackgroundColor3 = activeColors.Surface
    menu.BorderColor3 = activeColors.Border or activeColors.Primary
    menu.BorderSizePixel = 1
    menu.ZIndex = 19001
    menu.Parent = cover
    registerThemeObject(menu, "Surface")

    local heading = Instance.new("TextLabel")
    heading.Name = "PluginName"
    heading.Size = UDim2.new(1, -16, 0, 22)
    heading.Position = UDim2.fromOffset(8, 3)
    heading.BackgroundTransparency = 1
    heading.Font = activeTheme.font
    heading.Text = name
    heading.TextTruncate = Enum.TextTruncate.AtEnd
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.TextColor3 = activeColors.Text
    heading.TextSize = 11
    heading.ZIndex = 19002
    heading.Parent = menu
    registerThemeObject(heading, "Text")

    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -12, 0, 1)
    separator.Position = UDim2.fromOffset(6, 26)
    separator.BorderSizePixel = 0
    separator.BackgroundColor3 = activeColors.Primary
    separator.BackgroundTransparency = 0.55
    separator.ZIndex = 19002
    separator.Parent = menu
    registerThemeObject(separator, "Primary")

    local action = Instance.new("TextButton")
    action.Name = "ToggleFavorite"
    action.Size = UDim2.new(1, -12, 0, 27)
    action.Position = UDim2.fromOffset(6, 30)
    action.BackgroundColor3 = activeColors.Tab
    action.BorderSizePixel = 0
    action.AutoButtonColor = false
    action.Font = activeTheme.font
    action.TextXAlignment = Enum.TextXAlignment.Left
    action.TextColor3 = activeColors.Text
    action.TextSize = 11
    action.Text = favoritePlugins[name] and "  ★  Remove favorite" or "  ☆  Add to favorites"
    action.ZIndex = 19002
    action.Parent = menu
    registerThemeObject(action, "Tab")
    action.MouseEnter:Connect(function()
        action.BackgroundColor3 = activeColors.TabActive
    end)
    action.MouseLeave:Connect(function()
        action.BackgroundColor3 = activeColors.Tab
    end)

    cover.MouseButton1Click:Connect(function()
        if cover.Parent then cover:Destroy() end
    end)
    action.MouseButton1Click:Connect(function()
        if favoritePlugins[name] then
            favoritePlugins[name] = nil
        else
            favoritePlugins[name] = true
        end
        schedulePanelSave()
        refreshFavoriteWidgets()
        if cover.Parent then cover:Destroy() end
        createNotification("Favorites", name .. (favoritePlugins[name] and " added" or " removed"), 2, "info")
    end)

    local moveButton = Instance.new("TextButton")
    moveButton.Name = "MoveToFolder"
    moveButton.Size = UDim2.new(1, -12, 0, 27)
    moveButton.Position = UDim2.fromOffset(6, 60)
    moveButton.BackgroundColor3 = activeColors.Tab
    moveButton.BorderSizePixel = 0
    moveButton.AutoButtonColor = false
    moveButton.Font = activeTheme.font
    moveButton.TextXAlignment = Enum.TextXAlignment.Left
    moveButton.TextColor3 = activeColors.Text
    moveButton.TextSize = 11
    moveButton.Text = "  Move to folder  >"
    moveButton.ZIndex = 19002
    moveButton.Parent = menu
    registerThemeObject(moveButton, "Tab")
    moveButton.MouseEnter:Connect(function() moveButton.BackgroundColor3 = activeColors.TabActive end)
    moveButton.MouseLeave:Connect(function() moveButton.BackgroundColor3 = activeColors.Tab end)
    moveButton.MouseButton1Click:Connect(function()
        local folderNames = {}
        for folderName, enabled in pairs(pluginFolders) do
            if enabled then table.insert(folderNames, folderName) end
        end
        table.sort(folderNames)
        local entries = {"Main area"}
        for _, folderName in ipairs(folderNames) do table.insert(entries, folderName) end
        local rowHeight = 27
        local sub = Instance.new("Frame")
        sub.Name = "FolderChoices"
        sub.Size = UDim2.fromOffset(190, #entries * rowHeight + 8)
        local x = menu.Position.X.Offset + menuWidth
        if x + 190 > MainFrame.AbsoluteSize.X then x = menu.Position.X.Offset - 190 end
        sub.Position = UDim2.fromOffset(math.max(0, x), math.clamp(menu.Position.Y.Offset + 40, 0, math.max(0, MainFrame.AbsoluteSize.Y - sub.Size.Y.Offset)))
        sub.BackgroundColor3 = activeColors.Surface
        sub.BorderColor3 = activeColors.Border or activeColors.Primary
        sub.BorderSizePixel = 1
        sub.ZIndex = 19005
        sub.Parent = cover
        registerThemeObject(sub, "Surface")
        for index, folderName in ipairs(entries) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, -8, 0, rowHeight - 2)
            option.Position = UDim2.fromOffset(4, 4 + (index - 1) * rowHeight)
            option.BackgroundColor3 = activeColors.Tab
            option.BorderSizePixel = 0
            option.Font = activeTheme.font
            option.TextSize = 11
            option.TextColor3 = activeColors.Text
            option.Text = folderName
            option.ZIndex = 19006
            option.Parent = sub
            registerThemeObject(option, "Tab")
            option.MouseButton1Click:Connect(function()
                pluginFolderAssignments[name] = folderName == "Main area" and nil or folderName
                schedulePanelSave()
                if cover.Parent then cover:Destroy() end
                if refreshFolderNavigation then refreshFolderNavigation() end
                createNotification("Folders", name .. " moved to " .. folderName, 2, "success")
            end)
        end
    end)

    local reloadButton = Instance.new("TextButton")
    reloadButton.Name = "ReloadPlugin"
    reloadButton.Size = UDim2.new(1, -12, 0, 27)
    reloadButton.Position = UDim2.fromOffset(6, 90)
    reloadButton.BackgroundColor3 = activeColors.Tab
    reloadButton.BorderSizePixel = 0
    reloadButton.AutoButtonColor = false
    reloadButton.Font = activeTheme.font
    reloadButton.TextXAlignment = Enum.TextXAlignment.Left
    reloadButton.TextColor3 = activeColors.Text
    reloadButton.TextSize = 11
    reloadButton.Text = "  Reload plugin"
    reloadButton.ZIndex = 19002
    reloadButton.Parent = menu
    registerThemeObject(reloadButton, "Tab")
    reloadButton.MouseEnter:Connect(function() reloadButton.BackgroundColor3 = activeColors.TabActive end)
    reloadButton.MouseLeave:Connect(function() reloadButton.BackgroundColor3 = activeColors.Tab end)
    reloadButton.MouseButton1Click:Connect(function()
        if cover.Parent then cover:Destroy() end
        local filePath = pluginSourcePaths[name]
        if not filePath or not isfile or not isfile(filePath) then
            createNotification("Reload plugin", "Saved plugin file not found: " .. name, 4, "error")
            return
        end
        -- Cleanup calls plugin.Cleanup and releases resources registered with its scoped API.
        -- Arbitrary side effects outside that API cannot be forcibly reversed by Luau.
        cleanupPluginRuntime(name, Plugins[name])
        createNotification("Reload plugin", "Reloading " .. name .. " from disk...", 2, "info")
        loadPlugins(false, filePath)
    end)

    local deleteButton = Instance.new("TextButton")
    deleteButton.Name = "DeletePlugin"
    deleteButton.Size = UDim2.new(1, -12, 0, 27)
    deleteButton.Position = UDim2.fromOffset(6, 120)
    deleteButton.BackgroundColor3 = activeColors.Tab
    deleteButton.BorderSizePixel = 0
    deleteButton.AutoButtonColor = false
    deleteButton.Font = activeTheme.font
    deleteButton.TextXAlignment = Enum.TextXAlignment.Left
    deleteButton.TextColor3 = activeColors.Danger or Color3.fromRGB(230, 100, 100)
    deleteButton.TextSize = 11
    deleteButton.Text = "  Delete plugin..."
    deleteButton.ZIndex = 19002
    deleteButton.Parent = menu
    registerThemeObject(deleteButton, "Tab")
    deleteButton.MouseEnter:Connect(function() deleteButton.BackgroundColor3 = activeColors.TabActive end)
    deleteButton.MouseLeave:Connect(function() deleteButton.BackgroundColor3 = activeColors.Tab end)
    deleteButton.MouseButton1Click:Connect(function()
        if cover.Parent then cover:Destroy() end
        task.spawn(function()
            local decision = createPluginDecisionDialog(
                "Delete plugin?",
                name,
                "This removes the plugin's Lua file from your executor's plugin folder and unloads it from the panel. This cannot be undone.",
                {
                    {label = "Cancel", value = "cancel", color = Color3.fromRGB(75, 83, 92)},
                    {label = "Delete", value = "delete", color = Color3.fromRGB(170, 55, 55)},
                }
            )
            if decision ~= "delete" then return end
            local filePath = pluginSourcePaths[name]
            if not filePath then
                local candidate = PLUGIN_FOLDER .. "/" .. name:gsub("%s+", "_"):lower() .. ".lua"
                if isfile and isfile(candidate) then filePath = candidate end
            end
            if not filePath or not isfile or not isfile(filePath) then
                createNotification("Delete plugin", "Cannot find the source file for " .. name, 4, "error")
                return
            end
            local remover = delfile or deletefile
            if type(remover) ~= "function" then
                createNotification("Delete plugin", "Executor does not support delfile", 4, "error")
                return
            end
            local ok, err = pcall(remover, filePath)
            if not ok then
                createNotification("Delete plugin", "Could not delete file: " .. tostring(err), 4, "error")
                return
            end
            cleanupPluginRuntime(name, Plugins[name])
            pluginSourcePaths[name] = nil
            favoritePlugins[name] = nil
            pluginFolderAssignments[name] = nil
            schedulePanelSave()
            if updatePluginHub then updatePluginHub() end
            if refreshFolderNavigation then refreshFolderNavigation() end
            createNotification("Delete plugin", name .. " deleted", 3, "success")
        end)
    end)
end

-- Folder navigation lives in the sidebar, while the actual plugin widgets stay in their original tabs.
local folderTools = Instance.new("Frame")
folderTools.Name = "FolderTools"
folderTools.BackgroundTransparency = 1
folderTools.Size = UDim2.new(0, 126, 0, 29)
folderTools.Position = UDim2.fromOffset(0, 0)
folderTools.Parent = MainFrame

folderButton = Instance.new("TextButton")
folderButton.Name = "CreateFolder"
folderButton.Size = UDim2.fromOffset(22, 22)
folderButton.Position = UDim2.fromOffset(activeTheme.sidebarWidth - 29, activeTheme.headerHeight + 32)
folderButton.Text = ""
folderButton.BackgroundColor3 = activeColors.Tab
folderButton.BorderColor3 = activeColors.Border or activeColors.Primary
folderButton.Parent = MainFrame
registerThemeObject(folderButton, "Tab")
-- A subtle folder silhouette using Roblox UI primitives; the empty areas stay transparent.
local function updateFolderIconTint()
    local textColor = activeColors.MutedText or activeColors.Text or Color3.fromRGB(185, 180, 175)
    local softColor = textColor:Lerp(activeColors.Tab or Color3.fromRGB(30, 30, 30), 0.18)
    if folderLip then folderLip.BackgroundColor3 = softColor end
    if folderBody then folderBody.BackgroundColor3 = softColor end
end
local folderLip
local folderBody
folderLip = Instance.new("Frame")
folderLip.Size = UDim2.fromOffset(8, 3)
folderLip.Position = UDim2.fromOffset(4, 6)
folderLip.BorderSizePixel = 0
folderLip.BackgroundColor3 = activeColors.MutedText or Color3.fromRGB(175, 170, 165)
folderLip.BackgroundTransparency = 0.18
folderLip.Parent = folderButton
-- Keep the surrounding area fully transparent.
folderBody = Instance.new("Frame")
folderBody.Size = UDim2.fromOffset(15, 10)
folderBody.Position = UDim2.fromOffset(4, 9)
folderBody.BorderSizePixel = 0
folderBody.BackgroundColor3 = activeColors.MutedText or Color3.fromRGB(175, 170, 165)
folderBody.BackgroundTransparency = 0.18
folderBody.Parent = folderButton
-- Keep the surrounding area fully transparent.
local folderCorner = Instance.new("UICorner")
folderCorner.CornerRadius = UDim.new(0, 2)
folderCorner.Parent = folderBody
updateFolderIconTint()

-- Refresh icon tint when a theme or color scheme changes.
task.spawn(function()
    local lastColor
    while folderButton and folderButton.Parent do
        local c = activeColors.MutedText or activeColors.Text
        if c ~= lastColor then
            lastColor = c
            updateFolderIconTint()
        end
        task.wait(0.5)
    end
end)

folderBackButton = Instance.new("TextButton")
folderBackButton.Name = "FolderBack"
folderBackButton.Position = UDim2.fromOffset(31, activeTheme.headerHeight + 32)
folderBackButton.Size = UDim2.fromOffset(22, 22)
folderBackButton.Text = "<"
folderBackButton.TextSize = 15
folderBackButton.Font = activeTheme.boldFont
folderBackButton.BackgroundColor3 = activeColors.Tab
folderBackButton.TextColor3 = activeColors.Text
folderBackButton.Parent = MainFrame
registerThemeObject(folderBackButton, "Tab")
folderHeading = Instance.new("TextLabel")
folderHeading.Name = "FolderPath"
folderHeading.Position = UDim2.fromOffset(8, activeTheme.headerHeight + 34)
folderHeading.Size = UDim2.new(0, math.max(0, activeTheme.sidebarWidth - 42), 0, 19)
folderHeading.BackgroundTransparency = 1
folderHeading.TextColor3 = activeColors.Text
folderHeading.Font = activeTheme.font
folderHeading.TextSize = 11
folderHeading.TextTruncate = Enum.TextTruncate.AtEnd
folderHeading.TextXAlignment = Enum.TextXAlignment.Left
folderHeading.Parent = MainFrame
registerThemeObject(folderHeading, "Text")

local folderRows = {}
local function clearFolderRows()
    for _, row in ipairs(folderRows) do if row.Parent then row:Destroy() end end
    table.clear(folderRows)
end
local function createFolderRow(name)
    local row = Instance.new("TextButton")
    row.Name = "Folder_" .. name
    row.Size = UDim2.new(1, 0, 0, 27)
    row.Text = "  " .. name .. "  >"
    row.TextSize = 12
    row.Font = activeTheme.font
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextColor3 = activeColors.Text
    row.BackgroundColor3 = activeColors.Tab
    row.BorderColor3 = activeColors.Border or activeColors.Primary
    row.Parent = TabBar
    registerThemeObject(row, "Tab")
    table.insert(folderRows, row)
    row.MouseButton1Click:Connect(function()
        currentFolder = name
        refreshFolderNavigation()
    end)
    row.MouseButton2Click:Connect(function()
        if pluginContextOverlay and pluginContextOverlay.Parent then pluginContextOverlay:Destroy() end
        local cover = Instance.new("TextButton")
        cover.Name = "FolderContextDismiss"
        cover.Size = UDim2.fromScale(1,1)
        cover.BackgroundTransparency = 1
        cover.Text = ""
        cover.ZIndex = 19000
        cover.Parent = MainFrame
        pluginContextOverlay = cover
        local mouse = UserInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
        local pos = mouse - MainFrame.AbsolutePosition
        local menu = Instance.new("TextButton")
        menu.Size = UDim2.fromOffset(165, 28)
        menu.Position = UDim2.fromOffset(math.clamp(pos.X,0,math.max(0,MainFrame.AbsoluteSize.X-165)),math.clamp(pos.Y,0,math.max(0,MainFrame.AbsoluteSize.Y-28)))
        menu.Text = "Delete empty folder"
        menu.Font = activeTheme.font
        menu.TextSize = 11
        menu.TextColor3 = activeColors.Text
        menu.BackgroundColor3 = activeColors.Tab
        menu.ZIndex = 19001
        menu.Parent = cover
        registerThemeObject(menu,"Tab")
        cover.MouseButton1Click:Connect(function() cover:Destroy() end)
        menu.MouseButton1Click:Connect(function()
            for pluginName, folderName in pairs(pluginFolderAssignments) do
                if folderName == name and tabs[pluginName] then
                    createNotification("Folders", "Move plugins out before deleting this folder", 3, "warning")
                    cover:Destroy()
                    return
                end
            end
            pluginFolders[name] = nil
            if currentFolder == name then currentFolder = nil end
            schedulePanelSave()
            cover:Destroy()
            refreshFolderNavigation()
        end)
    end)
end

refreshFolderNavigation = function()
    if currentFolder and not pluginFolders[currentFolder] then currentFolder = nil end
    clearFolderRows()
    local names = {}
    if not currentFolder then
        for name, exists in pairs(pluginFolders) do if exists then table.insert(names, name) end end
        table.sort(names)
        for _, name in ipairs(names) do createFolderRow(name) end
    end
    local query = SidebarSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    for name, tab in pairs(tabs) do
        local assigned = pluginFolderAssignments[name]
        if assigned and not pluginFolders[assigned] then assigned = nil end
        local inFolder = reservedTabs[name] and currentFolder == nil or (not reservedTabs[name] and assigned == currentFolder)
        local matches = query == "" or name:lower():find(query, 1, true) ~= nil
        if query ~= "" and not matches then
            for _, widget in ipairs(tab.widgets) do
                if widget and widget.Parent then
                    for _, child in ipairs(widget:GetDescendants()) do
                        if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text:lower():find(query,1,true) then matches = true break end
                    end
                end
                if matches then break end
            end
        end
        tab.button.Visible = (name ~= "Loadstrings" and name ~= "Executor" and inFolder and matches)
    end
    for _, row in ipairs(folderRows) do
        row.Visible = query == "" or row.Name:sub(8):lower():find(query,1,true) ~= nil
    end
    folderBackButton.Visible = currentFolder ~= nil
    folderHeading.Text = currentFolder or "Library"
    local headingLeft = currentFolder and 35 or 8
    folderHeading.Position = UDim2.fromOffset(headingLeft, activeTheme.headerHeight + 34)
    folderHeading.Size = UDim2.new(0, math.max(0, activeTheme.sidebarWidth - headingLeft - 34), 0, 19)
    if currentTab and tabs[currentTab] and not tabs[currentTab].button.Visible then
        -- Keep the existing tab's widgets until the user chooses another tab.
    end
end

showCreateFolderDialog = function()
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1,1)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.25
    overlay.ZIndex = 19500
    overlay.Parent = MainFrame
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(230, 118)
    card.Position = UDim2.new(0.5,-115,0.5,-59)
    card.BackgroundColor3 = activeColors.Surface
    card.BorderColor3 = activeColors.Primary
    card.ZIndex = 19501
    card.Parent = overlay
    registerThemeObject(card,"Surface")
    local prompt = Instance.new("TextLabel")
    prompt.Size = UDim2.new(1,-12,0,25)
    prompt.Position = UDim2.fromOffset(6,5)
    prompt.Text = "New plugin folder"
    prompt.TextColor3 = activeColors.Text
    prompt.Font = activeTheme.boldFont
    prompt.TextSize = 12
    prompt.BackgroundTransparency = 1
    prompt.ZIndex = 19502
    prompt.Parent = card
    registerThemeObject(prompt,"Text")
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-16,0,27)
    input.Position = UDim2.fromOffset(8,36)
    input.PlaceholderText = "Folder name"
    input.Text = ""
    input.ClearTextOnFocus = false
    input.TextColor3 = activeColors.Text
    input.BackgroundColor3 = activeColors.Input
    input.Font = activeTheme.font
    input.TextSize = 12
    input.ZIndex = 19502
    input.Parent = card
    registerThemeObject(input,"Input")
    local function button(text, x, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(100,26)
        b.Position = UDim2.fromOffset(x,78)
        b.Text = text
        b.Font = activeTheme.font
        b.TextSize = 12
        b.BackgroundColor3 = activeColors.Tab
        b.TextColor3 = activeColors.Text
        b.ZIndex = 19502
        b.Parent = card
        registerThemeObject(b,"Tab")
        b.MouseButton1Click:Connect(callback)
    end
    button("Cancel",8,function() overlay:Destroy() end)
    local function submit()
        local name = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if #name == 0 or #name > 28 or reservedTabs[name] or pluginFolders[name] or name:find("[/\\]") then
            createNotification("Folders", "Choose a unique folder name (1-28 characters)", 3, "warning")
            return
        end
        pluginFolders[name] = true
        schedulePanelSave()
        overlay:Destroy()
        refreshFolderNavigation()
        createNotification("Folders", "Created " .. name, 2, "success")
    end
    button("Create",122,submit)
    input.FocusLost:Connect(function(enter) if enter then submit() end end)
    input:CaptureFocus()
end
-- Separate Loadstrings shortcut, on the opposite side of the Create Folder button.
loadstringsButton = Instance.new("TextButton")
loadstringsButton.Name = "OpenLoadstrings"
loadstringsButton.Size = UDim2.fromOffset(22, 22)
loadstringsButton.Position = UDim2.fromOffset(6, activeTheme.headerHeight + 32)
loadstringsButton.Text = "<>"
loadstringsButton.TextSize = 11
loadstringsButton.Font = activeTheme.boldFont
loadstringsButton.BackgroundColor3 = activeColors.Tab
loadstringsButton.TextColor3 = activeColors.MutedText or activeColors.Text
loadstringsButton.BorderColor3 = activeColors.Border or activeColors.Primary
loadstringsButton.Parent = MainFrame
loadstringsButton.Visible = false -- Keep internal tab wiring, but hide shortcut until the UI is ready.
registerThemeObject(loadstringsButton, "Tab")
loadstringsButton.MouseButton1Click:Connect(function()
    selectPanelTab("Loadstrings")
end)
local openExecutorWorkspace
folderButton.MouseButton1Click:Connect(showCreateFolderDialog)
folderBackButton.MouseButton1Click:Connect(function()
    currentFolder = nil
    refreshFolderNavigation()
end)
TabBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local hovered = UserInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
        local overTab = false
        for _, child in ipairs(TabBar:GetChildren()) do
            if child:IsA("GuiButton") and child.Visible then
                local p, z = child.AbsolutePosition, child.AbsoluteSize
                if hovered.X >= p.X and hovered.X <= p.X + z.X and hovered.Y >= p.Y and hovered.Y <= p.Y + z.Y then overTab = true break end
            end
        end
        if not overTab then showCreateFolderDialog() end
    end
end)
refreshFolderNavigation()

refreshPluginSearch = function()
    refreshFolderNavigation()
end
SidebarSearch:GetPropertyChangedSignal("Text"):Connect(refreshPluginSearch)

-- Toggle widget (FIXED - properly loads saved state)
-- Shared toggle keybinds (one keyboard listener for the whole panel).
local toggleKeybinds = {}
local pendingToggleBind = nil
local toggleBindCounter = 0
local function attachToggleKeybind(frame, label, toggleButton, storage, path, entryPress)
    if not storage or not path then return end
    local keyPath = {"__PanelKeybinds"}
    for _, part in ipairs(path) do table.insert(keyPath, tostring(part)) end
    local saved = readSettingPath(storage, keyPath)
    local assigned = type(saved) == "string" and Enum.KeyCode[saved] and saved or nil
    -- The panel's persisted binding is authoritative, even when plugins initialize later.
    local function reloadSavedBinding()
        local current = readSettingPath(storage, keyPath)
        local validated = type(current) == "string" and Enum.KeyCode[current] and current or nil
        if assigned ~= validated then
            assigned = validated
            return true
        end
        return false
    end
    local bindButton = Instance.new("TextButton")
    bindButton.Name = "Keybind"
    bindButton.Size = UDim2.fromOffset(43, 18)
    bindButton.Position = UDim2.new(1, -98, 0.5, -9)
    bindButton.BackgroundColor3 = Color3.fromRGB(55, 62, 73)
    bindButton.BorderSizePixel = 0
    bindButton.TextColor3 = Color3.fromRGB(240, 240, 240)
    bindButton.TextSize = 10
    bindButton.Font = Enum.Font.Code
    bindButton.ZIndex = toggleButton.ZIndex
    bindButton.Parent = frame
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearKeybind"
    clearButton.Size = UDim2.fromOffset(17, 18)
    clearButton.Position = UDim2.new(1, -119, 0.5, -9)
    clearButton.BackgroundColor3 = Color3.fromRGB(110, 45, 49)
    clearButton.BorderSizePixel = 0
    clearButton.Text = "X"
    clearButton.TextColor3 = Color3.fromRGB(255, 245, 245)
    clearButton.TextSize = 11
    clearButton.Font = Enum.Font.ArialBold
    clearButton.ZIndex = toggleButton.ZIndex
    clearButton.Parent = frame
    local function refresh()
        bindButton.Text = assigned or "KEY"
        if assigned and #assigned > 6 then bindButton.Text = assigned:sub(1, 5) .. "…" end
    end
    refresh()
    toggleBindCounter += 1
    local entry = {frame = frame, label = tostring(label), key = assigned, reload = function()
        local changed = reloadSavedBinding()
        if changed then refresh() end
        return assigned
    end, activate = function()
        if frame.Parent and toggleButton.Parent then
            -- Use the existing click path so callbacks and persistence remain identical.
            entryPress()
            local state = toggleButton.Text == "ON" and "ON" or "OFF"
            createNotification("Keybind: " .. tostring(label), tostring(label) .. " turned " .. state, 2, state == "ON" and "success" or "info")
        end
    end}
    table.insert(toggleKeybinds, entry)
    -- Reapply after deferred plugin initialization/restoration has completed.
    task.defer(function()
        if frame.Parent then entry.key = entry.reload() end
    end)
    bindButton.MouseButton1Click:Connect(function()
        pendingToggleBind = entry
        bindButton.Text = "..."
    end)
    clearButton.MouseButton1Click:Connect(function()
        if pendingToggleBind == entry then pendingToggleBind = nil end
        assigned = nil
        entry.key = nil
        writeSettingPath(storage, keyPath, nil)
        schedulePanelSave()
        refresh()
        createNotification("Keybind removed", tostring(label) .. ": Unbound", 2, "info")
    end)
    entry.clear = function()
        if pendingToggleBind == entry then pendingToggleBind = nil end
        assigned = nil
        entry.key = nil
        writeSettingPath(storage, keyPath, nil)
        schedulePanelSave()
        refresh()
    end
    entry.capture = function(input)
        if input.KeyCode == Enum.KeyCode.Escape then
            pendingToggleBind = nil
            refresh()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
            assigned = nil
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            assigned = input.KeyCode.Name
        else
            return
        end
        local candidate = assigned
        local conflicts = {}
        if candidate then
            for _, other in ipairs(toggleKeybinds) do
                if other ~= entry and other.frame.Parent and other.reload() == candidate then
                    table.insert(conflicts, other)
                end
            end
        end
        pendingToggleBind = nil
        if #conflicts > 0 then
            -- Do not persist the new key until the user resolves the conflict.
            assigned = type(readSettingPath(storage, keyPath)) == "string" and readSettingPath(storage, keyPath) or nil
            refresh()
            task.spawn(function()
                local labels = {}
                for _, other in ipairs(conflicts) do table.insert(labels, other.label) end
                local choice = createPluginDecisionDialog(
                    "Keybind conflict",
                    candidate .. " is already assigned.",
                    "Used by: " .. table.concat(labels, ", ") .. "\n\nReplace their keybinds or keep the existing assignments?",
                    {{label = "Replace existing", value = "replace"}, {label = "Cancel", value = "cancel", color = Color3.fromRGB(153,54,54)}}
                )
                if choice ~= "replace" or not frame.Parent then return end
                for _, other in ipairs(conflicts) do
                    if other.frame.Parent and other.key == candidate then other.clear() end
                end
                assigned = candidate
                entry.key = assigned
                writeSettingPath(storage, keyPath, assigned)
                schedulePanelSave()
                refresh()
                createNotification("Keybind updated", tostring(label) .. ": " .. assigned, 2, "success")
            end)
            return
        end
        entry.key = assigned
        writeSettingPath(storage, keyPath, assigned)
        schedulePanelSave()
        refresh()
        createNotification("Keybind updated", tostring(label) .. ": " .. (assigned or "Unbound"), 2, "info")
    end
    frame.Destroying:Connect(function()
        if pendingToggleBind == entry then pendingToggleBind = nil end
        for i = #toggleKeybinds, 1, -1 do
            if toggleKeybinds[i] == entry then table.remove(toggleKeybinds, i) break end
        end
    end)
    return bindButton
end

UserInputService.InputBegan:Connect(function(input, processed)
    if pendingToggleBind then
        pendingToggleBind.capture(input)
        return
    end
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end
    for i = #toggleKeybinds, 1, -1 do
        local entry = toggleKeybinds[i]
        if not entry.frame.Parent then
            table.remove(toggleKeybinds, i)
        else
            -- Always resolve from persisted panel settings, not plugin-modified UI state.
            entry.key = entry.reload()
            if entry.key == input.KeyCode.Name then
                entry.activate()
            end
        end
    end
end)

local function createToggle(tabName: string, text: string, settingPathOrCallback: string | ToggleCallback, defaultValue: boolean?, settingsRoot, controlStatePath, restoreQueue)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 34)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
    ToggleFrame.BorderColor3 = Color3.fromRGB(39, 43, 48)
    ToggleFrame.BorderSizePixel = 1
    ToggleFrame.Visible = false
    ToggleFrame.Parent = ContentFrame
    registerThemeObject(ToggleFrame, "Surface")
    table.insert(tabs[tabName].widgets, ToggleFrame)

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    ToggleLabel.TextSize = 12
    ToggleLabel.Font = Enum.Font.Arial
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    registerThemeObject(ToggleLabel, "Text")
    ToggleLabel.Font = activeTheme.font
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 45, 0, 18)
    ToggleButton.Position = UDim2.new(1, -50, 0.5, -9)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    ToggleButton.Text = "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 10
    ToggleButton.Font = Enum.Font.ArialBold
    ToggleButton.Parent = ToggleFrame
    registerThemeObject(ToggleButton, "Toggle")
    
    -- FIXED: Properly determine initial state from saved data or default
    local isEnabled = defaultValue or false
    local hasSavedState = false
    
    if type(settingPathOrCallback) == "string" then
        local path = string.split(settingPathOrCallback, ".")
        local savedValue = readSettingPath(settingsRoot or Settings, path)
        if type(savedValue) == "boolean" then
            isEnabled = savedValue
            hasSavedState = true
        else
            writeSettingPath(settingsRoot or Settings, path, isEnabled)
        end
    elseif controlStatePath then
        local savedValue = readSettingPath(settingsRoot, controlStatePath)
        if type(savedValue) == "boolean" then
            isEnabled = savedValue
            hasSavedState = true
        else
            writeSettingPath(settingsRoot, controlStatePath, isEnabled)
        end
    end
    
    -- FIXED: Update UI to match initial state
    local function updateToggleUI(state)
        if state then
            ToggleButton.BackgroundColor3 = activeColors.Primary
            ToggleButton.Text = "ON"
        else
            ToggleButton.BackgroundColor3 = activeColors.Danger
            ToggleButton.Text = "OFF"
        end
    end
    
    -- Set initial UI state
    updateToggleUI(isEnabled)
    if hasSavedState and type(settingPathOrCallback) == "function" then
        local function restoreSavedToggle()
            local ok, err = pcall(settingPathOrCallback, isEnabled)
            if not ok then
                warn("Saved toggle restore failed [" .. tostring(tabName) .. " / " .. tostring(text) .. "]: " .. tostring(err))
                -- Do not claim ON when the plugin could not activate.
                if isEnabled then
                    isEnabled = false
                    updateToggleUI(false)
                    if controlStatePath then
                        writeSettingPath(settingsRoot, controlStatePath, false)
                        schedulePanelSave()
                    end
                end
            end
        end
        if restoreQueue then
            table.insert(restoreQueue, restoreSavedToggle)
        else
            task.defer(restoreSavedToggle)
        end
    end
    if type(settingPathOrCallback) == "string" or controlStatePath then
        local settingPath = type(settingPathOrCallback) == "string"
            and string.split(settingPathOrCallback, ".")
            or controlStatePath
        table.insert(settingsRefreshers, {
            owner = ToggleFrame,
            refresh = function()
                local value = readSettingPath(settingsRoot or Settings, settingPath)
                if type(value) == "boolean" then
                    isEnabled = value
                    updateToggleUI(isEnabled)
                    if controlStatePath and type(settingPathOrCallback) == "function" then
                        task.defer(function()
                            pcall(settingPathOrCallback, isEnabled)
                        end)
                    end
                end
            end,
        })
    end
    
    local function pressToggle()
        isEnabled = not isEnabled
        
        if type(settingPathOrCallback) == "string" then
            local path = string.split(settingPathOrCallback, ".")
            writeSettingPath(settingsRoot or Settings, path, isEnabled)
        elseif type(settingPathOrCallback) == "function" then
            if controlStatePath then
                writeSettingPath(settingsRoot, controlStatePath, isEnabled)
            end
            local callbackOk, callbackError = pcall(settingPathOrCallback, isEnabled)
            if not callbackOk then
                warn("Toggle callback failed: " .. tostring(callbackError))
            end
        end
        
        updateToggleUI(isEnabled)
        schedulePanelSave()
    end
    ToggleButton.MouseButton1Click:Connect(pressToggle)
    local bindStorage = settingsRoot or Settings
    local bindPath = controlStatePath or {"MainToggles", tostring(tabName), tostring(text)}
    attachToggleKeybind(ToggleFrame, text, ToggleButton, bindStorage, bindPath, pressToggle)
    ToggleLabel.Size = UDim2.new(1, -135, 1, 0)
    
    updateCanvasSize()
    return ToggleButton, ToggleFrame
end

-- Button widget
local function createButton(tabName: string, text: string, callback: ButtonCallback?)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, 0, 0, 34)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Visible = false
    ButtonFrame.Parent = ContentFrame
    registerThemeObject(ButtonFrame, "Panel")
    table.insert(tabs[tabName].widgets, ButtonFrame)
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, -2)
    Button.Position = UDim2.new(0, 0, 0, 1)
    Button.BackgroundColor3 = Color3.fromRGB(47, 123, 185)
    Button.BorderColor3 = Color3.fromRGB(29, 82, 125)
    Button.BorderSizePixel = 1
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.ArialBold
    Button.AutoButtonColor = false
    Button.Parent = ButtonFrame
    registerThemeObject(Button, "Primary")

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = activeColors.Primary:Lerp(Color3.new(1, 1, 1), 0.14)
    end)

    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = activeColors.Primary
    end)
    
    Button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    updateCanvasSize()
    return Button, ButtonFrame
end

-- Dropdown widget (FIXED - now parents to ScreenGui)
local function createDropdown(tabName: string, text: string, options: {string}, default: string?, callback: DropdownCallback?, settingsRoot, controlStatePath, restoreQueue)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Size = UDim2.new(1, 0, 0, 30)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
    DropdownFrame.Visible = false
    DropdownFrame.ClipsDescendants = false
    DropdownFrame.Parent = ContentFrame
    registerThemeObject(DropdownFrame, "Surface")
    table.insert(tabs[tabName].widgets, DropdownFrame)

    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Size = UDim2.new(0.5, -5, 1, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = text
    DropdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    DropdownLabel.TextSize = 12
    DropdownLabel.Font = Enum.Font.Arial
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = DropdownFrame
    registerThemeObject(DropdownLabel, "Text")
    DropdownLabel.Font = activeTheme.font

    local currentValue = default or options[1]
    local hasSavedValue = false
    if controlStatePath then
        local savedValue = readSettingPath(settingsRoot, controlStatePath)
        if type(savedValue) == "string" and table.find(options, savedValue) then
            currentValue = savedValue
            hasSavedValue = true
        else
            writeSettingPath(settingsRoot, controlStatePath, currentValue)
        end
    end

    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Size = UDim2.new(0.5, -5, 0, 22)
    DropdownButton.Position = UDim2.new(0.5, 5, 0, 4)
    DropdownButton.BackgroundColor3 = Color3.fromRGB(58, 62, 67)
    DropdownButton.BorderColor3 = Color3.fromRGB(77, 82, 88)
    DropdownButton.Text = currentValue
    DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropdownButton.TextSize = 11
    DropdownButton.Font = Enum.Font.Arial
    DropdownButton.ZIndex = 100
    DropdownButton.Parent = DropdownFrame
    registerThemeObject(DropdownButton, "Secondary")
    DropdownButton.Font = activeTheme.font

    if controlStatePath then
        table.insert(settingsRefreshers, {
            owner = DropdownFrame,
            refresh = function()
                local savedValue = readSettingPath(settingsRoot, controlStatePath)
                if type(savedValue) == "string" and table.find(options, savedValue) then
                    currentValue = savedValue
                    DropdownButton.Text = savedValue
                    if type(callback) == "function" then
                        task.defer(function()
                            pcall(callback, savedValue)
                        end)
                    end
                end
            end,
        })
    end

    -- Create fullscreen backdrop
    local Backdrop = Instance.new("TextButton")
    Backdrop.Name = "DropdownBackdrop"
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.Position = UDim2.new(0, 0, 0, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Backdrop.BackgroundTransparency = 0.7
    Backdrop.BorderSizePixel = 0
    Backdrop.Visible = false
    Backdrop.ZIndex = 9998
    Backdrop.Text = ""
    Backdrop.AutoButtonColor = false
    Backdrop.Parent = ScreenGui

    -- Create dropdown list container
    local DropdownList = Instance.new("Frame")
    DropdownList.Size = UDim2.new(0, 160, 0, math.min(#options * 25, 150))
    DropdownList.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
    DropdownList.BorderColor3 = Color3.fromRGB(100, 100, 100)
    DropdownList.BorderSizePixel = 2
    DropdownList.Visible = false
    DropdownList.ZIndex = 9999
    DropdownList.ClipsDescendants = false
    DropdownList.Parent = ScreenGui
    registerThemeObject(DropdownList, "Surface")

    -- Scrolling frame for options
    local DropdownScroll = Instance.new("ScrollingFrame")
    DropdownScroll.Size = UDim2.new(1, 0, 1, 0)
    DropdownScroll.BackgroundTransparency = 1
    DropdownScroll.BorderSizePixel = 0
    DropdownScroll.ScrollBarThickness = 4
    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 25)
    DropdownScroll.ZIndex = 10000
    DropdownScroll.ClipsDescendants = true
    DropdownScroll.Parent = DropdownList

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = DropdownScroll

    local function updatePosition()
        local buttonPos = DropdownButton.AbsolutePosition
        local buttonSize = DropdownButton.AbsoluteSize
        local screenSize = ScreenGui.AbsoluteSize
        
        local posX = buttonPos.X
        local posY = buttonPos.Y + buttonSize.Y + 2
        
        -- Keep dropdown on screen
        if posX + 160 > screenSize.X then
            posX = screenSize.X - 160
        end
        if posY + DropdownList.AbsoluteSize.Y > screenSize.Y then
            posY = buttonPos.Y - DropdownList.AbsoluteSize.Y - 2
        end
        
        DropdownList.Position = UDim2.new(0, posX, 0, posY)
    end

    local function closeDropdown()
        DropdownList.Visible = false
        Backdrop.Visible = false
    end

    local function closeAllDropdowns()
        for _, obj in ipairs(ScreenGui:GetChildren()) do
            if obj.Name == "DropdownBackdrop" and obj ~= Backdrop then
                obj.Visible = false
            end
        end
        for _, obj in ipairs(ScreenGui:GetChildren()) do
            if obj:IsA("Frame") and obj ~= DropdownList and obj ~= MainFrame and obj.ZIndex >= 9999 then
                obj.Visible = false
            end
        end
    end

    -- Create option buttons
    for _, option in ipairs(options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Size = UDim2.new(1, -4, 0, 25)
        OptionButton.BackgroundColor3 = Color3.fromRGB(61, 65, 70)
        OptionButton.BorderSizePixel = 0
        OptionButton.Text = option
        OptionButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        OptionButton.TextSize = 11
        OptionButton.Font = Enum.Font.Arial
        OptionButton.ZIndex = 10001
        OptionButton.AutoButtonColor = false
        OptionButton.Parent = DropdownScroll
        registerThemeObject(OptionButton, "Secondary")
        OptionButton.Font = activeTheme.font

        -- Hover effect
        OptionButton.MouseEnter:Connect(function()
            OptionButton.BackgroundColor3 = activeColors.Primary
        end)

        OptionButton.MouseLeave:Connect(function()
            OptionButton.BackgroundColor3 = activeColors.Secondary
        end)

        -- Selection
        OptionButton.MouseButton1Click:Connect(function()
            currentValue = option
            DropdownButton.Text = option
            closeDropdown()
            if controlStatePath then
                writeSettingPath(settingsRoot, controlStatePath, option)
                schedulePanelSave()
            end
            if callback then 
                task.spawn(function()
                    local callbackOk, callbackError = pcall(callback, option)
                    if not callbackOk then
                        warn("Dropdown callback failed: " .. tostring(callbackError))
                    end
                end)
            end
        end)
    end

    -- Toggle dropdown
    DropdownButton.MouseButton1Click:Connect(function()
        closeAllDropdowns()
        
        local newState = not DropdownList.Visible
        if newState then
            updatePosition()
        end
        DropdownList.Visible = newState
        Backdrop.Visible = newState
    end)

    -- Close when clicking backdrop
    Backdrop.MouseButton1Click:Connect(function()
        closeDropdown()
    end)

    if hasSavedValue and type(callback) == "function" then
        local restore = function()
            local ok, err = pcall(callback, currentValue)
            if not ok then warn("Dropdown restore failed [" .. tostring(tabName) .. " / " .. tostring(text) .. "]: " .. tostring(err)) end
        end
        if restoreQueue then table.insert(restoreQueue, restore) else task.defer(restore) end
    end

    updateCanvasSize()
    return DropdownButton, DropdownFrame
end

-- Window widget (creates a separate draggable window)
local function createWindow(title: string, width: number?, height: number?, windowSettings, restoreQueue)
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = title .. "Window"
    WindowFrame.Size = UDim2.new(0, width or 300, 0, height or 400)
    WindowFrame.Position = UDim2.new(0.5, -(width or 300)/2, 0.5, -(height or 400)/2)
    WindowFrame.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
    WindowFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
    WindowFrame.BorderSizePixel = 3
    WindowFrame.ZIndex = 100
    WindowFrame.Parent = ScreenGui
    registerThemeObject(WindowFrame, "Panel")
    
    local WindowGradient = Instance.new("UIGradient")
    WindowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(77, 81, 86)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 49, 53))
    })
    WindowGradient.Rotation = 90
    WindowGradient.Parent = WindowFrame
    
    -- Window top bar
    local WindowTopBar = Instance.new("Frame")
    WindowTopBar.Name = "TopBar"
    WindowTopBar.Size = UDim2.new(1, 0, 0, 25)
    WindowTopBar.BackgroundColor3 = Color3.fromRGB(32, 125, 205)
    WindowTopBar.BorderSizePixel = 0
    WindowTopBar.ZIndex = 101
    WindowTopBar.Parent = WindowFrame
    registerThemeObject(WindowTopBar, "Header")
    
    local WindowTopGradient = Instance.new("UIGradient")
    WindowTopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 145, 225)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 105, 175))
    })
    WindowTopGradient.Rotation = 90
    WindowTopGradient.Parent = WindowTopBar
    registerThemeGradient(WindowTopGradient)
    
    local WindowTitle = Instance.new("TextLabel")
    WindowTitle.Size = UDim2.new(1, -60, 1, 0)
    WindowTitle.Position = UDim2.new(0, 5, 0, 0)
    WindowTitle.BackgroundTransparency = 1
    WindowTitle.Text = title
    WindowTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    WindowTitle.TextSize = 14
    WindowTitle.Font = Enum.Font.Arial
    WindowTitle.TextXAlignment = Enum.TextXAlignment.Left
    WindowTitle.TextStrokeTransparency = 0.8
    WindowTitle.ZIndex = 102
    WindowTitle.Parent = WindowTopBar
    registerThemeObject(WindowTitle, "Text")
    
    -- Window minimize button
    local WindowMinimizeBtn = Instance.new("TextButton")
    WindowMinimizeBtn.Size = UDim2.new(0, 20, 0, 18)
    WindowMinimizeBtn.Position = UDim2.new(1, -46, 0, 3)
    WindowMinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 180)
    WindowMinimizeBtn.BorderColor3 = Color3.fromRGB(70, 110, 150)
    WindowMinimizeBtn.Text = "_"
    WindowMinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    WindowMinimizeBtn.TextSize = 12
    WindowMinimizeBtn.Font = Enum.Font.ArialBold
    WindowMinimizeBtn.ZIndex = 102
    WindowMinimizeBtn.Parent = WindowTopBar
    registerThemeObject(WindowMinimizeBtn, "Secondary")
    
    -- Window close button
    local WindowCloseBtn = Instance.new("TextButton")
    WindowCloseBtn.Size = UDim2.new(0, 20, 0, 18)
    WindowCloseBtn.Position = UDim2.new(1, -23, 0, 3)
    WindowCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    WindowCloseBtn.BorderColor3 = Color3.fromRGB(150, 40, 40)
    WindowCloseBtn.Text = "X"
    WindowCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    WindowCloseBtn.TextSize = 12
    WindowCloseBtn.Font = Enum.Font.ArialBold
    WindowCloseBtn.ZIndex = 102
    WindowCloseBtn.Parent = WindowTopBar
    registerThemeObject(WindowCloseBtn, "Danger")
    
    -- Window content area
    local WindowContent = Instance.new("ScrollingFrame")
    WindowContent.Name = "Content"
    WindowContent.Size = UDim2.new(1, -10, 1, -35)
    WindowContent.Position = UDim2.new(0, 5, 0, 30)
    WindowContent.BackgroundColor3 = Color3.fromRGB(61, 65, 70)
    WindowContent.BorderColor3 = Color3.fromRGB(35, 35, 35)
    WindowContent.ScrollBarThickness = 8
    WindowContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    WindowContent.ZIndex = 101
    WindowContent.Parent = WindowFrame
    registerThemeObject(WindowContent, "Content")
    
    local WindowContentLayout = Instance.new("UIListLayout")
    WindowContentLayout.Padding = UDim.new(0, 5)
    WindowContentLayout.Parent = WindowContent
    
    local WindowContentPadding = Instance.new("UIPadding")
    WindowContentPadding.PaddingTop = UDim.new(0, 5)
    WindowContentPadding.PaddingLeft = UDim.new(0, 5)
    WindowContentPadding.PaddingRight = UDim.new(0, 5)
    WindowContentPadding.Parent = WindowContent
    
    WindowContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        WindowContent.CanvasSize = UDim2.new(0, 0, 0, WindowContentLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Bring windows to the front before starting a smooth drag.
    -- Bring window to front when clicked
    local function bringToFront()
        windowZIndex = windowZIndex + 10
        WindowFrame.ZIndex = windowZIndex
        WindowTopBar.ZIndex = windowZIndex + 1
        WindowTitle.ZIndex = windowZIndex + 2
        WindowMinimizeBtn.ZIndex = windowZIndex + 2
        WindowCloseBtn.ZIndex = windowZIndex + 2
        WindowContent.ZIndex = windowZIndex + 1
        
        -- Update all child elements
        for _, child in ipairs(WindowContent:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.ZIndex = windowZIndex + 2
            end
        end
    end
    
    local windowIsMinimized = false
    local originalHeight = height or 400
    attachSmoothDrag(WindowTopBar, WindowFrame, connections, bringToFront)
    --[[ Resize feature temporarily disabled; implementation retained.
    attachWindowResize(WindowFrame, 240, 160, connections, function(w, h)
        if not windowIsMinimized then originalHeight = h end
    end, bringToFront)
    ]]
    WindowFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            bringToFront()
        end
    end)

    -- Minimize functionality
    WindowMinimizeBtn.MouseButton1Click:Connect(function()
        windowIsMinimized = not windowIsMinimized
        if windowIsMinimized then
            WindowFrame:SetAttribute("SimbaResizeDisabled", true)
            WindowFrame.Size = UDim2.fromOffset(WindowFrame.AbsoluteSize.X, 25)
            WindowContent.Visible = false
            WindowMinimizeBtn.Text = "+"
        else
            WindowFrame.Size = UDim2.fromOffset(WindowFrame.AbsoluteSize.X, originalHeight)
            WindowFrame:SetAttribute("SimbaResizeDisabled", false)
            WindowContent.Visible = true
            WindowMinimizeBtn.Text = "_"
        end
    end)
    
    -- Close window
    WindowCloseBtn.MouseButton1Click:Connect(function()
        if WindowFrame.Parent then WindowFrame:Destroy() end
    end)
    
    -- API for adding elements to window
    local WindowAPI = {
        Frame = WindowFrame,
        Content = WindowContent,
        
        AddLabel = function(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(220, 220, 220)
            Label.TextSize = 11
            Label.Font = Enum.Font.Arial
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 102
            Label.Parent = WindowContent
            registerThemeObject(Label, "Text")
            return Label
        end,
        
        AddButton = function(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -10, 0, 25)
            Button.BackgroundColor3 = Color3.fromRGB(47, 123, 185)
            Button.BorderSizePixel = 0
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.TextSize = 12
            Button.Font = Enum.Font.ArialBold
            Button.ZIndex = 102
            Button.Parent = WindowContent
            registerThemeObject(Button, "Primary")
            
            Button.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            
            return Button
        end,
        
        AddToggle = function(text, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, -10, 0, 25)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.ZIndex = 102
            ToggleFrame.Parent = WindowContent
            registerThemeObject(ToggleFrame, "Surface")
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            ToggleLabel.TextSize = 12
            ToggleLabel.Font = Enum.Font.Arial
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.ZIndex = 103
            ToggleLabel.Parent = ToggleFrame
            registerThemeObject(ToggleLabel, "Text")
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 45, 0, 18)
            ToggleButton.Position = UDim2.new(1, -50, 0.5, -9)
            ToggleButton.BackgroundColor3 = default and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            ToggleButton.Text = default and "ON" or "OFF"
            ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleButton.TextSize = 10
            ToggleButton.Font = Enum.Font.ArialBold
            ToggleButton.ZIndex = 103
            ToggleButton.Parent = ToggleFrame
            registerThemeObject(ToggleButton, "Toggle")
            
            local togglePath = {"__PanelControlState", "Windows", tostring(title), "Toggles", tostring(text)}
            local savedToggle = windowSettings and readSettingPath(windowSettings, togglePath)
            local isEnabled = default or false
            if type(savedToggle) == "boolean" then isEnabled = savedToggle end
            local function refreshWindowToggle()
                ToggleButton.Text = isEnabled and "ON" or "OFF"
                ToggleButton.BackgroundColor3 = isEnabled and activeColors.Primary or activeColors.Danger
            end
            refreshWindowToggle()
            if windowSettings then
                if type(savedToggle) ~= "boolean" then
                    writeSettingPath(windowSettings, togglePath, isEnabled)
                elseif type(callback) == "function" then
                    local restore = function()
                        local ok, err = pcall(callback, isEnabled)
                        if not ok then warn("Window toggle restore failed: " .. tostring(err)) end
                    end
                    if restoreQueue then table.insert(restoreQueue, restore) else task.defer(restore) end
                end
                table.insert(settingsRefreshers, {owner = ToggleFrame, refresh = function()
                    local value = readSettingPath(windowSettings, togglePath)
                    if type(value) == "boolean" then
                        isEnabled = value
                        refreshWindowToggle()
                        if type(callback) == "function" then task.defer(function() pcall(callback, isEnabled) end) end
                    end
                end})
            end
            
            local function pressToggle()
                isEnabled = not isEnabled
                if isEnabled then
                    ToggleButton.BackgroundColor3 = activeColors.Primary
                    ToggleButton.Text = "ON"
                else
                    ToggleButton.BackgroundColor3 = activeColors.Danger
                    ToggleButton.Text = "OFF"
                end
                if windowSettings then
                    writeSettingPath(windowSettings, togglePath, isEnabled)
                    schedulePanelSave()
                end
                if callback then callback(isEnabled) end
            end
            ToggleButton.MouseButton1Click:Connect(pressToggle)
            if windowSettings then
                attachToggleKeybind(ToggleFrame, text, ToggleButton, windowSettings,
                    {"Windows", tostring(title), "Toggles", tostring(text)}, pressToggle)
                ToggleLabel.Size = UDim2.new(1, -135, 1, 0)
            end
            return ToggleFrame
        end,
        
        AddTextBox = function(placeholder)
            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -10, 0, 25)
            TextBox.BackgroundColor3 = Color3.fromRGB(58, 62, 67)
            TextBox.BorderColor3 = Color3.fromRGB(77, 82, 88)
            TextBox.PlaceholderText = placeholder or ""
            TextBox.Text = ""
            TextBox.TextColor3 = Color3.fromRGB(220, 220, 220)
            TextBox.TextSize = 11
            TextBox.Font = Enum.Font.Arial
            TextBox.ZIndex = 102
            TextBox.Parent = WindowContent
            registerThemeObject(TextBox, "Input")
            if windowSettings then
                local textPath = {"__PanelControlState", "Windows", tostring(title), "TextBoxes", tostring(placeholder or "")}
                local savedText = readSettingPath(windowSettings, textPath)
                if type(savedText) == "string" then TextBox.Text = savedText end
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    writeSettingPath(windowSettings, textPath, TextBox.Text)
                    schedulePanelSave()
                end)
                table.insert(settingsRefreshers, {owner = TextBox, refresh = function()
                    local value = readSettingPath(windowSettings, textPath)
                    if type(value) == "string" then TextBox.Text = value end
                end})
            end
            return TextBox
        end,
        
        Show = function()
            WindowFrame.Visible = true
        end,
        
        Hide = function()
            WindowFrame.Visible = false
        end,
        
        Destroy = function()
            if WindowFrame.Parent then
                WindowFrame:Destroy()
            end
        end
    }
    
    return WindowAPI
end

-- Label widget
local function createLabel(tabName: string, text: string)
    local LabelFrame = Instance.new("Frame")
    LabelFrame.Size = UDim2.new(1, 0, 0, 20)
    LabelFrame.BackgroundTransparency = 1
    LabelFrame.Visible = false
    LabelFrame.Parent = ContentFrame
    registerThemeObject(LabelFrame, "Panel")
    table.insert(tabs[tabName].widgets, LabelFrame)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(180, 180, 180)
    Label.TextSize = 11
    Label.Font = Enum.Font.Arial
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = LabelFrame
    registerThemeObject(Label, "MutedText")
    Label.Font = activeTheme.font
    
    updateCanvasSize()
    return Label, LabelFrame
end

-- Slider widget (now supports decimal precision)
-- One wheel listener for every slider. Hit testing is based on cursor position,
-- not MouseEnter, which is unreliable when controls overlap or are clipped.
local wheelSliderRegistry = {}
local wheelPausedScrollers = {}
local wheelTarget = nil
local wheelHoverCandidate = nil
local wheelHoverStarted = 0
local WHEEL_HOVER_DELAY = 1.0

local function wheelContains(frame, point)
    if not frame.Parent or not frame.Visible then return false end
    local position, size = frame.AbsolutePosition, frame.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return false end
    if point.X < position.X or point.X >= position.X + size.X
        or point.Y < position.Y or point.Y >= position.Y + size.Y then return false end
    local ancestor = frame.Parent
    while ancestor do
        if ancestor:IsA("GuiObject") then
            if not ancestor.Visible then return false end
            if ancestor.ClipsDescendants or ancestor:IsA("ScrollingFrame") then
                local ap, as = ancestor.AbsolutePosition, ancestor.AbsoluteSize
                if point.X < ap.X or point.X >= ap.X + as.X
                    or point.Y < ap.Y or point.Y >= ap.Y + as.Y then return false end
            end
        end
        if ancestor == ScreenGui then break end
        ancestor = ancestor.Parent
    end
    return ancestor == ScreenGui
end

local function wheelFindTarget()
    -- GetMouseLocation includes Roblox's top-bar inset, whereas this ScreenGui
    -- uses IgnoreGuiInset=true. Convert to the GUI's coordinate space first.
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    local mouse = UserInputService:GetMouseLocation() - guiInset
    local best, bestZ = nil, -math.huge
    for _, entry in ipairs(wheelSliderRegistry) do
        if wheelContains(entry.frame, mouse) then
            local z = entry.frame.ZIndex
            if z >= bestZ then
                best, bestZ = entry, z
            end
        end
    end
    return best
end

-- Only capture the wheel after one uninterrupted second over the same slider.
-- Keep the scrollable container disabled *before* wheel input is dispatched.
-- Re-evaluate every frame so mouse-enter events are not needed.
local function wheelUpdateHover()
    local target = wheelFindTarget()
    if target ~= wheelHoverCandidate then
        wheelHoverCandidate = target
        wheelHoverStarted = os.clock()
        wheelTarget = nil
    elseif target and os.clock() - wheelHoverStarted >= WHEEL_HOVER_DELAY then
        wheelTarget = target
    else
        wheelTarget = nil
    end
    local required = {}
    if wheelTarget then
        local ancestor = wheelTarget.frame.Parent
        while ancestor do
            if ancestor:IsA("ScrollingFrame") then required[ancestor] = true end
            if ancestor == ScreenGui then break end
            ancestor = ancestor.Parent
        end
    end
    for scroller, previous in pairs(wheelPausedScrollers) do
        if not required[scroller] or not scroller.Parent then
            if scroller.Parent then scroller.ScrollingEnabled = previous end
            wheelPausedScrollers[scroller] = nil
        end
    end
    for scroller in pairs(required) do
        if wheelPausedScrollers[scroller] == nil then
            wheelPausedScrollers[scroller] = scroller.ScrollingEnabled
        end
        scroller.ScrollingEnabled = false
    end
end

local wheelHoverConnection = RunService.RenderStepped:Connect(wheelUpdateHover)
local wheelInputConnection = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    wheelUpdateHover()
    if wheelTarget then
        local delta = input.Position.Z
        local direction = math.sign(delta)
        if direction ~= 0 then wheelTarget.apply(direction) end
    end
end)
ScreenGui.Destroying:Connect(function()
    wheelHoverConnection:Disconnect()
    wheelInputConnection:Disconnect()
    for scroller, previous in pairs(wheelPausedScrollers) do
        if scroller.Parent then scroller.ScrollingEnabled = previous end
    end
end)

local function createSlider(tabName: string, text: string, min: number, max: number, default: number, callbackOrPath: string | SliderCallback, increment: number?, settingsRoot, controlStatePath, restoreQueue)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 45)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(72, 76, 81)
    SliderFrame.Visible = false
    SliderFrame.Parent = ContentFrame
    registerThemeObject(SliderFrame, "Surface")
    table.insert(tabs[tabName].widgets, SliderFrame)
    
    -- Default increment is 1 for integers, or can be set to 0.1, 0.01, etc
    local step = increment or 1
    local isDecimal = step < 1
    local decimalPlaces = 0
    if isDecimal then
        -- Calculate decimal places from step
        local stepStr = tostring(step)
        if stepStr:find("%.") then
            decimalPlaces = #stepStr - stepStr:find("%.") 
        end
    end
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(1, -50, 0, 15)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = text
    SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    SliderLabel.TextSize = 12
    SliderLabel.Font = Enum.Font.Arial
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame
    registerThemeObject(SliderLabel, "Text")
    SliderLabel.Font = activeTheme.font
    
    local currentValue = default or min
    local hasSavedValue = false
    if type(callbackOrPath) == "string" then
        local path = string.split(callbackOrPath, ".")
        local value = readSettingPath(settingsRoot or Settings, path)
        if type(value) == "number" then
            currentValue = math.clamp(value, min, max)
            hasSavedValue = true
        else
            writeSettingPath(settingsRoot or Settings, path, currentValue)
        end
    elseif controlStatePath then
        local value = readSettingPath(settingsRoot, controlStatePath)
        if type(value) == "number" then
            currentValue = math.clamp(value, min, max)
            hasSavedValue = true
        else
            writeSettingPath(settingsRoot, controlStatePath, currentValue)
        end
    end
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 50, 0, 15)
    ValueLabel.Position = UDim2.new(1, -52, 0, 3)
    ValueLabel.BackgroundTransparency = 1
    if isDecimal then
        ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", currentValue)
    else
        ValueLabel.Text = tostring(math.floor(currentValue))
    end
    ValueLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    ValueLabel.TextSize = 11
    ValueLabel.Font = Enum.Font.ArialBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame
    registerThemeObject(ValueLabel, "Primary")
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -10, 0, 10)
    SliderBar.Position = UDim2.new(0, 5, 0, 25)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 49, 53)
    SliderBar.Parent = SliderFrame
    registerThemeObject(SliderBar, "Input")
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(47, 123, 185)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBar
    registerThemeObject(SliderFill, "Primary")
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(1, 0, 1, 5)
    SliderButton.BackgroundTransparency = 1
    SliderButton.Text = ""
    SliderButton.Parent = SliderBar
    
    local dragging = false
    local function updateSlider(input, exactValue)
        local newValue
        if exactValue ~= nil then
            -- Wheel adjustments must not round-trip through screen pixels.
            newValue = math.clamp(exactValue, min, max)
        else
            local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local rawValue = min + (max - min) * pos
            newValue = math.clamp(math.floor((rawValue / step) + 0.5) * step, min, max)
        end
        currentValue = newValue
        
        SliderFill.Size = UDim2.new((newValue - min) / (max - min), 0, 1, 0)
        
        if isDecimal then
            ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", newValue)
        else
            ValueLabel.Text = tostring(math.floor(newValue))
        end
        
        if type(callbackOrPath) == "string" then
            local path = string.split(callbackOrPath, ".")
            writeSettingPath(settingsRoot or Settings, path, newValue)
        elseif type(callbackOrPath) == "function" then
            if controlStatePath then
                writeSettingPath(settingsRoot, controlStatePath, newValue)
            end
            local callbackOk, callbackError = pcall(callbackOrPath, newValue)
            if not callbackOk then
                warn("Slider callback failed: " .. tostring(callbackError))
            end
        end
        schedulePanelSave()
    end

    if type(callbackOrPath) == "string" or controlStatePath then
        local settingPath = type(callbackOrPath) == "string"
            and string.split(callbackOrPath, ".")
            or controlStatePath
        table.insert(settingsRefreshers, {
            owner = SliderFrame,
            refresh = function()
                local value = readSettingPath(settingsRoot or Settings, settingPath)
                if type(value) == "number" then
                    currentValue = math.clamp(value, min, max)
                    SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
                    if isDecimal then
                        ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", currentValue)
                    else
                        ValueLabel.Text = tostring(math.floor(currentValue))
                    end
                    if controlStatePath and type(callbackOrPath) == "function" then
                        task.defer(function()
                            pcall(callbackOrPath, currentValue)
                        end)
                    end
                end
            end,
        })
    end
    
    if hasSavedValue and type(callbackOrPath) == "function" then
        local restore = function()
            local ok, err = pcall(callbackOrPath, currentValue)
            if not ok then warn("Slider restore failed [" .. tostring(tabName) .. " / " .. tostring(text) .. "]: " .. tostring(err)) end
        end
        if restoreQueue then table.insert(restoreQueue, restore) else task.defer(restore) end
    end

    -- Register with one central wheel router; avoid competing per-slider handlers.
    local wheelEntry = {
        frame = SliderFrame,
        apply = function(direction)
            if max <= min then return end
            local index = math.floor((currentValue - min) / step + 0.5)
            local nextValue = math.clamp(min + (index + direction) * step, min, max)
            if math.abs(nextValue - currentValue) < 0.000001 then return end
            -- Apply exactly one configured step, independent of slider width.
            updateSlider(nil, nextValue)
        end,
    }
    table.insert(wheelSliderRegistry, wheelEntry)
    SliderFrame.Destroying:Connect(function()
        for i = #wheelSliderRegistry, 1, -1 do
            if wheelSliderRegistry[i] == wheelEntry then
                table.remove(wheelSliderRegistry, i)
                break
            end
        end
    end)

    SliderButton.MouseButton1Down:Connect(function()
        dragging = true
        local endConn, moveConn
        endConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                endConn:Disconnect()
                moveConn:Disconnect()
            end
        end)
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
    end)

    if hasSavedValue and type(callbackOrPath) == "function" then
        task.defer(function()
            pcall(callbackOrPath, currentValue)
        end)
    end
    
    updateCanvasSize()
end

-- Set API functions
PluginAPI.CreateTab = createTab
PluginAPI.CreateToggle = createToggle
PluginAPI.CreateSlider = function(tabName, text, min, max, default, callback, increment)
    createSlider(tabName, text, min, max, default, callback, increment)
end
PluginAPI.CreateButton = function(tabName, text, callback)
    return createButton(tabName, text, callback)
end
PluginAPI.CreateDropdown = function(tabName, text, options, default, callback)
    return createDropdown(tabName, text, options, default, callback)
end
PluginAPI.CreateLabel = function(tabName, text)
    return createLabel(tabName, text)
end
PluginAPI.CreateWindow = function(title, width, height)
    return createWindow(title, width, height)
end

setStartupProgress(0.52, "Preparing plugin controls...", "Setting up the plugin API")
task.wait()

createPluginAPI = function(pluginName)
    local pluginSettings = Settings.PluginSettings[pluginName]
    if type(pluginSettings) ~= "table" then
        pluginSettings = {}
        Settings.PluginSettings[pluginName] = pluginSettings
    end
    -- Shared settings remain available for plugin API compatibility.
    -- Plugin-specific control state is persisted in pluginSettings separately.

    local scopedAPI: {[string]: any} = {}
    for key, value in pairs(PluginAPI) do
        scopedAPI[key] = value
    end
    scopedAPI.Settings = Settings
    scopedAPI.LocalSettings = pluginSettings
    scopedAPI.PluginConnections = {}
    scopedAPI.Windows = {}
    scopedAPI.ScreenUIs = {}
    scopedAPI.PendingRestores = {}
    -- Observe text-based custom controls that older plugins create with AddButton.
    -- This preserves displayed selections, including keybind labels, without
    -- replaying arbitrary button clicks on startup.
    local observedControls = {}
    local controlOrdinals = {}
    local function observeControl(control, group, identity)
        if not control or not control:IsA("TextButton") and not control:IsA("TextBox") then return end
        if observedControls[control] then return end
        observedControls[control] = true
        local baseText = control.Text
        local baseKey = tostring(group) .. "|" .. tostring(identity or baseText)
        controlOrdinals[baseKey] = (controlOrdinals[baseKey] or 0) + 1
        local key = baseKey .. "|" .. tostring(controlOrdinals[baseKey])
        local path = {"__PanelControlState", "ObservedControls", key}
        local saved = readSettingPath(pluginSettings, path)
        local restoring = false
        if type(saved) == "string" then
            restoring = true
            control.Text = saved
            restoring = false
        end
        control:GetPropertyChangedSignal("Text"):Connect(function()
            if restoring or not control.Parent then return end
            writeSettingPath(pluginSettings, path, control.Text)
            schedulePanelSave()
        end)
    end
    local function observeWindowButtons(windowAPI, title)
        local content = windowAPI and windowAPI.Content
        if not content then return end
        local function inspect(child)
            if child:IsA("TextButton") or child:IsA("TextBox") then
                observeControl(child, "Window:" .. tostring(title), child.Name ~= "TextButton" and child.Name or child.Text)
            end
        end
        for _, child in ipairs(content:GetDescendants()) do inspect(child) end
        content.DescendantAdded:Connect(function(child)
            -- Defer until plugins have populated the label on the new control.
            task.defer(function()
                if child.Parent then inspect(child) end
            end)
        end)
    end
    scopedAPI.GetSavedControlValue = function(key, fallback)
        local value = readSettingPath(pluginSettings, {"__PanelControlState", "CustomValues", tostring(key)})
        return value == nil and fallback or value
    end
    scopedAPI.SaveControlValue = function(key, value)
        local serializable = copySerializable(value)
        if serializable == nil then return false end
        writeSettingPath(pluginSettings, {"__PanelControlState", "CustomValues", tostring(key)}, serializable)
        schedulePanelSave()
        return true
    end
    scopedAPI.RegisterConnection = function(connection)
        if connection then
            table.insert(scopedAPI.PluginConnections, connection)
        end
        return connection
    end
    -- Older plugins sometimes create controls without explicitly creating a tab.
    -- Recover by creating that tab rather than throwing and removing their UI.
    local function ensurePluginTab(tabName)
        if type(tabName) ~= "string" or tabName == "" then
            error("Plugin " .. tostring(pluginName) .. " passed an invalid tab name", 3)
        end
        if not tabs[tabName] then
            warn("[" .. tostring(pluginName) .. "] Auto-creating missing tab: " .. tabName)
            createTab(tabName, "")
        end
    end
    scopedAPI.CreateTab = function(name, icon)
        return createTab(name, icon)
    end
    scopedAPI.CreateButton = function(tabName, text, callback)
        ensurePluginTab(tabName)
        local button, frame = createButton(tabName, text, callback)
        observeControl(button, "Tab:" .. tostring(tabName), tostring(text))
        return button, frame
    end
    scopedAPI.CreateLabel = function(tabName, text)
        ensurePluginTab(tabName)
        return createLabel(tabName, text)
    end
    scopedAPI.CreateToggle = function(tabName, text, settingPathOrCallback, defaultValue)
        ensurePluginTab(tabName)
        local controlStatePath = type(settingPathOrCallback) == "function"
            and {"__PanelControlState", "Toggles", tostring(tabName), tostring(text)}
            or nil
        return createToggle(tabName, text, settingPathOrCallback, defaultValue, type(settingPathOrCallback) == "string" and Settings or pluginSettings, controlStatePath, scopedAPI.PendingRestores)
    end
    scopedAPI.CreateSlider = function(tabName, text, min, max, default, callbackOrPath, increment)
        ensurePluginTab(tabName)
        local controlStatePath = type(callbackOrPath) == "function"
            and {"__PanelControlState", "Sliders", tostring(tabName), tostring(text)}
            or nil
        return createSlider(tabName, text, min, max, default, callbackOrPath, increment, type(callbackOrPath) == "string" and Settings or pluginSettings, controlStatePath, scopedAPI.PendingRestores)
    end
    scopedAPI.CreateDropdown = function(tabName, text, options, default, callback)
        ensurePluginTab(tabName)
        local controlStatePath = {"__PanelControlState", "Dropdowns", tostring(tabName), tostring(text)}
        return createDropdown(tabName, text, options, default, callback, pluginSettings, controlStatePath, scopedAPI.PendingRestores)
    end
    scopedAPI.CreateWindow = function(title, width, height)
        local windowAPI = createWindow(title, width, height, pluginSettings, scopedAPI.PendingRestores)
        table.insert(scopedAPI.Windows, windowAPI)
        observeWindowButtons(windowAPI, title)
        return windowAPI
    end
    scopedAPI.CreateScreenUI = function(name, position, size)
        local screenUI = createScreenUI(pluginName .. "_" .. tostring(name), position, size)
        table.insert(scopedAPI.ScreenUIs, screenUI)
        return screenUI
    end
    scopedAPI.GetScreenUI = function(name)
        return screenUIElements[pluginName .. "_" .. tostring(name)]
    end

    pluginAPIs[pluginName] = scopedAPI
    return scopedAPI
end

local function destroyPluginTab(pluginName)
    local tab = tabs[pluginName]
    if not tab then
        return
    end

    local roots = {tab.button}
    for _, widget in ipairs(tab.widgets) do
        table.insert(roots, widget)
    end
    pruneThemeObjects(roots)

    if tab.button and tab.button.Parent then
        tab.button:Destroy()
    end
    for _, widget in ipairs(tab.widgets) do
        if widget and widget.Parent then
            widget:Destroy()
        end
    end
    tabs[pluginName] = nil
    if refreshFavoriteWidgets then refreshFavoriteWidgets() end
end

cleanupPluginRuntime = function(pluginName, plugin)
    local scopedAPI = pluginAPIs[pluginName]
    if plugin and type(plugin.Cleanup) == "function" then
        pcall(plugin.Cleanup, scopedAPI or PluginAPI)
    end
    if scopedAPI then
        for _, connection in ipairs(scopedAPI.PluginConnections or {}) do
            pcall(function()
                if connection and connection.Connected then
                    connection:Disconnect()
                end
            end)
        end
        for _, windowAPI in ipairs(scopedAPI.Windows or {}) do
            pcall(function()
                if windowAPI.Destroy then
                    windowAPI.Destroy()
                elseif windowAPI.Frame and windowAPI.Frame.Parent then
                    windowAPI.Frame:Destroy()
                end
            end)
        end
        for _, screenUI in ipairs(scopedAPI.ScreenUIs or {}) do
            pcall(function()
                if screenUI.Destroy then
                    screenUI.Destroy()
                end
            end)
        end
        pluginAPIs[pluginName] = nil
    end
    if pluginName ~= "Plugins" and pluginName ~= "Settings" and pluginName ~= "Favorites" then
        destroyPluginTab(pluginName)
    end
    for index = #connections, 1, -1 do
        local connection = connections[index]
        if not connection or not connection.Connected then
            table.remove(connections, index)
        end
    end
    pruneThemeObjects({})
    refreshThemeGradients()
    Plugins[pluginName] = nil
    if refreshFolderNavigation then refreshFolderNavigation() end
end

-- Create tabs
createTab("Plugins", "")
createTab("Settings", "")
createTab("Favorites", "★")
-- Hidden from normal plugin list; accessed through the small <> toolbar button.
tabs["Loadstrings"] = {button = loadstringsButton, widgets = {}}
reservedTabs.Loadstrings = true
reservedTabs.Executor = true

refreshFavoriteWidgets()
refreshFolderNavigation()
setStartupProgress(0.6, "Building the control panel...", "Creating plugin manager and settings controls")
task.wait()

-- Keep a panel-construction error from leaving the full-screen loader stranded.
local startupBuildOk, startupBuildError = pcall(function()
-- Plugin management
-- Loadstrings area. Manifest is a Lua file you control on your own website.
-- Only scripts explicitly clicked by the user are fetched and executed.
local manifestURL = "https://www.simbastudios.win/WobbleScotch/Assets/loadstrings.lua"
local loaderRoot = Instance.new("Frame")
loaderRoot.Name = "LoadstringsLibrary"
loaderRoot.Size = UDim2.new(1, -10, 0, 340)
loaderRoot.BackgroundTransparency = 1
loaderRoot.Visible = false
loaderRoot.LayoutOrder = 1
loaderRoot.Parent = ContentFrame
table.insert(tabs.Loadstrings.widgets, loaderRoot)

local function loaderText(text, y, height, size)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, height)
    t.Position = UDim2.fromOffset(0, y)
    t.BackgroundTransparency = 1
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.TextWrapped = true
    t.Text = text
    t.TextSize = size or 12
    t.Font = activeTheme.font
    t.TextColor3 = activeColors.Text
    t.Parent = loaderRoot
    registerThemeObject(t, "Text")
    return t
end
loaderText("Remote Loadstrings", 0, 28, 15)
loaderText("Only run code from sources you trust. Nothing runs automatically.", 29, 35, 11)
loaderText("Source: " .. manifestURL, 66, 33, 10)
local loaderStatus = loaderText("Press Refresh to fetch your list.", 177, 30, 11)
local loaderRows = {}
local function clearLoaderRows()
    for _, obj in ipairs(loaderRows) do obj:Destroy() end
    table.clear(loaderRows)
end
local function loaderButton(label, x, y, width, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(width, -6, 0, 27)
    b.Position = UDim2.new(x, 0, 0, y)
    b.Text = label
    b.TextSize = 11
    b.Font = activeTheme.font
    b.TextColor3 = activeColors.Text
    b.BackgroundColor3 = activeColors.Tab
    b.Parent = loaderRoot
    registerThemeObject(b, "Tab")
    b.MouseButton1Click:Connect(callback)
    return b
end
local function fetchRemote(url)
    if type(url) ~= "string" or not url:match("^https://") then
        error("Only HTTPS URLs are supported")
    end
    return game:HttpGet(url)
end
local function refreshLoadstrings()
    local url = manifestURL
    clearLoaderRows()
    loaderStatus.Text = "Fetching manifest..."
    task.spawn(function()
        local ok, result = pcall(function()
            local source = fetchRemote(url)
            -- The manifest is executable Lua: host it only on a website you control.
            local fn, compileError = loadstring(source)
            if not fn then error(compileError) end
            local entries = fn()
            if type(entries) ~= "table" then error("Manifest must return a Lua table") end
            return entries
        end)
        if not loaderRoot.Parent then return end
        if not ok then
            loaderStatus.Text = "Failed: " .. tostring(result):sub(1, 120)
            return
        end
        local entries = result
        local count = 0
        for i, entry in ipairs(entries) do
            if type(entry) == "table" and type(entry.name) == "string" and type(entry.url) == "string" and entry.url:match("^https://") then
                local y = 212 + count * 37
                local b = loaderButton("Run  " .. entry.name, 0, y, 1, function()
                    loaderStatus.Text = "Loading " .. entry.name .. "..."
                    task.spawn(function()
                        local success, err = pcall(function()
                            local source = fetchRemote(entry.url)
                            local fn, compileError = loadstring(source)
                            if not fn then error(compileError) end
                            fn()
                        end)
                        if loaderRoot.Parent then
                            loaderStatus.Text = success and ("Executed: " .. entry.name) or ("Error: " .. tostring(err):sub(1, 120))
                        end
                    end)
                end)
                table.insert(loaderRows, b)
                count += 1
            end
        end
        loaderStatus.Text = "Loaded " .. count .. " entries. Click one to run it."
        loaderRoot.Size = UDim2.new(1, -10, 0, math.max(340, 220 + count * 37))
    end)
end
loaderButton("Refresh list", 0, 108, 0.5, refreshLoadstrings)
executorButton = loaderButton("Open Executor", 0.5, 108, 0.5, function()
    if openExecutorWorkspace then openExecutorWorkspace() end
end)
executorButton.Name = "OpenExecutorFromLoadstrings"
loaderButton("Back to Plugins", 0, 143, 1, function()
    currentFolder = nil
    selectPanelTab("Plugins")
end)

-- Built-in executor workspace. Scripts only run when Execute is clicked.
local executorRoot = Instance.new("Frame")
executorRoot.Name = "ExecutorWorkspace"
executorRoot.Size = UDim2.new(1, -18, 1, -16)
executorRoot.BackgroundTransparency = 1
executorRoot.Visible = false
executorRoot.LayoutOrder = 1
executorRoot.Parent = ScreenGui


local function execElement(className, props, role)
    local obj = Instance.new(className)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = executorRoot
    obj.ZIndex = 110
    if role then registerThemeObject(obj, role) end
    return obj
end
local executorTitle = execElement("TextLabel", {
    Size = UDim2.new(1,0,0,25), Position = UDim2.fromOffset(0,0),
    Text = "Script editor", TextSize = 15, Font = activeTheme.boldFont,
    TextColor3 = activeColors.Text, BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
}, "Text")
local tabStrip = execElement("ScrollingFrame", {
    Name = "CodeTabs", Size = UDim2.new(1,-66,0,30),
    Position = UDim2.fromOffset(0,31), BackgroundTransparency = 1,
    ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.fromOffset(0,0)
})
local stripLayout = Instance.new("UIListLayout")
stripLayout.FillDirection = Enum.FillDirection.Horizontal
stripLayout.Padding = UDim.new(0,4)
stripLayout.Parent = tabStrip
stripLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tabStrip.CanvasSize = UDim2.fromOffset(stripLayout.AbsoluteContentSize.X + 8,0)
end)
local function execButton(text, x, y, width, callback)
    local button = execElement("TextButton", {
        Text = text, Font = activeTheme.font, TextSize = 11,
        Size = UDim2.new(width,-4,0,32), Position = UDim2.new(x,0,1,-85),
        BackgroundColor3 = activeColors.Tab, TextColor3 = activeColors.Text,
        BorderColor3 = activeColors.Border or activeColors.Primary
    }, "Tab")
    button.MouseButton1Click:Connect(callback)
    return button
end
local codeEditor = execElement("TextBox", {
    Name = "CodeEditor", Size = UDim2.new(1,-4,1,-184),
    Position = UDim2.fromOffset(0,68),
    Text = "", PlaceholderText = "-- Paste your Luau code here",
    MultiLine = true, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = false, TextSize = 12, Font = Enum.Font.Code,
    TextColor3 = activeColors.Text, BackgroundColor3 = activeColors.Input or activeColors.Surface,
    BorderColor3 = activeColors.Border or activeColors.Primary
}, "Input")
local execStatus = execElement("TextLabel", {
    Size = UDim2.new(1,0,0,42), Position = UDim2.new(0,0,1,-44),
    Text = "Ready. Scripts execute only when you click Execute.",
    TextSize = 11, Font = activeTheme.font, TextColor3 = activeColors.Text,
    BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, "Text")
local savedCodeTabs = Settings.ExecutorTabs
if type(savedCodeTabs) ~= "table" then savedCodeTabs = {} end
local codeTabs = {}
for _, item in ipairs(savedCodeTabs) do
    if type(item) == "table" and type(item.name) == "string" and type(item.code) == "string" then
        table.insert(codeTabs, {name = item.name:sub(1,24), code = item.code})
    end
end
if #codeTabs == 0 then table.insert(codeTabs, {name="Tab 1",code=""}) end
Settings.ExecutorTabs = codeTabs
local selectedCodeTab = math.clamp(tonumber(Settings.ExecutorSelectedTab) or 1,1,#codeTabs)
local tabButtons = {}
local switchingCodeTab = false
local function persistEditor()
    if codeTabs[selectedCodeTab] then
        codeTabs[selectedCodeTab].code = codeEditor.Text
        Settings.ExecutorTabs = codeTabs
        Settings.ExecutorSelectedTab = selectedCodeTab
        schedulePanelSave()
    end
end
local renderCodeTabs
renderCodeTabs = function()
    for _, button in ipairs(tabButtons) do button:Destroy() end
    table.clear(tabButtons)
    for i, tab in ipairs(codeTabs) do
        local button = Instance.new("TextButton")
        button.Name = "CodeTab" .. i
        button.Size = UDim2.fromOffset(75,25)
        button.Text = tab.name
        button.TextSize = 11
        button.Font = activeTheme.font
        button.TextColor3 = activeColors.Text
        button.BackgroundColor3 = i == selectedCodeTab and activeColors.TabActive or activeColors.Tab
        button.Parent = tabStrip
        registerThemeObject(button,"Tab")
        button.MouseButton1Click:Connect(function()
            persistEditor()
            selectedCodeTab = i
            switchingCodeTab = true
            codeEditor.Text = codeTabs[i].code
            switchingCodeTab = false
            Settings.ExecutorSelectedTab = i
            schedulePanelSave()
            renderCodeTabs()
        end)
        table.insert(tabButtons,button)
    end
end
codeEditor:GetPropertyChangedSignal("Text"):Connect(function()
    if not switchingCodeTab then persistEditor() end
end)
switchingCodeTab = true
codeEditor.Text = codeTabs[selectedCodeTab].code
switchingCodeTab = false
renderCodeTabs()
local newTabButton = execElement("TextButton", {
    Text = "+ Tab", Font = activeTheme.font, TextSize = 11,
    Size = UDim2.fromOffset(58,28), Position = UDim2.new(1,-60,0,31),
    BackgroundColor3 = activeColors.Tab, TextColor3 = activeColors.Text
}, "Tab")
newTabButton.MouseButton1Click:Connect(function()
    persistEditor()
    table.insert(codeTabs,{name="Tab " .. (#codeTabs+1),code=""})
    selectedCodeTab = #codeTabs
    switchingCodeTab = true
    codeEditor.Text = ""
    switchingCodeTab = false
    Settings.ExecutorSelectedTab = selectedCodeTab
    schedulePanelSave()
    renderCodeTabs()
end)
execButton("Execute",0,0,0.5,function()
    persistEditor()
    local source = codeEditor.Text
    local compiler = loadstring
    if type(compiler) ~= "function" then
        execStatus.Text = "This executor does not expose loadstring."
        return
    end
    local ok, compiled, compileError = pcall(compiler,source)
    if not ok or type(compiled) ~= "function" then
        execStatus.Text = "Compile error: " .. tostring(compileError or compiled):sub(1,125)
        return
    end
    execStatus.Text = "Executing " .. codeTabs[selectedCodeTab].name .. "..."
    task.spawn(function()
        local success, result = pcall(compiled)
        if executorRoot.Parent then
            execStatus.Text = success and "Executed successfully." or ("Runtime error: " .. tostring(result):sub(1,125))
        end
    end)
end)
execButton("Delete Tab",0.5,0,0.5,function()
    if #codeTabs == 1 then
        execStatus.Text = "Keep at least one tab."
        return
    end
    table.remove(codeTabs,selectedCodeTab)
    selectedCodeTab = math.clamp(selectedCodeTab,1,#codeTabs)
    switchingCodeTab = true
    codeEditor.Text = codeTabs[selectedCodeTab].code
    switchingCodeTab = false
    Settings.ExecutorSelectedTab = selectedCodeTab
    schedulePanelSave()
    renderCodeTabs()
    execStatus.Text = "Tab deleted."
end)

-- The executor is a standalone native panel window, not an embedded tab.
local executorWindow
openExecutorWorkspace = function()
    if executorWindow and executorWindow.Frame and executorWindow.Frame.Parent then
        executorWindow.Show()
        return
    end
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local width = math.max(340, math.min(780, viewport.X - 50))
    local height = math.max(320, math.min(570, viewport.Y - 65))
    executorWindow = createWindow("Simba Executor", width, height)
    local window = executorWindow
    local content = window.Content
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("UIListLayout") or child:IsA("UIPadding") then child:Destroy() end
    end
    content.ScrollBarThickness = 0
    content.ScrollingEnabled = false
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    executorRoot.Parent = content
    executorRoot.Position = UDim2.fromOffset(9,8)
    executorRoot.Visible = true
    for _, element in ipairs(executorRoot:GetDescendants()) do
        if element:IsA("GuiObject") then element.ZIndex = 110 end
    end
    -- Native close button destroys its frame; detach the editor first to preserve tabs.
    window.Frame.Destroying:Connect(function()
        if executorRoot.Parent == content then
            executorRoot.Parent = ScreenGui
            executorRoot.Visible = false
        end
        if executorWindow == window then executorWindow = nil end
    end)
    window.Show()
end

local PluginListLabel = Instance.new("TextLabel")
PluginListLabel.Size = UDim2.new(1, 0, 0, 48)
PluginListLabel.BackgroundTransparency = 1
PluginListLabel.Text = "Plugin Manager\nAdd a plugin script below, then load it."
PluginListLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
PluginListLabel.TextSize = 13
PluginListLabel.Font = Enum.Font.Arial
PluginListLabel.TextWrapped = true
PluginListLabel.TextYAlignment = Enum.TextYAlignment.Top
PluginListLabel.Visible = false
PluginListLabel.Parent = ContentFrame
registerThemeObject(PluginListLabel, "Text")
PluginListLabel.Font = activeTheme.font
-- Plugin manager heading removed from the visible Plugins page

-- Plugin Hub
local PluginHubFrame = Instance.new("ScrollingFrame")
PluginHubFrame.Size = UDim2.new(1, 0, 0, 92)
PluginHubFrame.BackgroundColor3 = Color3.fromRGB(46, 50, 55)
PluginHubFrame.BorderColor3 = Color3.fromRGB(33, 37, 42)
PluginHubFrame.BorderSizePixel = 1
PluginHubFrame.ScrollBarThickness = 5
PluginHubFrame.ScrollBarImageColor3 = Color3.fromRGB(89, 138, 177)
PluginHubFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PluginHubFrame.Visible = false
PluginHubFrame.Parent = ContentFrame
registerThemeObject(PluginHubFrame, "Content")
-- Redundant plugin list hidden; right-click plugin tabs to manage them

local PluginHubLayout = Instance.new("UIListLayout")
PluginHubLayout.Padding = UDim.new(0, 5)
PluginHubLayout.Parent = PluginHubFrame

local PluginHubPadding = Instance.new("UIPadding")
PluginHubPadding.PaddingTop = UDim.new(0, 7)
PluginHubPadding.PaddingLeft = UDim.new(0, 7)
PluginHubPadding.PaddingRight = UDim.new(0, 7)
PluginHubPadding.Parent = PluginHubFrame

PluginHubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PluginHubFrame.CanvasSize = UDim2.new(0, 0, 0, PluginHubLayout.AbsoluteContentSize.Y + 10)
end)

updatePluginHub = function()
    for _, child in ipairs(PluginHubFrame:GetChildren()) do
        if child ~= PluginHubLayout and child ~= PluginHubPadding then
            child:Destroy()
        end
    end
    pruneThemeObjects({})
    
    for pluginName, pluginData in pairs(Plugins) do
        local EntryFrame = Instance.new("Frame")
        EntryFrame.Size = UDim2.new(1, -4, 0, 32)
        EntryFrame.BackgroundColor3 = Color3.fromRGB(68, 73, 79)
        EntryFrame.BorderColor3 = Color3.fromRGB(43, 47, 52)
        EntryFrame.BorderSizePixel = 1
        EntryFrame.Parent = PluginHubFrame
        registerThemeObject(EntryFrame, "Surface")
        
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -72, 1, 0)
        NameLabel.Position = UDim2.new(0, 9, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = pluginName
        NameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        NameLabel.TextSize = 12
        NameLabel.Font = Enum.Font.Arial
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = EntryFrame
        registerThemeObject(NameLabel, "Text")
        NameLabel.Font = activeTheme.font
        
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 54, 0, 22)
        DeleteBtn.Position = UDim2.new(1, -60, 0.5, -11)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(153, 54, 54)
        DeleteBtn.BorderColor3 = Color3.fromRGB(105, 37, 37)
        DeleteBtn.BorderSizePixel = 1
        DeleteBtn.Text = "Delete"
        DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteBtn.TextSize = 10
        DeleteBtn.Font = Enum.Font.ArialBold
        DeleteBtn.Parent = EntryFrame
        registerThemeObject(DeleteBtn, "Danger")

        EntryFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then openPluginContextMenu(pluginName) end
        end)

        DeleteBtn.MouseButton1Click:Connect(function()
            cleanupPluginRuntime(pluginName, pluginData)
            
            local fileName = pluginName:gsub("%s+", "_"):lower() .. ".lua"
            local filePath = pluginSourcePaths[pluginName] or (PLUGIN_FOLDER .. "/" .. fileName)
            if isfile and isfile(filePath) and (delfile or deletefile) then
                pcall(delfile or deletefile, filePath)
                pluginSourcePaths[pluginName] = nil
                print("Deleted plugin file: " .. filePath)
            end
            
            updatePluginHub()
            print("Removed plugin: " .. pluginName)
        end)
    end
    
    if next(Plugins) == nil then
        local NoPluginsLabel = Instance.new("TextLabel")
        NoPluginsLabel.Size = UDim2.new(1, 0, 1, 0)
        NoPluginsLabel.BackgroundTransparency = 1
        NoPluginsLabel.Text = "No plugins loaded yet."
        NoPluginsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        NoPluginsLabel.TextSize = 12
        NoPluginsLabel.Font = Enum.Font.Arial
        NoPluginsLabel.Parent = PluginHubFrame
        registerThemeObject(NoPluginsLabel, "MutedText")
        NoPluginsLabel.Font = activeTheme.font
    end
end

-- Plugin code editor
local EditorFrame = Instance.new("Frame")
EditorFrame.Size = UDim2.new(1, 0, 0, 220)
EditorFrame.BackgroundColor3 = Color3.fromRGB(45, 49, 54)
EditorFrame.BorderColor3 = Color3.fromRGB(33, 37, 42)
EditorFrame.BorderSizePixel = 1
EditorFrame.Visible = false
EditorFrame.Parent = ContentFrame
registerThemeObject(EditorFrame, "Surface")
table.insert(tabs["Plugins"].widgets, EditorFrame)

local EditorScroll = Instance.new("ScrollingFrame")
EditorScroll.Size = UDim2.new(1, -10, 1, -10)
EditorScroll.Position = UDim2.new(0, 5, 0, 5)
EditorScroll.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
EditorScroll.BorderColor3 = Color3.fromRGB(16, 18, 20)
EditorScroll.BorderSizePixel = 1
EditorScroll.ScrollBarThickness = 5
EditorScroll.ScrollBarImageColor3 = Color3.fromRGB(89, 138, 177)
EditorScroll.CanvasSize = UDim2.new(0, 0, 0, 5000)
EditorScroll.Parent = EditorFrame
registerThemeObject(EditorScroll, "Input")

local PluginCodeBox = Instance.new("TextBox")
PluginCodeBox.Size = UDim2.new(1, -10, 0, 5000)
PluginCodeBox.Position = UDim2.new(0, 5, 0, 5)
PluginCodeBox.BackgroundTransparency = 1
PluginCodeBox.Text = ""
PluginCodeBox.PlaceholderText = "-- Write plugin code here..."
PluginCodeBox.TextColor3 = Color3.fromRGB(220, 220, 220)
PluginCodeBox.TextSize = 12
PluginCodeBox.Font = Enum.Font.Code
PluginCodeBox.TextXAlignment = Enum.TextXAlignment.Left
PluginCodeBox.TextYAlignment = Enum.TextYAlignment.Top
PluginCodeBox.MultiLine = true
PluginCodeBox.ClearTextOnFocus = false
PluginCodeBox.TextWrapped = false
PluginCodeBox.Parent = EditorScroll
registerThemeObject(PluginCodeBox, "Text")
PluginCodeBox.Font = Enum.Font.Code

local CodePadding = Instance.new("UIPadding")
CodePadding.PaddingTop = UDim.new(0, 7)
CodePadding.PaddingLeft = UDim.new(0, 8)
CodePadding.Parent = PluginCodeBox

PluginCodeBox:GetPropertyChangedSignal("Text"):Connect(function()
    local lines = select(2, PluginCodeBox.Text:gsub('\n', '\n')) + 1
    local neededHeight = math.max(5000, lines * 15 + 50)
    PluginCodeBox.Size = UDim2.new(1, -10, 0, neededHeight)
    EditorScroll.CanvasSize = UDim2.new(0, 0, 0, neededHeight + 10)
end)

-- Use the same capability scanner for pasted/editor plugins as for disk plugins.
-- Scan before compiling or executing any pasted source.
local function approvePastedPluginSource(source)
    local references = findSensitiveReferences(source)
    local categories = {}
    for category in pairs(references) do
        table.insert(categories, category)
    end
    if #categories == 0 then
        return true
    end
    table.sort(categories)

    -- Pasted source has no trusted filename or stable identity. Always ask for
    -- this specific submission; do not reuse permissions from a prior plugin.
    local details = {}
    for _, category in ipairs(categories) do
        table.insert(details, category .. ":")
        for _, match in ipairs(references[category]) do
            table.insert(details, "  " .. match)
        end
    end
    local decision = createPluginDecisionDialog(
        "Pasted plugin capability warning",
        "The pasted plugin contains sensitive API references. Review them before running it.",
        "Detected source references:\n" .. table.concat(details, "\n")
            .. "\n\nAllow Once runs this pasted source. Deny cancels loading and saving."
            .. "\nThis text scan is not a sandbox and can miss indirect or obfuscated calls.",
        {
            {label = "Allow Once", value = "once", color = Color3.fromRGB(57, 125, 181)},
            {label = "Deny", value = "deny", color = Color3.fromRGB(160, 63, 57)},
        }
    )
    return decision == "once"
end

createButton("Plugins", "Load Plugin", function()
    local code = PluginCodeBox.Text
    
    if code == "" or code == nil then
        warn("Plugin code is empty.")
        return
    end
    
    print("Attempting to load plugin...")

    -- Gate the editor path just like the startup/reload path.
    -- Do this before loadstring, pcall(pluginFunc), Init, or writefile.
    if not approvePastedPluginSource(code) then
        warn("Pasted plugin was denied or its permission dialog was closed; nothing was executed or saved.")
        return
    end

    -- Stage 1: Compile
    -- Keep the source string as the loadstring argument and the protected call
    -- argument as a zero-argument function; this avoids the function/string
    -- union reported by Luau at this call site.
    local compileOk, pluginFunc = pcall(function()
        return loadstring(code)
    end)
    if not compileOk or not pluginFunc then
        warn("Plugin compile error: " .. tostring(pluginFunc))
        return
    end

    -- Stage 2: Execute plugin table
    local execOk, plugin = pcall(pluginFunc)
    if not execOk or not plugin then
        warn("Plugin execution error: " .. tostring(plugin))
        return
    end

    if not plugin.Name or not plugin.Init then
        warn("Plugin is missing the Name or Init field.")
        return
    end

    print("Plugin structure validated: " .. plugin.Name)

    -- Remove old version if exists
    if Plugins[plugin.Name] or tabs[plugin.Name] then
        print("Removing old version of: " .. plugin.Name)
        cleanupPluginRuntime(plugin.Name, Plugins[plugin.Name])
    end

    -- Stage 3: Initialize (isolated)
    local pluginAPI = createPluginAPI(plugin.Name)
    local initOk, initErr = pcall(plugin.Init, pluginAPI)
    if initOk and pluginAPI.PendingRestores then
        for _, restore in ipairs(pluginAPI.PendingRestores) do
            restore()
        end
        table.clear(pluginAPI.PendingRestores)
    end
    if not initOk then
        cleanupPluginRuntime(plugin.Name, plugin)
        warn("Plugin initialization error: " .. tostring(initErr))
        return
    end

    Plugins[plugin.Name] = plugin
    schedulePanelSave()

    -- Save to disk
    local fileName = plugin.Name:gsub("%s+", "_"):lower() .. ".lua"
    local filePath = PLUGIN_FOLDER .. "/" .. fileName
    pluginSourcePaths[plugin.Name] = filePath
    pcall(writefile, filePath, code)
    print("Saved to: " .. filePath)

    updatePluginHub()
    print("Plugin loaded successfully.")
end)


-- Info
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 100)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Retro system\n\nSettings save locally\nTheme and color are remembered\nPlugin support enabled\nPlugin data storage enabled"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Arial
InfoLabel.TextWrapped = true
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Visible = false
InfoLabel.Parent = ContentFrame
registerThemeObject(InfoLabel, "MutedText")
InfoLabel.Font = activeTheme.font
table.insert(tabs["Settings"].widgets, InfoLabel)

local themeOptions = {"Original", "Original Bigger", "Modern Small", "Modern Big"}
local themeDropdownButton = createDropdown("Settings", "UI Theme", themeOptions, activeThemeName, applyTheme)
local colorSchemeOptions = {"Blue", "Ocean", "Forest", "Violet", "Ember"}
local colorSchemeDropdownButton = createDropdown("Settings", "Color Scheme", colorSchemeOptions, activeColorSchemeName, applyColorScheme)
local isCapturingHideBind = false
local hideBindButton
local function getHideBindLabel()
    local binding = Settings.HideBind
    local validKey = type(binding) == "table"
        and binding.kind == "KeyCode"
        and type(binding.name) == "string"
        and Enum.KeyCode[binding.name] ~= nil
    local validMouseButton = type(binding) == "table"
        and binding.kind == "UserInputType"
        and type(binding.name) == "string"
        and string.sub(binding.name, 1, 11) == "MouseButton"
        and Enum.UserInputType[binding.name] ~= nil
    if not validKey and not validMouseButton then
        Settings.HideBind = {kind = "KeyCode", name = "RightShift"}
        binding = Settings.HideBind
    end
    return binding.name
end
hideBindButton = createButton("Settings", "Set Hide Button: " .. getHideBindLabel(), function()
    isCapturingHideBind = true
    hideBindButton.Text = "Press a key or mouse button..."
end)
local pluginApiDocumentation = [=[
RETRO 2013 MODULAR PANEL - PLUGIN API

PLUGIN FORMAT
Plugins are Luau files in the RetroESP_Plugins folder. The panel expects each file
to return a table with a unique Name and an Init function. Init receives a plugin-
scoped API table. Create the plugin tab before adding controls to it.

REQUIRED FIELDS
Name: string - the plugin's display name and settings namespace.
Init(API): function - creates the plugin UI and starts the plugin.
Cleanup(API): optional function - stop tasks or release resources when closing.

UI METHODS
API.CreateTab(name, icon?)
API.CreateToggle(tabName, label, settingPathOrCallback, defaultValue?)
  Use a callback for custom behavior. Callback toggle state is saved automatically.
  Or use a string path such as "Enabled" to store it in API.Settings.Enabled.
API.CreateSlider(tabName, label, min, max, default, callbackOrPath, increment?)
  Callback slider state and string-path values are saved automatically.
API.CreateDropdown(tabName, label, options, default?, callback?)
  The selected option is saved automatically for this plugin.
API.CreateButton(tabName, label, callback)
API.CreateLabel(tabName, text)
API.CreateWindow(title, width?, height?)

OTHER METHODS
API.Notify(title, message, duration?, type?)
API.GetLocalPlayer(), API.GetPlayers(), API.GetCamera(), API.GetWorkspace()
API.CreateScreenUI(name, position, size), API.GetScreenUI(name)
API.RegisterConnection(connection) - register a connection for cleanup.
API.Settings - this plugin's settings table; saved with the panel settings.
API.SavePluginData(name, key, value), API.LoadPluginData(name, key, default?)
API.GetAllPluginData(name), API.ClearPluginData(name)
The explicit data methods are optional. Controls and API.Settings are saved by the
main panel automatically; plugin code does not need its own save/load calls.

SAMPLE PLUGIN
return {
    Name = "Example Plugin",

    Init = function(API)
        API.CreateTab("Example", "")

        local saved = API.Settings
        saved.Message = saved.Message or "Plugin is ready"

        API.CreateLabel("Example", saved.Message)

        API.CreateToggle("Example", "Enable example", function(enabled)
            saved.Enabled = enabled
            print("Example enabled:", enabled)
        end, false)

        API.CreateSlider("Example", "Amount", 1, 10, 5, function(value)
            saved.Amount = value
            print("Amount:", value)
        end, 1)

        API.CreateDropdown("Example", "Mode", {"Quiet", "Normal", "Fast"}, "Normal", function(mode)
            saved.Mode = mode
            print("Mode:", mode)
        end)

        API.CreateButton("Example", "Show message", function()
            API.Notify("Example Plugin", saved.Message, 3, "success")
        end)
    end,

    Cleanup = function(API)
        -- Disconnect plugin connections or stop plugin tasks here.
    end,
}

LOADING
Save this code as a .lua file in RetroESP_Plugins, or paste it into the plugin
editor and click Load Plugin. Use the plugin Name as the settings namespace.
]=]
createButton("Settings", "Copy Plugin API Documentation", function()
    if type(setclipboard) ~= "function" then
        createNotification("Clipboard Unavailable", "This executor does not expose setclipboard.", 3, "error")
        return
    end

    local copied, copyError = pcall(setclipboard, pluginApiDocumentation)
    if copied then
        createNotification("Documentation Copied", "API guide and sample plugin copied to clipboard.", 3, "success")
    else
        createNotification("Copy Failed", tostring(copyError), 3, "error")
    end
end)
createButton("Settings", "Save Settings Now", function()
    if savePanelConfig(true) then
        createNotification("Settings Saved", "Your theme and settings were saved locally.", 2, "success")
    else
        createNotification("Save Failed", "The settings file could not be written.", 3, "error")
    end
end)
createButton("Settings", "Load Saved Settings", function()
    local loaded, loadError = loadPanelConfig()
    if loaded then
        themeDropdownButton.Text = activeThemeName
        colorSchemeDropdownButton.Text = activeColorSchemeName
        hideBindButton.Text = "Set Hide Button: " .. getHideBindLabel()
        createNotification("Settings Loaded", "Saved theme and settings were restored.", 2, "success")
    else
        createNotification("Load Failed", loadError, 3, "error")
    end
end)

if startupLoadingScreen then
    registerThemeObject(startupLoadingScreen.Frame, "Panel")
    registerThemeObject(startupLoadingScreen.Card, "Surface")
    registerThemeObject(startupLoadingScreen.Header, "Header")
    registerThemeObject(startupLoadingScreen.Inset, "Surface")
    registerThemeObject(startupLoadingScreen.Accent, "Primary")
    registerThemeObject(startupLoadingScreen.Badge, "Primary")
    registerThemeObject(startupLoadingScreen.BadgeText, "Text")
    registerThemeObject(startupLoadingScreen.Subtitle, "MutedText")
    registerThemeObject(startupLoadingScreen.Footer, "MutedText")
    registerThemeObject(startupLoadingScreen.ActivityLight, "Primary")
    registerThemeObject(startupLoadingScreen.ActivityText, "MutedText")
    registerThemeObject(startupLoadingScreen.CardFooter, "MutedText")
    registerThemeObject(startupLoadingScreen.Title, "Text")
    registerThemeObject(startupLoadingScreen.StatusLabel, "Text")
    registerThemeObject(startupLoadingScreen.ProgressBarFill.Parent, "Input")
    registerThemeObject(startupLoadingScreen.ProgressBarFill, "Primary")
    registerThemeObject(startupLoadingScreen.PercentLabel, "MutedText")
    registerThemeObject(startupLoadingScreen.CountLabel, "MutedText")
    local loadingHeaderGradient = startupLoadingScreen.Header:FindFirstChildOfClass("UIGradient")
    if loadingHeaderGradient then
        registerThemeGradient(loadingHeaderGradient)
    end
end
setStartupProgress(0.74, "Finishing the interface...", "Applying saved theme and color settings")
task.wait()
applyTheme(activeThemeName)

loadPlugins(true)

-- Store the versions already acknowledged independently of plugin and panel settings.
local CHANGELOG_HISTORY_FILE = PLUGIN_DATA_FOLDER .. "/seen-versions.json"
local function readSeenVersions()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return {}
    end
    local ok, result = pcall(function()
        if not isfile(CHANGELOG_HISTORY_FILE) then return {} end
        return HttpService:JSONDecode(readfile(CHANGELOG_HISTORY_FILE))
    end)
    if not ok or type(result) ~= "table" then return {} end
    -- Support either {versions = {"1.0.0"}} or a simple string array.
    local values = type(result.versions) == "table" and result.versions or result
    local seen = {}
    for _, value in pairs(values) do
        if type(value) == "string" then seen[value] = true end
    end
    return seen
end

local function saveSeenVersion(version)
    local seen = readSeenVersions()
    seen[version] = true
    local versions = {}
    for value in pairs(seen) do table.insert(versions, value) end
    table.sort(versions)
    local ok, err = pcall(function()
        if type(writefile) ~= "function" then error("writefile unavailable") end
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(PLUGIN_DATA_FOLDER) then
            makefolder(PLUGIN_DATA_FOLDER)
        end
        writefile(CHANGELOG_HISTORY_FILE, HttpService:JSONEncode({versions = versions}))
    end)
    if not ok then warn("[Changelog] Could not save version history: " .. tostring(err)) end
    return ok
end

local function showWhatsNew()
    if readSeenVersions()[PANEL_VERSION] or not MainFrame.Parent then return end
    if MainFrame:FindFirstChild("WhatsNewOverlay") then return end

    local overlay = Instance.new("Frame")
    overlay.Name = "WhatsNewOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = activeColors.Panel
    overlay.BorderSizePixel = 0
    overlay.Active = true
    overlay.ZIndex = 50000
    overlay.Parent = MainFrame
    registerThemeObject(overlay, "Panel")

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 49)
    header.BackgroundColor3 = activeColors.Header
    header.BorderSizePixel = 0
    header.ZIndex = 50001
    header.Parent = overlay
    registerThemeObject(header, "Header")

    local heading = Instance.new("TextLabel")
    heading.BackgroundTransparency = 1
    heading.Position = UDim2.fromOffset(15, 5)
    heading.Size = UDim2.new(1, -75, 0, 23)
    heading.Font = activeTheme.boldFont
    heading.TextSize = 17
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.TextColor3 = activeColors.Text
    heading.Text = "What's New  •  v" .. tostring(PANEL_VERSION)
    heading.ZIndex = 50002
    heading.Parent = header
    registerThemeObject(heading, "Text")

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(15, 27)
    subtitle.Size = UDim2.new(1, -75, 0, 16)
    subtitle.Font = activeTheme.font
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextColor3 = activeColors.MutedText
    subtitle.Text = "Release notes • Shown once per version"
    subtitle.ZIndex = 50002
    subtitle.Parent = header
    registerThemeObject(subtitle, "MutedText")

    local close = Instance.new("TextButton")
    close.Name = "CloseWhatsNew"
    close.Size = UDim2.fromOffset(31, 29)
    close.Position = UDim2.new(1, -40, 0, 10)
    close.BackgroundColor3 = activeColors.Danger
    close.BorderSizePixel = 0
    close.Font = activeTheme.boldFont
    close.TextSize = 20
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.ZIndex = 50003
    close.Parent = header
    registerThemeObject(close, "Danger")

    local body = Instance.new("ScrollingFrame")
    body.Name = "ReleaseNotes"
    body.Position = UDim2.fromOffset(12, 61)
    body.Size = UDim2.new(1, -24, 1, -74)
    body.BackgroundColor3 = activeColors.Content
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 5
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.CanvasSize = UDim2.new()
    body.Active = true
    body.ZIndex = 50001
    body.Parent = overlay
    registerThemeObject(body, "Content")
    body.ScrollBarImageColor3 = activeColors.Primary

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 11)
    padding.PaddingBottom = UDim.new(0, 11)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = body
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 7)
    layout.Parent = body

    local categories = {
        {"Added", Color3.fromRGB(101, 213, 149)},
        {"Changed", Color3.fromRGB(114, 182, 255)},
        {"Fixed", Color3.fromRGB(248, 204, 108)},
        {"Removed", Color3.fromRGB(255, 127, 135)},
    }
    for index, category in ipairs(categories) do
        local titleText, accent = category[1], category[2]
        local section = Instance.new("TextLabel")
        section.Name = titleText .. "Section"
        section.Size = UDim2.new(1, -4, 0, 0)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.BackgroundTransparency = 1
        section.Font = activeTheme.font
        section.TextSize = 12
        section.TextWrapped = true
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.TextYAlignment = Enum.TextYAlignment.Top
        section.RichText = true
        section.TextColor3 = activeColors.Text
        section.LayoutOrder = index
        section.ZIndex = 50002
        local lines = {}
        for _, entry in ipairs(PANEL_CHANGELOG[titleText] or {}) do
            table.insert(lines, "• " .. tostring(entry):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
        end
        local hex = accent:ToHex()
        section.Text = '<font color="#' .. hex .. '"><b>' .. titleText .. '</b></font>\n' .. (#lines > 0 and table.concat(lines, "\n") or "Nothing this update.")
        section.Parent = body
        registerThemeObject(section, "Text")
    end

    local closed = false
    close.MouseButton1Click:Connect(function()
        if closed then return end
        closed = true
        saveSeenVersion(PANEL_VERSION)
        overlay:Destroy()
    end)
end

task.spawn(function()
    -- Wait until the startup overlay has disappeared before displaying release notes.
    while ScreenGui.Parent and startupLoadingScreen and startupLoadingScreen.Frame.Parent do
        task.wait(0.1)
    end
    if ScreenGui.Parent then showWhatsNew() end
end)

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(15)
        if ScreenGui.Parent then
            savePanelConfig()
        end
    end
end)
-- Minimize functionality
local minimizeTween
local minimizeTweenInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setMinimized(shouldMinimize)
    isMinimized = shouldMinimize

    if minimizeTween then
        minimizeTween:Cancel()
        minimizeTween = nil
    end

    if isMinimized then
        MainFrame:SetAttribute("SimbaResizeDisabled", true)
        MinimizeBtn.Text = "+"
    else
        MainFrame:SetAttribute("SimbaResizeDisabled", false)
        TabBar.Visible = true
        ContentFrame.Visible = true
        MinimizeBtn.Text = "_"
    end

    local expandedWidth = MainFrame:GetAttribute("SimbaExpandedWidth") or activeTheme.width
    local expandedHeight = MainFrame:GetAttribute("SimbaExpandedHeight") or activeTheme.height
    local targetSize = isMinimized
        and UDim2.fromOffset(expandedWidth, activeTheme.headerHeight)
        or UDim2.fromOffset(expandedWidth, expandedHeight)

    local activeTween = TweenService:Create(MainFrame, minimizeTweenInfo, {
        Size = targetSize
    })
    minimizeTween = activeTween

    activeTween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed and isMinimized then
            TabBar.Visible = false
            ContentFrame.Visible = false
        end
        if minimizeTween == activeTween then
            minimizeTween = nil
        end
    end)

    activeTween:Play()
end

MinimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not isMinimized)
end)

-- The selected keyboard or mouse bind hides/restores the panel without stopping plugins.
table.insert(connections, UserInputService.InputBegan:Connect(function(input)
    if isCapturingHideBind then
        local binding
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            binding = {kind = "KeyCode", name = input.KeyCode.Name}
        elseif string.sub(input.UserInputType.Name, 1, 11) == "MouseButton" then
            binding = {kind = "UserInputType", name = input.UserInputType.Name}
        end

        if binding then
            Settings.HideBind = binding
            isCapturingHideBind = false
            hideBindButton.Text = "Set Hide Button: " .. binding.name
            schedulePanelSave()
            createNotification("Hide Button Set", "Menu hide button: " .. binding.name, 2, "success")
        end
        return
    end

    local binding = Settings.HideBind
    if type(binding) == "table" then
        local matchesKey = binding.kind == "KeyCode"
            and Enum.KeyCode[binding.name] ~= nil
            and input.KeyCode == Enum.KeyCode[binding.name]
        local matchesMouse = binding.kind == "UserInputType"
            and Enum.UserInputType[binding.name] ~= nil
            and input.UserInputType == Enum.UserInputType[binding.name]
        if matchesKey or matchesMouse then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end))
-- Smooth dragging for the main panel.
local function bringMainToFront()
        -- Bring main window to front (only update if needed)
        local newZ = windowZIndex + 10
        if MainFrame.ZIndex ~= newZ then
            windowZIndex = newZ
            MainFrame.ZIndex = windowZIndex
            TopBar.ZIndex = windowZIndex + 1
            Title.ZIndex = windowZIndex + 2
            MinimizeBtn.ZIndex = windowZIndex + 2
            CloseBtn.ZIndex = windowZIndex + 2
            TabBar.ZIndex = windowZIndex + 1
            ContentFrame.ZIndex = windowZIndex + 1
        end
end

attachSmoothDrag(TopBar, MainFrame, connections, bringMainToFront)
--[[ Resize feature temporarily disabled; implementation retained.
attachWindowResize(MainFrame, 360, 260, connections, function(w, h)
    MainFrame:SetAttribute("SimbaExpandedWidth", w)
    MainFrame:SetAttribute("SimbaExpandedHeight", h)
end, bringMainToFront)
]]
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bringMainToFront()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Disconnect all main connections
    for _, connection in pairs(connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    -- Stop plugin callbacks and resources before destroying the panel.
    for pluginName, plugin in pairs(Plugins) do
        cleanupPluginRuntime(pluginName, plugin)
    end
    
    -- Clean up ESP objects
    for player, espData in pairs(ESPObjects) do
        if espData.Drawings then
            for _, drawing in pairs(espData.Drawings) do
                if drawing and drawing.Remove then
                    pcall(function() drawing:Remove() end)
                end
            end
        end
    end

    savePanelConfig(true)
    
    -- Destroy all custom windows
    for _, obj in ipairs(ScreenGui:GetChildren()) do
        if obj:IsA("Frame") and obj ~= MainFrame then
            obj:Destroy()
        end
    end
    
    -- Destroy the main GUI
    ScreenGui:Destroy()
    
    print("Panel closed and plugins cleaned up.")
end)
tabs["Plugins"].button.BackgroundColor3 = activeColors.TabActive
tabs["Plugins"].button.TextColor3 = activeColors.Text
for _, widget in pairs(tabs["Plugins"].widgets) do widget.Visible = true end
currentTab = "Plugins"
end)

if not startupBuildOk then
    warn("Panel startup failed: " .. tostring(startupBuildError))
    showPluginDiagnostic("Control Panel", "startup", startupBuildError)
    finishStartupLoading("Panel construction stopped after an error.")
end
