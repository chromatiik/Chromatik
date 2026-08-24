local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local run = game:GetService("RunService")
local stats = game:GetService("Stats")
local coregui = game:GetService("CoreGui")
local tween_service = game:GetService("TweenService")
local marketplace = game:GetService("MarketplaceService")
local text_service = game:GetService("TextService")
local content_provider = game:GetService("ContentProvider")

local vec2 = Vector2.new
local dim2 = UDim2.new
local dim = UDim.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = gui_service:GetGuiInset().Y

local clamp = math.clamp
local floor = math.floor
local min = math.min
local max = math.max
local abs = math.abs

local insert = table.insert
local find = table.find
local remove = table.remove
local concat = table.concat

getgenv().Chromatik = getgenv().Chromatik or {}
local library = {
    directory = "Chromatik",
    folders = {
        "/fonts",
        "/configs",
        "/assets",
    },
    flags = {},
    config_flags = {},
    connections = {},
    notifications = { notifs = {} },
    current_open = nil,
    version = "1.4.1",
    theme_dirty = false,
    silent = false,
    MenuKeybind = Enum.KeyCode.RightControl,
    MenuKeyName = "RCtrl",
    keybind_registry = {},
    KeybindListInstance = nil,
    EspPreviewInstance = nil,
    author = "chromatik",
}

library.__index = library

local function ensure_folders()
    for _, path in next, library.folders do
        pcall(makefolder, library.directory .. path)
    end
end
ensure_folders()

function library:SetConfigDirectory(path)
    if type(path) ~= "string" or path == "" then return end

    path = path:gsub("^/+", ""):gsub("/+$", "")
    library.directory = path
    ensure_folders()
end

local flags = library.flags
local config_flags = library.config_flags
local notifications = library.notifications

local themes = {
    preset = {
        accent = rgb(155, 150, 219),
        background = rgb(14, 14, 16),
        section = rgb(22, 22, 24),
        element = rgb(25, 25, 29),
        light = rgb(33, 33, 35),
        hover = rgb(39, 39, 43),
        line = rgb(21, 21, 23),
        text = rgb(255, 255, 255),
        dimtext = rgb(72, 72, 73),
        dimicon = rgb(72, 72, 73),
    },
    utility = {
        accent = {
            BackgroundColor3 = {},
            TextColor3 = {},
            ImageColor3 = {},
            ScrollBarImageColor3 = {},
            Color = {},
        },
    },
}

local keys = {
    [Enum.KeyCode.LeftShift] = "LS",
    [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC",
    [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent",
    [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA",
    [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.KeypadOne] = "Num1",
    [Enum.KeyCode.KeypadTwo] = "Num2",
    [Enum.KeyCode.KeypadThree] = "Num3",
    [Enum.KeyCode.KeypadFour] = "Num4",
    [Enum.KeyCode.KeypadFive] = "Num5",
    [Enum.KeyCode.KeypadSix] = "Num6",
    [Enum.KeyCode.KeypadSeven] = "Num7",
    [Enum.KeyCode.KeypadEight] = "Num8",
    [Enum.KeyCode.KeypadNine] = "Num9",
    [Enum.KeyCode.KeypadZero] = "Num0",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.Tilde] = "~",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.RightParenthesis] = ")",
    [Enum.KeyCode.LeftParenthesis] = "(",
    [Enum.KeyCode.Semicolon] = ";",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Asterisk] = "*",
    [Enum.KeyCode.Plus] = "+",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
    [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC",
}

local fonts = {}
do
    local function Register_Font(Name, Weight, Style, Asset)
        local path = library.directory .. "/fonts/" .. Asset.Id
        if not isfile(path) then
            pcall(function()
                writefile(path, Asset.Font)
            end)
        end

        local jsonPath = library.directory .. "/fonts/" .. Name .. ".font"
        pcall(delfile, jsonPath)

        local Data = {
            name = Name,
            faces = {
                {
                    name = "Normal",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(path),
                },
            },
        }

        writefile(jsonPath, http_service:JSONEncode(Data))
        return getcustomasset(jsonPath)
    end

    local MediumOk, Medium = pcall(function()
        return Register_Font("Medium", 200, "Normal", {
            Id = "Medium.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"),
        })
    end)

    local SemiOk, SemiBold = pcall(function()
        return Register_Font("SemiBold", 200, "Normal", {
            Id = "SemiBold.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"),
        })
    end)

    fonts = {
        small = Font.new(MediumOk and Medium or Font.fromEnum(Enum.Font.GothamMedium).Family, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        font = Font.new(SemiOk and SemiBold or Font.fromEnum(Enum.Font.GothamMedium).Family, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }
end

local IconPack
pcall(function()
    local Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
    IconPack = loadstring(game:HttpGetAsync(Url))()
    IconPack.SetIconsType("lucide")
end)

local function ResolveIcon(Icon)
    if type(Icon) == "number" then
        return "rbxassetid://" .. Icon
    end
    if type(Icon) ~= "string" then
        return "rbxassetid://0"
    end
    if string.match(Icon, "^rbxassetid://") or string.match(Icon, "^rbxasset://") then
        return Icon
    end
    if string.match(Icon, "^%d+$") then
        return "rbxassetid://" .. Icon
    end
    if IconPack then
        local Ok, Result = pcall(function()
            return IconPack.GetIcon(Icon)
        end)
        if Ok and Result and Result ~= "rbxassetid://0" then
            return Result
        end
    end
    return "rbxassetid://0"
end

local function ApplyIcon(Object, Icon)
    if not Icon then return end
    local Image = ResolveIcon(Icon)
    Object.Image = Image
end

function library:tween(obj, properties, easing_style, time)
    local tween = tween_service:Create(
        obj,
        TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0),
        properties
    )
    tween:Play()
    return tween
end

function library:connection(signal, callback)
    local connection = signal:Connect(callback)
    insert(library.connections, connection)
    return connection
end

function library:create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do
        ins[prop] = value
    end
    return ins
end

function library:round(number, float)
    local multiplier = 1 / (float or 1)
    return floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
    if not instance then return end
    local bucket = themes.utility[theme] and themes.utility[theme][property]
    if not bucket then

        if themes.utility[theme] then
            themes.utility[theme][property] = {}
            bucket = themes.utility[theme][property]
        else
            return
        end
    end
    insert(bucket, instance)
end

function library:update_theme(theme, color)

    local buckets = themes.utility[theme]
    if buckets then
        for property_name, bucket in pairs(buckets) do
            for i = #bucket, 1, -1 do
                local object = bucket[i]
                if object and object.Parent then
                    pcall(function()
                        object[property_name] = color
                    end)
                else
                    table.remove(bucket, i)
                end
            end
        end
    end
    themes.preset[theme] = color

    if theme == "accent" and library._active_tab_icon and library._active_tab_icon.Parent then
        pcall(function()
            library._active_tab_icon.ImageColor3 = color
        end)
    end

    if theme == "accent" and library._toggle_hooks then
        for _, switch in pairs(library._toggle_hooks) do
            if switch and switch.Parent then
                pcall(function()
                    switch.BackgroundColor3 = color
                end)
            end
        end
    end
end

function library:close_element(new_path)
    local open_element = library.current_open
    if open_element and new_path ~= open_element then
        if open_element.set_visible then
            open_element.set_visible(false)
        end
        open_element.open = false
    end
    if new_path ~= open_element then
        library.current_open = new_path or nil
    end
end

function library:mouse_in_frame(uiobject)
    local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
    local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
    return (y_cond and x_cond)
end

function library:draggify(frame)
    local dragging = false
    local start_size = frame.Position
    local start

    frame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local relY = input.Position.Y - frame.AbsolutePosition.Y
        if relY > 56 then return end
        dragging = true
        start = input.Position
        start_size = frame.Position
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            -- AbsoluteSize respects UIScale so the menu does not jump/squash off-screen
            local aw = math.max(frame.AbsoluteSize.X, 50)
            local ah = math.max(frame.AbsoluteSize.Y, 50)
            local nx = start_size.X.Offset + (input.Position.X - start.X)
            local ny = start_size.Y.Offset + (input.Position.Y - start.Y)
            nx = clamp(nx, 0, math.max(0, viewport_x - aw))
            ny = clamp(ny, 0, math.max(0, viewport_y - ah))
            frame.Position = dim2(0, nx, 0, ny)
            library:close_element()
            pcall(function()
                local esp = library.EspPreviewInstance
                if esp and type(esp.DockToMain) == "function" then
                    esp.DockToMain()
                end
            end)
        end
    end)
end

function library:resizify(frame)
    local Frame = Instance.new("TextButton")
    Frame.Position = dim2(1, -10, 1, -10)
    Frame.Size = dim2(0, 10, 0, 10)
    Frame.BackgroundTransparency = 1
    Frame.Text = ""
    Frame.Parent = frame

    local resizing = false
    local start_size
    local start
    local og_size = frame.Size

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            start = input.Position
            start_size = frame.Size
        end
    end)

    Frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            -- keep roughly same aspect so layout does not squash
            local minW = math.max(og_size.X.Offset * 0.55, 320)
            local minH = math.max(og_size.Y.Offset * 0.55, 280)
            local newW = clamp(start_size.X.Offset + (input.Position.X - start.X), minW, viewport_x - 8)
            local aspect = (og_size.Y.Offset > 0) and (og_size.Y.Offset / og_size.X.Offset) or (565 / 700)
            local newH = clamp(newW * aspect, minH, viewport_y - 8)
            frame.Size = dim2(0, newW, 0, newH)
        end
    end)
end

function library:next_flag()
    local index = 0
    for _ in flags do
        index = index + 1
    end
    return string.format("flagnumber%s", index + 1)
end

function library:convert(str)
    local values = {}
    for value in string.gmatch(str, "[^,]+") do
        insert(values, tonumber(value))
    end
    if #values == 4 then
        return unpack(values)
    end
end

function library:convert_enum(enum)
    local enum_parts = {}
    for part in string.gmatch(enum, "[%w_]+") do
        insert(enum_parts, part)
    end
    local enum_table = Enum
    for i = 2, #enum_parts do
        enum_table = enum_table[enum_parts[i]]
    end
    return enum_table
end

function library:unload_menu()
    if library.KeybindListInstance then
        pcall(function()
            if library.KeybindListInstance.Destroy then
                library.KeybindListInstance.Destroy()
            elseif library.KeybindListInstance.Gui then
                library.KeybindListInstance.Gui:Destroy()
            end
        end)
        library.KeybindListInstance = nil
    end
    if library.EspPreviewInstance then
        pcall(function()
            if library.EspPreviewInstance.Destroy then
                library.EspPreviewInstance.Destroy()
            elseif library.EspPreviewInstance.Gui then
                library.EspPreviewInstance.Gui:Destroy()
            end
        end)
        library.EspPreviewInstance = nil
    end
    library.keybind_registry = {}
    if library["items"] then
        library["items"]:Destroy()
    end
    if library["other"] then
        library["other"]:Destroy()
    end
    if library["watermark_gui"] then
        library["watermark_gui"]:Destroy()
    end
    for _, connection in library.connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    getgenv().Chromatik = nil
    getgenv().Aether = nil
end

function library:get_config(Created)
    local Config = {}
    for _, v in next, flags do
        if type(v) == "table" and v.key then
            Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
        elseif type(v) == "table" and v["Transparency"] and v["Color"] then
            Config[_] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
        else
            Config[_] = v
        end
    end

    Config.__accent = themes.preset.accent:ToHex()
    Config.__created = Created or os.date("%d.%m.%Y %H:%M")
    Config.__version = library.version
    Config.__creator = lp.DisplayName

    return http_service:JSONEncode(Config)
end

function library:load_config(config_json)
    local Ok, config = pcall(function()
        return http_service:JSONDecode(config_json)
    end)
    if not Ok or type(config) ~= "table" then
        return false
    end

    library.silent = true
    for _, v in config do
        local function_set = library.config_flags[_]
        if not function_set then
            continue
        end
        if type(v) == "table" and v["Transparency"] and v["Color"] then
            function_set(hex(v["Color"]), v["Transparency"])
        elseif type(v) == "table" and v["active"] then
            function_set(v)
        else
            function_set(v)
        end
    end

    if type(config.__accent) == "string" then
        local OkColor, Color = pcall(hex, config.__accent)
        if OkColor then
            library:update_theme("accent", Color)
        end
    end

    library.silent = false
    return true
end

function library:SaveConfigFile(Name)
    if not writefile then
        return false
    end
    writefile(library.directory .. "/configs/" .. Name .. ".json", library:get_config())
    return true
end

function library:LoadConfigFile(Name)
    if not isfile then
        return false
    end
    local Path = library.directory .. "/configs/" .. Name .. ".json"
    if not isfile(Path) then
        return false
    end
    return library:load_config(readfile(Path))
end

function library:ListConfigs()
    local Result = {}
    if not listfiles then
        return Result
    end
    for _, File in listfiles(library.directory .. "/configs") do
        if string.sub(File, -5) ~= ".json" then
            continue
        end
        local Name = string.match(File, "([^/\\]+)%.json$")
        if Name then
            insert(Result, Name)
        end
    end
    return Result
end

function library:window(properties)
    local cfg = {
        suffix = properties.suffix or properties.Suffix or "",
        name = properties.name or properties.Name or "Chromatik",
        game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Chromatik for Roblox",
        author = properties.author or properties.Author or library.author or "chromatik",
        size = properties.size or properties.Size or dim2(0, 700, 0, 565),
        selected_tab = nil,
        items = {},
    }

    if properties.author or properties.Author then
        library.author = cfg.author
    end

    library["items"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })



    library["other"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    library["cache"] = library:create("Folder", {
        Parent = library["other"],
        Name = "\0",
    })

    local items = cfg.items
    do
        items["main"] = library:create("Frame", {
            Parent = library["items"],
            Size = cfg.size,
            Name = "\0",
            Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })
        items["main"].Position = dim2(0, items["main"].AbsolutePosition.X, 0, items["main"].AbsolutePosition.Y)

        library:create("UICorner", {
            Parent = items["main"],
            CornerRadius = dim(0, 10),
        })

        library:create("UIStroke", {
            Color = rgb(23, 23, 29),
            Parent = items["main"],
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })

        items["side_frame"] = library:create("Frame", {
            Parent = items["main"],
            BackgroundTransparency = 1,
            Name = "\0",
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 196, 1, -25),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })

        library:create("Frame", {
            AnchorPoint = vec2(1, 0),
            Parent = items["side_frame"],
            Position = dim2(1, 0, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 1, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })

        items["button_holder"] = library:create("Frame", {
            Parent = items["side_frame"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 60),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, -60),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.button_holder = items["button_holder"]

        library:create("UIListLayout", {
            Parent = items["button_holder"],
            Padding = dim(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 16),
            PaddingBottom = dim(0, 36),
            Parent = items["button_holder"],
            PaddingRight = dim(0, 11),
            PaddingLeft = dim(0, 10),
        })

        items["title"] = library:create("TextLabel", {
            FontFace = fonts.font,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["side_frame"],
            Name = "\0",
            Text = string.format('<u>%s</u><font color = "rgb(255, 255, 255)">%s</font>', cfg.name, cfg.suffix),
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 70),
            TextColor3 = themes.preset.accent,
            BorderSizePixel = 0,
            RichText = true,
            TextSize = 30,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        library:apply_theme(items["title"], "accent", "TextColor3")

        items["multi_holder"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -196, 0, 56),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.multi_holder = items["multi_holder"]

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["multi_holder"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })


        items["profile_btn"] = library:create("TextButton", {
            Parent = items["multi_holder"], Name = "\0", Text = "", AutoButtonColor = false,
            BackgroundTransparency = 1, AnchorPoint = vec2(1, 0.5),
            Position = dim2(1, -14, 0.5, 0), Size = dim2(0, 32, 0, 32), ZIndex = 6, BorderSizePixel = 0,
        })
        items["profile_avatar"] = library:create("ImageLabel", {
            Parent = items["profile_btn"], Name = "\0", BackgroundColor3 = themes.preset.light,
            Size = dim2(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 6,
        })
        library:create("UICorner", { Parent = items["profile_avatar"], CornerRadius = dim(1, 0) })

        items["profile_ring"] = library:create("UIStroke", {
            Parent = items["profile_avatar"], Color = themes.preset.accent, Thickness = 1.5,
        })
        library:apply_theme(items["profile_ring"], "accent", "Color")
        task.spawn(function()
            local ok, content = pcall(function()
                return players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and content then items["profile_avatar"].Image = content end
        end)

        -- ============================================================
        -- Header search: icon button expands into a pill-shaped search bar
        -- ============================================================
        items["search_btn"] = library:create("TextButton", {
            Parent = items["multi_holder"],
            Name = "\0",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = vec2(1, 0.5),
            Position = dim2(1, -52, 0.5, 0),
            Size = dim2(0, 32, 0, 32),
            ZIndex = 6,
            BorderSizePixel = 0,
        })
        items["search_icon"] = library:create("ImageLabel", {
            Parent = items["search_btn"],
            Name = "\0",
            BackgroundTransparency = 1,
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 16, 0, 16),
            Image = (function() local i = ResolveIcon("search"); if not i or i == "rbxassetid://0" then return "rbxassetid://6034287511" end return i end)(),
            ImageColor3 = themes.preset.dimicon,
            ZIndex = 7,
            BorderSizePixel = 0,
        })

        items["search_bar"] = library:create("Frame", {
            Parent = items["multi_holder"],
            Name = "\0",
            BackgroundColor3 = themes.preset.element,
            BorderSizePixel = 0,
            AnchorPoint = vec2(1, 0.5),
            Position = dim2(1, -14, 0.5, 0),
            Size = dim2(0, 0, 0, 30),
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 15,
        })
        library:create("UICorner", { Parent = items["search_bar"], CornerRadius = dim(1, 0) })
        local searchStroke = library:create("UIStroke", {
            Parent = items["search_bar"],
            Color = themes.preset.line,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })

        items["search_bar_icon"] = library:create("ImageLabel", {
            Parent = items["search_bar"],
            Name = "\0",
            BackgroundTransparency = 1,
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 12, 0.5, 0),
            Size = dim2(0, 14, 0, 14),
            Image = items["search_icon"].Image,
            ImageColor3 = themes.preset.accent,
            ZIndex = 16,
            BorderSizePixel = 0,
        })
        library:apply_theme(items["search_bar_icon"], "accent", "ImageColor3")

        items["search_box"] = library:create("TextBox", {
            Parent = items["search_bar"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 34, 0, 0),
            Size = dim2(1, -66, 1, 0),
            FontFace = fonts.small,
            TextSize = 13,
            TextColor3 = themes.preset.text,
            PlaceholderText = "Search...",
            PlaceholderColor3 = themes.preset.dimtext,
            Text = "",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
            BorderSizePixel = 0,
        })

        items["search_close"] = library:create("TextButton", {
            Parent = items["search_bar"],
            Name = "\0",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = vec2(1, 0.5),
            Position = dim2(1, -10, 0.5, 0),
            Size = dim2(0, 22, 0, 22),
            ZIndex = 17,
            BorderSizePixel = 0,
        })
        local searchCloseIcon = library:create("ImageLabel", {
            Parent = items["search_close"],
            Name = "\0",
            BackgroundTransparency = 1,
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 12, 0, 12),
            ImageColor3 = themes.preset.dimtext,
            ZIndex = 18,
            BorderSizePixel = 0,
        })
        ApplyIcon(searchCloseIcon, "x")
        items["search_close"].MouseEnter:Connect(function()
            library:tween(searchCloseIcon, { ImageColor3 = themes.preset.text }, Enum.EasingStyle.Quint, 0.15)
        end)
        items["search_close"].MouseLeave:Connect(function()
            library:tween(searchCloseIcon, { ImageColor3 = themes.preset.dimtext }, Enum.EasingStyle.Quint, 0.15)
        end)

        items["search_empty"] = library:create("TextLabel", {
            Parent = items["tab_holder"] or items["multi_holder"],
            Name = "\0",
            FontFace = fonts.font,
            Text = "No results found",
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 30),
            Position = dim2(0, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Center,
            Visible = false,
            BorderSizePixel = 0,
            ZIndex = 20,
        })

        local searchExpanded = false
        local searchRowCache = {}

        local function collectSearchRows()
            searchRowCache = {}
            local main = items["main"]
            if not main then return end
            for _, d in ipairs(main:GetDescendants()) do
                if d:IsA("TextLabel") and d.TextSize and d.TextSize <= 14 then
                    local t = tostring(d.Text or "")
                    if t ~= "" and #t <= 48 then
                        local row = d.Parent
                        if row and row:IsA("Frame") then
                            local h = row.AbsoluteSize.Y
                            if h >= 18 and h <= 52 then
                                searchRowCache[row] = true
                            end
                        end
                    end
                end
            end
        end

        local searchSnap = {}
        local function applyMenuSearch(query)
            query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
            local main = items["main"]
            if query == "" then
                for inst, vis in pairs(searchSnap) do
                    if inst and inst.Parent then
                        pcall(function() inst.Visible = vis end)
                    end
                end
                for row in pairs(searchRowCache) do
                    if row and row.Parent then row.Visible = true end
                end
                items["search_empty"].Visible = false
                return
            end
            if next(searchSnap) == nil and main then
                for _, d in ipairs(main:GetDescendants()) do
                    if d:IsA("GuiObject") then searchSnap[d] = d.Visible end
                end
            end
            if next(searchRowCache) == nil then
                collectSearchRows()
            end
            local matches = {}
            for row in pairs(searchRowCache) do
                if row and row.Parent then
                    local match = false
                    for _, c in ipairs(row:GetDescendants()) do
                        if c:IsA("TextLabel") or c:IsA("TextButton") then
                            local t = tostring(c.Text or ""):lower()
                            if t ~= "" and t:find(query, 1, true) then
                                match = true
                                break
                            end
                        end
                    end
                    if match then
                        matches[row] = true
                        local p = row.Parent
                        while p and p ~= main do
                            if p:IsA("GuiObject") then matches[p] = true end
                            p = p.Parent
                        end
                    end
                end
            end
            -- also match section/tab titles
            if main then
                for _, d in ipairs(main:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton")) then
                        local t = tostring(d.Text or ""):lower()
                        if t ~= "" and #t <= 40 and t:find(query, 1, true) then
                            matches[d] = true
                            local p = d.Parent
                            while p and p ~= main do
                                if p:IsA("GuiObject") then matches[p] = true end
                                p = p.Parent
                            end
                        end
                    end
                end
            end
            local anyVisible = false
            for row in pairs(searchRowCache) do
                if row and row.Parent then
                    local vis = matches[row] == true
                    row.Visible = vis
                    if vis then anyVisible = true end
                end
            end
            for m in pairs(matches) do
                if m and m.Parent then
                    pcall(function() m.Visible = true end)
                    anyVisible = true
                end
            end
            items["search_empty"].Visible = not anyVisible
        end

        local function setSearchExpanded(on)
            searchExpanded = on == true
            if searchExpanded then
                collectSearchRows()
                items["search_bar"].Visible = true
                items["search_btn"].Visible = false
                library:tween(items["search_icon"], { ImageColor3 = themes.preset.accent }, Enum.EasingStyle.Quint, 0.15)
                library:tween(items["search_bar"], { Size = dim2(0, 230, 0, 30) }, Enum.EasingStyle.Quint, 0.22)
                task.defer(function()
                    pcall(function() items["search_box"]:CaptureFocus() end)
                end)
            else
                items["search_box"].Text = ""
                applyMenuSearch("")
                library:tween(items["search_icon"], { ImageColor3 = themes.preset.dimicon }, Enum.EasingStyle.Quint, 0.15)
                library:tween(items["search_bar"], { Size = dim2(0, 0, 0, 30) }, Enum.EasingStyle.Quint, 0.15)
                task.delay(0.16, function()
                    if not searchExpanded then
                        items["search_bar"].Visible = false
                        items["search_btn"].Visible = true
                    end
                end)
            end
        end

        items["search_box"].Focused:Connect(function()
            library:tween(searchStroke, { Color = themes.preset.accent, Thickness = 1.5 }, Enum.EasingStyle.Quint, 0.15)
        end)
        items["search_box"].FocusLost:Connect(function()
            library:tween(searchStroke, { Color = themes.preset.line, Thickness = 1 }, Enum.EasingStyle.Quint, 0.15)
        end)

        items["search_btn"].MouseButton1Click:Connect(function()
            setSearchExpanded(true)
        end)
        items["search_close"].MouseButton1Click:Connect(function()
            setSearchExpanded(false)
        end)
        items["search_box"]:GetPropertyChangedSignal("Text"):Connect(function()
            applyMenuSearch(items["search_box"].Text)
        end)
        items["search_btn"].MouseEnter:Connect(function()
            library:tween(items["search_icon"], { ImageColor3 = themes.preset.text }, Enum.EasingStyle.Quint, 0.15)
        end)
        items["search_btn"].MouseLeave:Connect(function()
            if not searchExpanded then
                library:tween(items["search_icon"], { ImageColor3 = themes.preset.dimicon }, Enum.EasingStyle.Quint, 0.15)
            end
        end)

        cfg.set_search = setSearchExpanded
        cfg.apply_search = applyMenuSearch
        library.MenuSearch = {
            SetOpen = setSearchExpanded,
            Apply = applyMenuSearch,
            IsOpen = function() return searchExpanded end,
        }

        local profileOpen = false
        local profilePopup = library:create("Frame", {
            Parent = items["main"], Name = "\0", Size = dim2(0, 240, 0, 0),
            BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, Visible = false,
            ZIndex = 80, ClipsDescendants = true, AnchorPoint = vec2(1, 0), Position = dim2(1, -10, 0, 56),
        })
        library:create("UICorner", { Parent = profilePopup, CornerRadius = dim(0, 10) })

        local function rebuildProfile()
            for _, ch in profilePopup:GetChildren() do
                if not ch:IsA("UICorner") then ch:Destroy() end
            end
            local display = lp.DisplayName or lp.Name
            local uname = "@" .. (lp.Name or "unknown")
            local uid = tostring(lp.UserId or 0)
            local age = "Unknown"
            pcall(function() age = tostring(lp.AccountAge or 0) .. " days" end)

            local bigAv = library:create("ImageLabel", {
                Parent = profilePopup, BackgroundColor3 = themes.preset.light,
                Position = dim2(0, 14, 0, 14), Size = dim2(0, 42, 0, 42),
                BorderSizePixel = 0, Image = items["profile_avatar"].Image, ZIndex = 81,
            })
            library:create("UICorner", { Parent = bigAv, CornerRadius = dim(1, 0) })
            local bigRing = library:create("UIStroke", { Parent = bigAv, Color = themes.preset.accent, Thickness = 1.5 })
            library:apply_theme(bigRing, "accent", "Color")

            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = display, TextSize = 15,
                TextColor3 = themes.preset.text, BackgroundTransparency = 1,
                Position = dim2(0, 66, 0, 16), Size = dim2(1, -80, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = uname, TextSize = 13,
                TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                Position = dim2(0, 66, 0, 36), Size = dim2(1, -80, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            local function infoRow(y, lab, val)
                library:create("TextLabel", {
                    Parent = profilePopup, FontFace = fonts.font, Text = lab, TextSize = 13,
                    TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                    Position = dim2(0, 14, 0, y), Size = dim2(0, 100, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
                })
                library:create("TextLabel", {
                    Parent = profilePopup, FontFace = fonts.font, Text = val, TextSize = 13,
                    TextColor3 = themes.preset.text, BackgroundTransparency = 1,
                    Position = dim2(0, 110, 0, y), Size = dim2(1, -124, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0, ZIndex = 81,
                })
            end
            infoRow(68, "User ID", uid)
            infoRow(90, "Account age", age)

            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = "Menu toggle", TextSize = 13,
                TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                Position = dim2(0, 14, 0, 118), Size = dim2(0, 100, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            local currentKey = library.MenuKeybind or Enum.KeyCode.RightControl
            local keyName = library.MenuKeyName or keys[currentKey] or (typeof(currentKey) == "EnumItem" and currentKey.Name) or "RCtrl"
            local keyBox = library:create("TextButton", {
                Parent = profilePopup, FontFace = fonts.font, Text = keyName, TextSize = 12,
                TextColor3 = themes.preset.text, AutoButtonColor = false,
                BackgroundColor3 = themes.preset.light,
                Position = dim2(1, -70, 0, 114), Size = dim2(0, 56, 0, 22),
                BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("UICorner", { Parent = keyBox, CornerRadius = dim(0, 4) })
            library.ProfileKeyBox = keyBox
            local binding = false
            keyBox.MouseButton1Click:Connect(function()
                if binding then return end
                binding = true
                keyBox.Text = "..."
                local conn
                conn = uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        library.MenuKeybind = input.KeyCode
                        local nm = keys[input.KeyCode] or input.KeyCode.Name
                        keyBox.Text = nm
                        if config_flags["menu_bind"] then
                            pcall(function() config_flags["menu_bind"](input.KeyCode) end)
                        end
                        binding = false
                        conn:Disconnect()
                    end
                end)
            end)

            local unloadBtn = library:create("TextButton", {
                Parent = profilePopup, FontFace = fonts.font, Text = "Unload", TextSize = 14,
                TextColor3 = themes.preset.text, AutoButtonColor = false,
                BackgroundColor3 = themes.preset.light,
                Position = dim2(0, 14, 0, 150), Size = dim2(1, -28, 0, 30),
                BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("UICorner", { Parent = unloadBtn, CornerRadius = dim(0, 6) })
            unloadBtn.MouseButton1Click:Connect(function()
                library:Notification({ Name = "Unloading", Description = "Chromatik is shutting down.", Icon = "power" })
                task.delay(0.35, function() library:unload_menu() end)
            end)
        end

        local function setProfileVisible(bool)
            profileOpen = bool
            if bool then
                rebuildProfile()
                profilePopup.Size = dim2(0, 240, 0, 0)
                profilePopup.BackgroundTransparency = 1
                profilePopup.Visible = true
                library:tween(profilePopup, { Size = dim2(0, 240, 0, 194), BackgroundTransparency = 0 }, Enum.EasingStyle.Quint, 0.22)
            else
                library:tween(profilePopup, { Size = dim2(0, 240, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, 0.18)
                task.delay(0.2, function()
                    if not profileOpen then profilePopup.Visible = false end
                end)
            end
        end

        items["profile_btn"].MouseButton1Click:Connect(function()
            setProfileVisible(not profileOpen)
        end)

        library:connection(uis.InputBegan, function(input)
            if not profileOpen then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local pos = input.Position
            local pAbs, pSize = profilePopup.AbsolutePosition, profilePopup.AbsoluteSize
            local bAbs, bSize = items["profile_btn"].AbsolutePosition, items["profile_btn"].AbsoluteSize
            local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
            local overBtn = pos.X >= bAbs.X and pos.X <= bAbs.X + bSize.X and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSize.Y
            if not overPopup and not overBtn then setProfileVisible(false) end
        end)

        items["shadow"] = library:create("ImageLabel", {
            ImageColor3 = rgb(0, 0, 0),
            ScaleType = Enum.ScaleType.Slice,
            Parent = items["main"],
            BorderColor3 = rgb(0, 0, 0),
            Name = "\0",
            BackgroundColor3 = rgb(255, 255, 255),
            Size = dim2(1, 75, 1, 75),
            AnchorPoint = vec2(0.5, 0.5),
            Image = "rbxassetid://112971167999062",
            BackgroundTransparency = 1,
            Position = dim2(0.5, 0, 0.5, 0),
            SliceScale = 0.75,
            ZIndex = -100,
            BorderSizePixel = 0,
            SliceCenter = Rect.new(vec2(112, 112), vec2(147, 147)),
        })

        items["global_fade"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 56),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -196, 1, -81),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
            ZIndex = 2,
        })

        library:create("UICorner", {
            Parent = items["shadow"],
            CornerRadius = dim(0, 5),
        })

        items["info"] = library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["main"],
            Name = "\0",
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 25),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        library:create("UICorner", {
            Parent = items["info"],
            CornerRadius = dim(0, 10),
        })

        items["grey_fill"] = library:create("Frame", {
            Name = "\0",
            Parent = items["info"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 6),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        items["game"] = library:create("TextLabel", {
            FontFace = fonts.font,
            Parent = items["info"],
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.game_name,
            Name = "\0",
            Size = dim2(1, 0, 0, 0),
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 10, 0.5, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        items["other_info"] = library:create("TextLabel", {
            Parent = items["info"],
            RichText = true,
            Name = "\0",
            TextColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Text = string.format('<font color="rgb(72, 72, 73)">%s, </font>%s%s', cfg.author or library.author or "chromatik", cfg.name, cfg.suffix or ""),
            Size = dim2(1, 0, 0, 0),
            Position = dim2(0, -10, 0.5, -1),
            AnchorPoint = vec2(0, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            AutomaticSize = Enum.AutomaticSize.XY,
            FontFace = fonts.font,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        library:apply_theme(items["other_info"], "accent", "TextColor3")
    end



    library:draggify(items["main"])
    library:resizify(items["main"])

    -- Mobile / small-screen: uniform UIScale only (no size squash), floating open button
    do
        local touch = false
        pcall(function() touch = uis.TouchEnabled == true end)
        local vp = camera and camera.ViewportSize
        local needMobile = touch
        if vp and math.min(vp.X, vp.Y) < 700 then
            needMobile = true
        end
        if needMobile and vp then
            -- Uniform scale keeps proportions — never change Width/Height ratios
            local scale = math.min(vp.X / 720, vp.Y / 580)
            scale = math.clamp(scale, 0.6, 1)
            local us = items["main"]:FindFirstChild("ChromatikMobileScale")
            if not us then
                us = Instance.new("UIScale")
                us.Name = "ChromatikMobileScale"
                us.Parent = items["main"]
            end
            us.Scale = scale
            library._mobile_scale = us
            -- center once; do not force top-left every frame (that felt like "moving")
            task.defer(function()
                pcall(function()
                    local aw = items["main"].AbsoluteSize.X
                    local ah = items["main"].AbsoluteSize.Y
                    local x = math.max(6, math.floor((vp.X - aw) * 0.5))
                    local y = math.max(6, math.floor((vp.Y - ah) * 0.5))
                    items["main"].Position = dim2(0, x, 0, y)
                end)
            end)
        end

        -- Floating menu button for touch (no keyboard LeftAlt on phones)
        if touch then
            local btnGui = library:create("ScreenGui", {
                Parent = coregui,
                Name = "\0",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
                DisplayOrder = 10050,
            })
            library._mobile_menu_gui = btnGui
            local btn = library:create("TextButton", {
                Parent = btnGui,
                Name = "\0",
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = themes.preset.section,
                Size = dim2(0, 46, 0, 46),
                Position = dim2(1, -58, 0.5, -23),
                BorderSizePixel = 0,
                ZIndex = 200,
            })
            library:create("UICorner", { Parent = btn, CornerRadius = dim(0, 12) })
            library:create("UIStroke", {
                Parent = btn, Color = themes.preset.accent, Thickness = 1.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            local icon = library:create("TextLabel", {
                Parent = btn,
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                Text = "≡",
                TextColor3 = themes.preset.text,
                TextSize = 22,
                FontFace = fonts.font,
                BorderSizePixel = 0,
                ZIndex = 201,
            })
            local open = true
            btn.MouseButton1Click:Connect(function()
                open = not open
                pcall(function()
                    if cfg.toggle_menu then
                        cfg.toggle_menu(open)
                    elseif library.items then
                        library.items.Enabled = open
                    end
                end)
                pcall(function()
                    shared = shared or {}
                    shared._juruMenuOpen = open
                end)
            end)
            -- also allow dragging the open button
            do
                local dragging, start, startPos
                btn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        start = input.Position
                        startPos = btn.Position
                    end
                end)
                btn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                library:connection(uis.InputChanged, function(input)
                    if not dragging then return end
                    if input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                    local vp2 = camera.ViewportSize
                    local nx = startPos.X.Offset + (input.Position.X - start.X)
                    local ny = startPos.Y.Offset + (input.Position.Y - start.Y)
                    nx = clamp(nx, 8, vp2.X - 54)
                    ny = clamp(ny, 8, vp2.Y - 54)
                    -- only move if dragged enough (tap vs drag)
                    if math.abs(input.Position.X - start.X) + math.abs(input.Position.Y - start.Y) > 12 then
                        btn.Position = dim2(0, nx, 0, ny)
                    end
                end)
            end
            library._mobile_menu_btn = btn
        end
    end

    function cfg.toggle_menu(bool)
        library["items"].Enabled = bool
        pcall(function()
            shared = shared or {}
            shared._juruMenuOpen = bool == true
        end)
    end

    return setmetatable(cfg, library)
end

function library:tab(properties)
    local cfg = {
        name = properties.name or properties.Name or "visuals",
        icon = properties.icon or properties.Icon or "layers",
        tabs = properties.tabs or properties.Tabs or { "Main", "Misc.", "Settings" },
        pages = {},
        current_multi = nil,
        items = {},
    }

    local items = cfg.items
    do
        items["tab_holder"] = library:create("Frame", {
            Parent = library.cache,
            Name = "\0",
            Visible = false,
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 56),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -216, 1, -101),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            Parent = self.items["button_holder"],
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Name = "\0",
            Size = dim2(1, 0, 0, 35),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = rgb(29, 29, 29),
        })

        items["icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.dimicon,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 22, 0, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        ApplyIcon(items["icon"], cfg.icon)


        items["name"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.name,
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 1, 0),
            Position = dim2(0, 40, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIPadding", {
            Parent = items["name"],
            PaddingRight = dim(0, 5),
            PaddingLeft = dim(0, 5),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        items["multi_section_button_holder"] = library:create("Frame", {
            Parent = library.cache,
            BackgroundTransparency = 1,
            Name = "\0",
            Visible = false,
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["multi_section_button_holder"],
            Padding = dim(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 8),
            PaddingBottom = dim(0, 7),
            Parent = items["multi_section_button_holder"],
            PaddingRight = dim(0, 7),
            PaddingLeft = dim(0, 7),
        })

        for _, section in cfg.tabs do
            local data = { items = {} }
            local multi_items = data.items

            multi_items["button"] = library:create("TextButton", {
                FontFace = fonts.font,
                TextColor3 = rgb(255, 255, 255),
                BorderColor3 = rgb(0, 0, 0),
                AutoButtonColor = false,
                Text = "",
                Parent = items["multi_section_button_holder"],
                Name = "\0",
                Size = dim2(0, 0, 0, 39),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 16,
                BackgroundColor3 = rgb(25, 25, 29),
            })

            multi_items["name"] = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = rgb(62, 62, 63),
                BorderColor3 = rgb(0, 0, 0),
                Text = section,
                Parent = multi_items["button"],
                Name = "\0",
                Size = dim2(0, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 16,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIPadding", {
                Parent = multi_items["name"],
                PaddingRight = dim(0, 5),
                PaddingLeft = dim(0, 5),
            })

            multi_items["accent"] = library:create("Frame", {
                BorderColor3 = rgb(0, 0, 0),
                AnchorPoint = vec2(0, 1),
                Parent = multi_items["button"],
                BackgroundTransparency = 1,
                Position = dim2(0, 10, 1, 4),
                Name = "\0",
                Size = dim2(1, -20, 0, 6),
                BorderSizePixel = 0,
                BackgroundColor3 = themes.preset.accent,
            })
            library:apply_theme(multi_items["accent"], "accent", "BackgroundColor3")

            library:create("UICorner", {
                Parent = multi_items["accent"],
                CornerRadius = dim(0, 999),
            })

            library:create("UIPadding", {
                Parent = multi_items["button"],
                PaddingRight = dim(0, 10),
                PaddingLeft = dim(0, 10),
            })

            library:create("UICorner", {
                Parent = multi_items["button"],
                CornerRadius = dim(0, 7),
            })

            multi_items["tab"] = library:create("Frame", {
                Parent = library.cache,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = rgb(0, 0, 0),
                Size = dim2(1, -20, 1, -20),
                BorderSizePixel = 0,
                Visible = false,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Parent = multi_items["tab"],
                Padding = dim(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
            })

            library:create("UIPadding", {
                PaddingTop = dim(0, 7),
                PaddingBottom = dim(0, 7),
                Parent = multi_items["tab"],
                PaddingRight = dim(0, 7),
                PaddingLeft = dim(0, 7),
            })

            data.text = multi_items["name"]
            data.accent = multi_items["accent"]
            data.button = multi_items["button"]
            data.page = multi_items["tab"]


            local tab_parent = library:create("Frame", {
                Parent = multi_items["tab"],
                BackgroundTransparency = 1,
                Name = "\0",
                Size = dim2(1, 0, 1, 0),
                BorderColor3 = rgb(0, 0, 0),
                BorderSizePixel = 0,
                Visible = true,
                BackgroundColor3 = rgb(255, 255, 255),
            })
            library:create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
                Parent = tab_parent,
                Padding = dim(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            data.parent = tab_parent

            function data.open_page()
                local page = cfg.current_multi
                if page and page.text ~= data.text then
                    self.items["global_fade"].BackgroundTransparency = 0
                    library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                end


                for _, p in ipairs(cfg.pages) do
                    if p ~= data then
                        pcall(function()
                            library:tween(p.text, { TextColor3 = rgb(62, 62, 63) })
                            library:tween(p.accent, { BackgroundTransparency = 1 })
                            library:tween(p.button, { BackgroundTransparency = 1 })
                            p.page.Visible = false
                            p.page.Parent = library["cache"]
                            p.page.Size = dim2(1, -20, 1, -20)
                        end)
                    end
                end

                library:tween(data.text, { TextColor3 = rgb(255, 255, 255) })
                library:tween(data.accent, { BackgroundTransparency = 0 })
                library:tween(data.button, { BackgroundTransparency = 0 })
                library:tween(data.page, { Size = dim2(1, 0, 1, 0) }, Enum.EasingStyle.Quad, 0.4)

                data.page.Visible = true
                data.page.Parent = items["tab_holder"]
                cfg.current_multi = data
                library:close_element()
            end

            multi_items["button"].MouseButton1Down:Connect(function()
                data.open_page()
            end)

            cfg.pages[#cfg.pages + 1] = setmetatable(data, library)
        end

        cfg.pages[1].open_page()
    end

    function cfg.open_tab()
        local selected_tab = self.selected_tab
        if selected_tab then
            if selected_tab[4] ~= items["tab_holder"] then
                self.items["global_fade"].BackgroundTransparency = 0
                library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                selected_tab[4].Size = dim2(1, -216, 1, -101)
            end
            library:tween(selected_tab[1], { BackgroundTransparency = 1 })
            library:tween(selected_tab[2], { ImageColor3 = themes.preset.dimicon })
            library:tween(selected_tab[3], { TextColor3 = themes.preset.dimtext })
            selected_tab[4].Visible = false
            selected_tab[4].Parent = library["cache"]
            selected_tab[5].Visible = false
            selected_tab[5].Parent = library["cache"]
        end

        library:tween(items["button"], { BackgroundTransparency = 0 })
        library:tween(items["icon"], { ImageColor3 = themes.preset.accent })
        library:tween(items["name"], { TextColor3 = rgb(255, 255, 255) })
        library._active_tab_icon = items["icon"]
        library:tween(items["tab_holder"], { Size = dim2(1, -196, 1, -81) }, Enum.EasingStyle.Quad, 0.4)

        items["tab_holder"].Visible = true
        items["tab_holder"].Parent = self.items["main"]
        items["multi_section_button_holder"].Visible = true
        items["multi_section_button_holder"].Parent = self.items["multi_holder"]

        self.selected_tab = {
            items["button"],
            items["icon"],
            items["name"],
            items["tab_holder"],
            items["multi_section_button_holder"],
        }
        library:close_element()
    end

    items["button"].MouseButton1Down:Connect(function()
        cfg.open_tab()
    end)

    if not self.selected_tab then
        cfg.open_tab(true)
    end

    return unpack(cfg.pages)
end

function library:seperator(properties)
    local cfg = { items = {}, name = properties.Name or properties.name or "General" }
    local items = cfg.items
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["button_holder"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 40, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })
    return setmetatable(cfg, library)
end

function library:column(properties)
    properties = properties or {}

    local sub = properties.tab or properties.Tab
    local parent_frame = nil


    if sub and type(sub) == "number" and self.pages and self.pages[sub] then
        parent_frame = self.pages[sub].parent
    elseif self.parent then

        parent_frame = self.parent
    elseif self.items and self.items["tab_parent"] then
        parent_frame = self.items["tab_parent"]
    elseif self.pages and self.pages[1] then

        parent_frame = self.pages[1].parent
        sub = 1
    end


    local count_key = sub or 0
    self._column_counts = self._column_counts or {}
    self._column_counts[count_key] = (self._column_counts[count_key] or 0) + 1
    if self._column_counts[count_key] > 2 then
        warn("[Chromatik] Max 2 sections/columns allowed per tab — extra column ignored.")
        local dummy = { items = { column = Instance.new("Frame") } }
        dummy.items.column.Parent = nil
        return setmetatable(dummy, library)
    end

    local cfg = { items = {}, size = properties.size or 1 }
    local items = cfg.items
    items["column"] = library:create("Frame", {
        Parent = parent_frame,
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, -4, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        PaddingBottom = dim(0, 10),
        Parent = items["column"],
    })
    library:create("UIListLayout", {
        Parent = items["column"],
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Padding = dim(0, 10),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable(cfg, library)
end

function library:sub_tab(properties)
    local cfg = { items = {}, order = properties.order or 0, size = properties.size or 1 }
    local items = cfg.items
    items["tab_parent"] = library:create("Frame", {
        Parent = self.items["tab"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(0, 0, cfg.size, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        Visible = true,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        Parent = items["tab_parent"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable(cfg, library)
end

function library:section(properties)
    local cfg = {
        name = properties.name or properties.Name or "section",
        side = properties.side or properties.Side or "left",
        default = properties.default or properties.Default or false,
        size = properties.size or properties.Size or self.size or 0.5,
        icon = properties.icon or properties.Icon or "box",
        fading_toggle = properties.fading or properties.Fading or false,
        items = {},
    }

    local items = cfg.items
    do
        items["outline"] = library:create("Frame", {
            Name = "\0",
            Parent = self.items["column"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 0, cfg.size, -3),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.element,
        })

        library:create("UICorner", {
            Parent = items["outline"],
            CornerRadius = dim(0, 7),
        })

        items["inline"] = library:create("Frame", {
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
        })

        library:create("UICorner", {
            Parent = items["inline"],
            CornerRadius = dim(0, 7),
        })

        items["scrolling"] = library:create("ScrollingFrame", {
            ScrollBarImageColor3 = rgb(44, 44, 46),
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            Parent = items["inline"],
            Name = "\0",
            Size = dim2(1, 0, 1, -40),
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 35),
            BackgroundColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
            CanvasSize = dim2(0, 0, 0, 0),
        })

        items["elements"] = library:create("Frame", {
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["scrolling"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0, 10),
            Size = dim2(1, -20, 0, 0),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["elements"],
            Padding = dim(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        library:create("UIPadding", {
            PaddingBottom = dim(0, 15),
            Parent = items["elements"],
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            AutoButtonColor = false,
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            Size = dim2(1, -2, 0, 35),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = rgb(19, 19, 21),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        items["Icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 22, 0, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        ApplyIcon(items["Icon"], cfg.icon)
        library:apply_theme(items["Icon"], "accent", "ImageColor3")

        items["section_title"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.name,
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 1, 0),
            Position = dim2(0, 40, 0, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["button"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(36, 36, 37),
        })
    end

    return setmetatable(cfg, library)
end

function library:toggle(options)
    local cfg = {
        enabled = options.enabled or nil,
        name = options.name or "Toggle",
        info = options.info or nil,
        flag = options.flag or library:next_flag(),

        type = options.type and string.lower(options.type) or "toggle",
        default = options.default or false,
        folding = options.folding or false,
        callback = options.callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["toggle"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["toggle"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["toggle"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })


    items["switch"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["right_components"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        Size = dim2(0, 36, 0, 18),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(33, 33, 35),
    })




    library:create("UICorner", {
        Parent = items["switch"],
        CornerRadius = dim(0, 999),
    })

    items["knob"] = library:create("Frame", {
        Parent = items["switch"],
        Name = "\0",
        Position = dim2(0, 2, 0, 2),
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(160, 160, 165),
    })

    library:create("UICorner", {
        Parent = items["knob"],
        CornerRadius = dim(0, 999),
    })


    library._toggle_hooks = library._toggle_hooks or {}

    function cfg.set(bool)
        cfg.enabled = bool
        flags[cfg.flag] = bool
        library:tween(items["switch"], {
            BackgroundColor3 = bool and themes.preset.accent or rgb(33, 33, 35),
        })
        library:tween(items["knob"], {
            Position = bool and dim2(1, -16, 0, 2) or dim2(0, 2, 0, 2),
            BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(160, 160, 165),
        })

        if bool then
            library._toggle_hooks[cfg.flag] = items["switch"]
        else
            library._toggle_hooks[cfg.flag] = nil
        end
        if not library.silent then
            cfg.callback(bool)
        end
    end

    items["switch"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    items["toggle"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:slider(options)
    local cfg = {
        name = options.name or "Slider",
        min = options.min or 0,
        max = options.max or 100,
        default = options.default or options.min or 0,
        interval = options.interval or options.decimals or 1,
        suffix = options.suffix or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
        value = 0,
        sliding = false,
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["slider"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 42),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })


    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(1, -70, 0, 18),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["value"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = tostring(cfg.default) .. cfg.suffix,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(0, 60, 0, 18),
        Position = dim2(1, -65, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["track"] = library:create("Frame", {
        Parent = items["slider"],
        Name = "\0",
        Position = dim2(0, 5, 0, 24),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 8),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["track"],
        CornerRadius = dim(0, 4),
    })

    items["fill"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent,
    })
    library:apply_theme(items["fill"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["fill"],
        CornerRadius = dim(0, 4),
    })

    items["knob"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0, 0, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 12, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
        ZIndex = 2,
    })

    library:create("UICorner", {
        Parent = items["knob"],
        CornerRadius = dim(0, 999),
    })

    library:create("UIStroke", {
        Color = themes.preset.accent,
        Parent = items["knob"],
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    library:apply_theme(items["knob"]:FindFirstChildOfClass("UIStroke"), "accent", "Color")

    items["hit"] = library:create("TextButton", {
        Parent = items["track"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 3,
        BorderSizePixel = 0,
    })

    function cfg.set(value)
        value = clamp(library:round(value, cfg.interval), cfg.min, cfg.max)
        cfg.value = value
        flags[cfg.flag] = value

        local fraction = (cfg.max - cfg.min) == 0 and 0 or (value - cfg.min) / (cfg.max - cfg.min)
        items["fill"].Size = dim2(fraction, 0, 1, 0)
        items["knob"].Position = dim2(fraction, 0, 0.5, 0)
        items["value"].Text = tostring(value) .. cfg.suffix

        if not library.silent then
            cfg.callback(value)
        end
    end

    local function calculate(input)
        local fraction = clamp((input.Position.X - items["track"].AbsolutePosition.X) / items["track"].AbsoluteSize.X, 0, 1)
        return cfg.min + (cfg.max - cfg.min) * fraction
    end

    items["hit"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = true
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if cfg.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = false
        end
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:dropdown(options)
    local cfg = {
        name = options.name or "Dropdown",
        options = options.items or options.Options or options.options or {},
        default = options.default,
        multi = options.multi or false,
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
        value = nil,
        open = false,
    }

    if cfg.multi then
        cfg.value = {}
    end

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["dropdown"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 54),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["dropdown"],
        Name = "\0",
        Size = dim2(1, -10, 0, 18),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["box"] = library:create("Frame", {
        Parent = items["dropdown"],
        Name = "\0",
        Position = dim2(0, 5, 0, 22),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 28),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["box"],
        CornerRadius = dim(0, 6),
    })

    library:create("UIStroke", {
        Parent = items["box"],
        Color = themes.preset.line,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    items["selected"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = "None",
        Parent = items["box"],
        Name = "\0",
        Size = dim2(1, -34, 1, 0),
        Position = dim2(0, 11, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["arrow"] = library:create("ImageLabel", {
        ImageColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items["box"],
        AnchorPoint = vec2(1, 0.5),
        BackgroundTransparency = 1,
        Position = dim2(1, -10, 0.5, 0),
        Name = "\0",
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    ApplyIcon(items["arrow"], "chevron-down")

    items["hit"] = library:create("TextButton", {
        Parent = items["box"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 2,
        BorderSizePixel = 0,
    })


    local popup = {
        open = false,
        order = {},
    }

    local popupFrame = library:create("Frame", {
        Parent = library["other"],
        Name = "\0",
        Size = dim2(0, 150, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 50,
    })

    local popupCorner = library:create("UICorner", {
        Parent = popupFrame,
        CornerRadius = dim(0, 6),
    })

    library:create("UIStroke", {
        Parent = popupFrame,
        Color = themes.preset.line,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local searchHolder = library:create("Frame", {
        Parent = popupFrame,
        Name = "\0",
        Size = dim2(1, 0, 0, 30),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
        Visible = false,
        ZIndex = 51,
    })

    local searchIcon = library:create("ImageLabel", {
        Parent = searchHolder,
        BackgroundTransparency = 1,
        Position = dim2(0, 9, 0, 8),
        Size = dim2(0, 13, 0, 13),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 52,
    })
    ApplyIcon(searchIcon, "search")

    local searchBox = library:create("TextBox", {
        Parent = searchHolder,
        FontFace = fonts.font,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = themes.preset.dimtext,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 27, 0, 0),
        Size = dim2(1, -32, 1, 0),
        TextSize = 14,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    library:create("Frame", {
        Parent = searchHolder,
        Position = dim2(0, 6, 1, -1),
        Size = dim2(1, -12, 0, 1),
        BackgroundColor3 = themes.preset.line,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    local scroll = library:create("ScrollingFrame", {
        Parent = popupFrame,
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = dim2(0, 0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 51,
    })

    library:create("UIListLayout", {
        Parent = scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = scroll,
        PaddingTop = dim(0, 4),
        PaddingBottom = dim(0, 4),
        PaddingLeft = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    local function applySearch(query)
        query = string.lower(query or "")
        for _, data in popup.order do
            local match = query == "" or string.find(string.lower(data.name), query, 1, true) ~= nil
            data.row.Visible = match
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(searchBox.Text)
    end)

    local function addRow(text)
        local row = library:create("TextButton", {
            Parent = scroll,
            Text = "",
            AutoButtonColor = false,
            Size = dim2(1, -4, 0, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
            ZIndex = 52,
        })

        library:create("UICorner", {
            Parent = row,
            CornerRadius = dim(0, 4),
        })

        local line = library:create("Frame", {
            Parent = row,
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 6, 0.5, 0),
            Size = dim2(0, 3, 0, 0),
            BackgroundColor3 = themes.preset.accent,
            BorderSizePixel = 0,
            ZIndex = 53,
        })
        library:apply_theme(line, "accent", "BackgroundColor3")

        library:create("UICorner", {
            Parent = line,
            CornerRadius = dim(0, 4),
        })

        local label = library:create("TextLabel", {
            Parent = row,
            FontFace = fonts.font,
            Text = text,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0, 14, 0, 0),
            Size = dim2(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BorderSizePixel = 0,
            ZIndex = 53,
        })

        local data = {
            name = text,
            selected = false,
            row = row,
            line = line,
            label = label,
        }

        function data:Set(active, instant)
            data.selected = active
            local color = active and themes.preset.text or themes.preset.dimtext
            local bg = active and 0 or 1
            local lineH = active and 16 or 0
            if instant then
                row.BackgroundTransparency = bg
                label.TextColor3 = color
                line.Size = dim2(0, 3, 0, lineH)
            else
                library:tween(row, { BackgroundTransparency = bg })
                library:tween(label, { TextColor3 = color })
                library:tween(line, { Size = dim2(0, 3, 0, lineH) })
            end
        end

        row.MouseEnter:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 0.7 })
            end
        end)

        row.MouseLeave:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 1 })
            end
        end)

        row.MouseButton1Down:Connect(function()
            if cfg.multi then
                local idx = find(cfg.value, data.name)
                if idx then
                    remove(cfg.value, idx)
                    data:Set(false)
                else
                    insert(cfg.value, data.name)
                    data:Set(true)
                end
            else
                cfg.value = data.name
                for _, other in popup.order do
                    other:Set(other == data)
                end
                cfg.set_visible(false)
                cfg.open = false
            end
            cfg.report()
        end)

        insert(popup.order, data)
        return data
    end

    function cfg.refresh(new_options)
        if type(new_options) ~= "table" then return end
        for _, data in popup.order do
            if data.row then data.row:Destroy() end
        end
        popup.order = {}
        cfg.options = new_options
        for _, text in new_options do
            addRow(tostring(text))
        end
        if cfg.multi then
            cfg.value = {}
            items["selected"].Text = "None"
        else
            cfg.value = new_options[1]
            items["selected"].Text = tostring(new_options[1] or "None")
        end
        flags[cfg.flag] = cfg.value
    end
    cfg.Refresh = cfg.refresh

    function cfg.report()
        flags[cfg.flag] = cfg.value
        if cfg.multi then
            items["selected"].Text = #cfg.value > 0 and concat(cfg.value, ", ") or "None"
        else
            items["selected"].Text = cfg.value ~= nil and tostring(cfg.value) or "None"
        end
        if not library.silent then
            cfg.callback(cfg.value)
        end
    end

    function cfg.set_visible(bool)
        popup.open = bool
        if bool then
            local showSearch = #popup.order > 8
            local listHeight = min(#popup.order * 28 + 6, 160)
            local targetH = showSearch and (listHeight + 28) or listHeight

            searchBox.Text = ""
            applySearch("")
            searchHolder.Visible = showSearch
            if showSearch then
                scroll.Position = dim2(0, 0, 0, 28)
                scroll.Size = dim2(1, 0, 1, -28)
            else
                scroll.Position = dim2(0, 0, 0, 0)
                scroll.Size = dim2(1, 0, 1, 0)
            end


            popupFrame.BackgroundColor3 = themes.preset.light
            popupFrame.BackgroundTransparency = 0
            popupFrame.Position = dim2(0, 5, 0, 52)
            popupFrame.Size = dim2(1, -10, 0, 0)
            popupFrame.Parent = items["dropdown"]
            popupFrame.Visible = true
            popupFrame.ClipsDescendants = true
            popupFrame.ZIndex = 5


            library:tween(items["dropdown"], {
                Size = dim2(1, 0, 0, 54 + targetH),
            }, Enum.EasingStyle.Quint, 0.18)
            library:tween(popupFrame, {
                Size = dim2(1, -10, 0, targetH),
            }, Enum.EasingStyle.Quint, 0.18)
            library:tween(items["arrow"], { Rotation = 180 }, Enum.EasingStyle.Quint, 0.18)
            library:close_element(cfg)
        else
            library:tween(popupFrame, {
                Size = dim2(1, -10, 0, 0),
            }, Enum.EasingStyle.Quint, 0.15)
            library:tween(items["dropdown"], {
                Size = dim2(1, 0, 0, 54),
            }, Enum.EasingStyle.Quint, 0.15)
            library:tween(items["arrow"], { Rotation = 0 }, Enum.EasingStyle.Quint, 0.15)
            task.delay(0.16, function()
                if not popup.open then
                    popupFrame.Visible = false
                    popupFrame.Parent = library["other"]
                    items["dropdown"].Size = dim2(1, 0, 0, 54)
                end
            end)
        end
    end


    library:connection(uis.InputBegan, function(input)
        if not popup.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local pos = input.Position
        local pAbs, pSize = popupFrame.AbsolutePosition, popupFrame.AbsoluteSize
        local bAbs, bSize = items["box"].AbsolutePosition, items["box"].AbsoluteSize
        local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X
            and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
        local overBox = pos.X >= bAbs.X and pos.X <= bAbs.X + bSize.X
            and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSize.Y
        if not overPopup and not overBox then
            cfg.set_visible(false)
            cfg.open = false
            if library.current_open == cfg then
                library.current_open = nil
            end
        end
    end)

    function cfg.set(value)
        if cfg.multi then
            if type(value) ~= "table" then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(find(value, data.name) ~= nil, true)
            end
        else
            local found = false
            for _, data in popup.order do
                if data.name == value then
                    found = true
                end
            end
            if not found and value ~= nil then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(data.name == value, true)
            end
        end
        cfg.report()
    end

    function cfg.refresh(list)
        for _, data in popup.order do
            data.row:Destroy()
        end
        popup.order = {}
        cfg.options = list
        for _, option in list do
            addRow(tostring(option))
        end
    end

    items["hit"].MouseButton1Down:Connect(function()
        cfg.open = not cfg.open
        cfg.set_visible(cfg.open)
    end)

    for _, option in cfg.options do
        addRow(tostring(option))
    end

    if cfg.default ~= nil then
        cfg.set(cfg.default)
    else
        cfg.report()
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:button(options)
    local cfg = {
        name = options.name or "Button",
        callback = options.callback or function() end,
        items = {},
    }

    local items = cfg.items
    items["button_element"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["button_element"],
        Name = "\0",
        Position = dim2(1, -4, 0, 0),
        Size = dim2(1, -8, 0, 30),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["button"],
        CornerRadius = dim(0, 3),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["button"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"].MouseButton1Click:Connect(function()
        cfg.callback()
        items["name"].TextColor3 = themes.preset.accent
        library:tween(items["name"], { TextColor3 = themes.preset.text })
    end)

    return setmetatable(cfg, library)
end

function library:textbox(options)
    local cfg = {
        name = options.name or "TextBox",
        placeholder = options.placeholder or options.placeholdertext or options.holder or "type here...",
        default = options.default or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["textbox"] = library:create("TextButton", {
        LayoutOrder = -1,
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["textbox"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["textbox"],
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 4, 0, 19),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    })

    items["input"] = library:create("TextBox", {
        FontFace = fonts.font,
        Text = "",
        Parent = items["right_components"],
        Name = "\0",
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        PlaceholderColor3 = themes.preset.dimtext,
        PlaceholderText = cfg.placeholder,
        ClearTextOnFocus = false,
        TextSize = 14,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Position = dim2(1, 0, 0, 0),
        Size = dim2(1, -4, 0, 30),
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["input"],
        CornerRadius = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = items["right_components"],
        PaddingTop = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    function cfg.set(text)
        flags[cfg.flag] = text
        items["input"].Text = text
        if not library.silent then
            cfg.callback(text)
        end
    end

    items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
        cfg.set(items["input"].Text)
    end)

    items["input"].Focused:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.text })
    end)

    items["input"].FocusLost:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.dimtext })
    end)

    if cfg.default ~= "" then
        cfg.set(cfg.default)
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:keybind(options)
    local cfg = {
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        name = options.name or nil,
        key = options.key or nil,
        mode = options.mode or "Toggle",
        active = options.default or false,
        open = false,
        binding = nil,
        items = {},
    }

    flags[cfg.flag] = {
        mode = cfg.mode,
        key = cfg.key,
        active = cfg.active,
    }

    local items = cfg.items
    items["keybind_element"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["keybind_element"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["keybind_element"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["keybind_holder"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = items["right_components"],
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Size = dim2(0, 0, 0, 16),
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["keybind_holder"],
        CornerRadius = dim(0, 4),
    })

    items["key"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = "NONE",
        Parent = items["keybind_holder"],
        Name = "\0",
        Size = dim2(1, -12, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["key"],
        PaddingTop = dim(0, 1),
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(input)
        if type(input) == "boolean" then
            cfg.active = input
            if cfg.mode == "Always" then
                cfg.active = true
            end
        elseif tostring(input):find("Enum") then
            input = input.Name == "Escape" and "NONE" or input
            cfg.key = input or "NONE"
        elseif find({ "Toggle", "Hold", "Always" }, input) then
            if input == "Always" then
                cfg.active = true
            end
            cfg.mode = input
        elseif type(input) == "table" then
            input.key = type(input.key) == "string" and input.key ~= "NONE" and library:convert_enum(input.key) or input.key
            input.key = input.key == Enum.KeyCode.Escape and "NONE" or input.key
            cfg.key = input.key or "NONE"
            cfg.mode = input.mode or "Toggle"
            if input.active then
                cfg.active = input.active
            end
        end

        cfg.callback(cfg.active)

        local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
        local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
        items["key"].Text = __text or "NONE"

        flags[cfg.flag] = {
            mode = cfg.mode,
            key = cfg.key,
            active = cfg.active,
        }


        if cfg.flag == "menu_bind" and cfg.key and cfg.key ~= "NONE" then
            library.MenuKeybind = cfg.key
            local label = __text or "NONE"
            library.MenuKeyName = label
            pcall(function()
                if library.ProfileKeyBox then
                    library.ProfileKeyBox.Text = label
                end
            end)
        end
    end

    items["keybind_holder"].MouseButton1Down:Connect(function()
        task.wait()
        items["key"].Text = "..."
        cfg.binding = library:connection(uis.InputBegan, function(keycode)
            cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            cfg.binding:Disconnect()
            cfg.binding = nil
        end)
    end)

    local function keys_match(input)
        if not cfg.key or cfg.key == "NONE" then return false end
        local selected = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if selected == cfg.key then return true end
        if type(cfg.key) == "string" then
            local name = cfg.key:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", ""):gsub("KeyCode.", "")
            if selected.Name == name then return true end
            local ok, enumKey = pcall(function() return Enum.KeyCode[name] end)
            if ok and enumKey and selected == enumKey then return true end
        end
        return false
    end


    cfg.passive = options.passive == true or options.no_listen == true


    function cfg.set_active(on)
        cfg.active = on == true
        flags[cfg.flag] = flags[cfg.flag] or {}
        flags[cfg.flag].active = cfg.active
        flags[cfg.flag].key = cfg.key
        flags[cfg.flag].mode = cfg.mode
        if library.KeybindListInstance and library.KeybindListInstance.Refresh then
            pcall(library.KeybindListInstance.Refresh)
        end
    end

    if not cfg.passive then
        library:connection(uis.InputBegan, function(input, game_event)
            if game_event then return end
            if uis:GetFocusedTextBox() then return end
            if cfg.binding then return end
            if keys_match(input) then
                if cfg.mode == "Toggle" then
                    cfg.active = not cfg.active
                    flags[cfg.flag] = flags[cfg.flag] or {}
                    flags[cfg.flag].active = cfg.active
                    flags[cfg.flag].key = cfg.key
                    flags[cfg.flag].mode = cfg.mode
                    pcall(cfg.callback, cfg.active)
                    if library.KeybindListInstance and library.KeybindListInstance.Refresh then
                        pcall(library.KeybindListInstance.Refresh)
                    end
                elseif cfg.mode == "Hold" then
                    cfg.active = true
                    flags[cfg.flag] = flags[cfg.flag] or {}
                    flags[cfg.flag].active = true
                    pcall(cfg.callback, true)
                end
            end
        end)

        library:connection(uis.InputEnded, function(input, game_event)
            if game_event then return end
            if keys_match(input) and cfg.mode == "Hold" then
                cfg.active = false
                flags[cfg.flag] = flags[cfg.flag] or {}
                flags[cfg.flag].active = false
                pcall(cfg.callback, false)
            end
        end)
    end

    cfg.set({ mode = cfg.mode, active = cfg.active, key = cfg.key })


    if cfg.flag == "menu_bind" then
        local original_set = cfg.set
        cfg.set = function(input)
            original_set(input)
            local key = cfg.key
            if typeof(key) == "EnumItem" then
                library.MenuKeybind = key
                local label = keys[key] or key.Name
                if library.ProfileKeyBox and library.ProfileKeyBox.Parent then
                    library.ProfileKeyBox.Text = label
                end
            end
        end
    end

    config_flags[cfg.flag] = cfg.set


    do
        local entry = {
            flag = cfg.flag,
            name = cfg.name or cfg.flag,
            get_key = function()
                return cfg.key
            end,
            get_mode = function()
                return cfg.mode
            end,
            get_active = function()
                return cfg.active
            end,
            cfg = cfg,
        }

        local list = library.keybind_registry
        for i = #list, 1, -1 do
            if list[i].flag == cfg.flag then
                table.remove(list, i)
            end
        end
        table.insert(list, entry)

        local _set = cfg.set
        cfg.set = function(input)
            _set(input)
            if library.KeybindListInstance and library.KeybindListInstance.Refresh then
                pcall(library.KeybindListInstance.Refresh)
            end
        end
        config_flags[cfg.flag] = cfg.set

        if library.KeybindListInstance and library.KeybindListInstance.Refresh then
            pcall(library.KeybindListInstance.Refresh)
        end
    end

    return setmetatable(cfg, library)
end

function library:colorpicker(options)
    local cfg = {
        name = options.name or "Color",
        flag = options.flag or library:next_flag(),
        color = options.color or options.default or themes.preset.accent,
        alpha = options.alpha or options.transparency or 0,
        callback = options.callback or function() end,
        items = {},
        open = false,
    }

    flags[cfg.flag] = { Color = cfg.color, Transparency = cfg.alpha }

    local items = cfg.items
    items["colorpicker"] = library:create("TextButton", {
        FontFace = fonts.small, TextColor3 = rgb(0, 0, 0), BorderColor3 = rgb(0, 0, 0),
        Text = "", AutoButtonColor = false, Parent = self.items["elements"], Name = "\0",
        BackgroundTransparency = 1, Size = dim2(1, 0, 0, 0), BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font, TextColor3 = themes.preset.text, BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name, Parent = items["colorpicker"], Name = "\0", Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY, TextSize = 16, BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", { Parent = items["name"], PaddingRight = dim(0, 5), PaddingLeft = dim(0, 5) })

    items["swatch"] = library:create("TextButton", {
        FontFace = fonts.small, TextColor3 = rgb(0, 0, 0), BorderColor3 = rgb(0, 0, 0),
        Text = "", AutoButtonColor = false, AnchorPoint = vec2(1, 0), Parent = items["colorpicker"],
        Name = "\0", Position = dim2(1, 0, 0, 0), Size = dim2(0, 18, 0, 18),
        BorderSizePixel = 0, TextSize = 14, BackgroundColor3 = cfg.color,
    })
    library:create("UICorner", { Parent = items["swatch"], CornerRadius = dim(0, 4) })


    local h, s, v = Color3.toHSV(cfg.color)
    local popup = library:create("Frame", {
        Parent = library["other"], Name = "\0", Size = dim2(0, 200, 0, 0),
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, Visible = false,
        ZIndex = 90, ClipsDescendants = true,
    })
    library:create("UICorner", { Parent = popup, CornerRadius = dim(0, 8) })

    local satFrame = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 10, 0, 10), Size = dim2(0, 150, 0, 100),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
        Image = "rbxassetid://4155801252",
    })
    library:create("UICorner", { Parent = satFrame, CornerRadius = dim(0, 4) })

    local satCursor = library:create("Frame", {
        Parent = satFrame, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 8, 0, 8),
        Position = dim2(s, 0, 1 - v, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = satCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = satCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local hueBar = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 168, 0, 10), Size = dim2(0, 14, 0, 100),
        BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
        Image = "rbxassetid://3570695787", ScaleType = Enum.ScaleType.Stretch,
    })
    library:create("UICorner", { Parent = hueBar, CornerRadius = dim(0, 4) })
    local hueGrad = library:create("UIGradient", {
        Parent = hueBar,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, rgb(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, rgb(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, rgb(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, rgb(255, 0, 255)),
            ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
        }),
        Rotation = 90,
    })
    local hueCursor = library:create("Frame", {
        Parent = hueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(1, 4, 0, 4),
        Position = dim2(0.5, 0, h, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = hueCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = hueCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local alphaBar = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 10, 0, 118), Size = dim2(0, 172, 0, 12),
        BackgroundColor3 = cfg.color, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
    })
    library:create("UICorner", { Parent = alphaBar, CornerRadius = dim(0, 3) })
    local alphaCursor = library:create("Frame", {
        Parent = alphaBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 1, 4),
        Position = dim2(1 - cfg.alpha, 0, 0.5, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = alphaCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = alphaCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local hexBox = library:create("TextBox", {
        Parent = popup, FontFace = fonts.font, Text = "", TextSize = 12,
        TextColor3 = themes.preset.text, BackgroundColor3 = themes.preset.light,
        Position = dim2(0, 10, 0, 140), Size = dim2(0, 172, 0, 22), BorderSizePixel = 0,
        ClearTextOnFocus = false, ZIndex = 91,
    })
    library:create("UICorner", { Parent = hexBox, CornerRadius = dim(0, 4) })
    library:create("UIPadding", { Parent = hexBox, PaddingLeft = dim(0, 6) })

    local function update_hex()
        local r = floor(cfg.color.R * 255)
        local g = floor(cfg.color.G * 255)
        local b = floor(cfg.color.B * 255)
        hexBox.Text = string.format("#%02X%02X%02X", r, g, b)
    end

    function cfg.set(color, alpha)
        if typeof(color) == "table" and color.Color then
            alpha = color.Transparency or alpha
            color = color.Color
        end
        if typeof(color) == "Color3" then
            cfg.color = color
            h, s, v = Color3.toHSV(color)
        end
        if type(alpha) == "number" then cfg.alpha = alpha end
        items["swatch"].BackgroundColor3 = cfg.color
        satFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satCursor.Position = dim2(s, 0, 1 - v, 0)
        hueCursor.Position = dim2(0.5, 0, h, 0)
        alphaBar.BackgroundColor3 = cfg.color
        alphaCursor.Position = dim2(1 - cfg.alpha, 0, 0.5, 0)
        update_hex()
        flags[cfg.flag] = { Color = cfg.color, Transparency = cfg.alpha }
        if not library.silent then
            cfg.callback(cfg.color, cfg.alpha)
        end
    end

    local function apply_hsv()
        cfg.set(Color3.fromHSV(h, s, v), cfg.alpha)
    end

    local dragging_sat, dragging_hue, dragging_alpha = false, false, false

    satFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_sat = true
            local relX = clamp((input.Position.X - satFrame.AbsolutePosition.X) / satFrame.AbsoluteSize.X, 0, 1)
            local relY = clamp((input.Position.Y - satFrame.AbsolutePosition.Y) / satFrame.AbsoluteSize.Y, 0, 1)
            s, v = relX, 1 - relY
            apply_hsv()
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_hue = true
            h = clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
            apply_hsv()
        end
    end)
    alphaBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_alpha = true
            cfg.alpha = 1 - clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            apply_hsv()
        end
    end)
    library:connection(uis.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if dragging_sat then
            local relX = clamp((input.Position.X - satFrame.AbsolutePosition.X) / satFrame.AbsoluteSize.X, 0, 1)
            local relY = clamp((input.Position.Y - satFrame.AbsolutePosition.Y) / satFrame.AbsoluteSize.Y, 0, 1)
            s, v = relX, 1 - relY
            apply_hsv()
        elseif dragging_hue then
            h = clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
            apply_hsv()
        elseif dragging_alpha then
            cfg.alpha = 1 - clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            apply_hsv()
        end
    end)
    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_sat, dragging_hue, dragging_alpha = false, false, false
        end
    end)

    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:gsub("#", "")
        if #hex == 6 then
            local ok, col = pcall(Color3.fromHex, hex)
            if ok and col then cfg.set(col, cfg.alpha) end
        end
        update_hex()
    end)

    function cfg.set_visible(bool)
        cfg.open = bool
        if bool then
            local scale = 1
            local sp = items["swatch"].AbsolutePosition
            local ss = items["swatch"].AbsoluteSize
            local px = (sp.X + ss.X) / scale - 200
            local py = (sp.Y + ss.Y) / scale + 6
            popup.Size = dim2(0, 200, 0, 0)
            popup.Position = dim2(0, px, 0, py)
            popup.Parent = library["items"]
            popup.Visible = true
            library:tween(popup, { Size = dim2(0, 200, 0, 172) }, Enum.EasingStyle.Quint, 0.2)
            library:close_element(cfg)
        else
            library:tween(popup, { Size = dim2(0, 200, 0, 0) }, Enum.EasingStyle.Quint, 0.15)
            task.delay(0.17, function()
                if not cfg.open then
                    popup.Visible = false
                    popup.Parent = library["other"]
                end
            end)
        end
    end

    items["swatch"].MouseButton1Click:Connect(function()
        cfg.set_visible(not cfg.open)
    end)


    library:connection(uis.InputBegan, function(input)
        if not cfg.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local pAbs, pSize = popup.AbsolutePosition, popup.AbsoluteSize
        local sAbs, sSize = items["swatch"].AbsolutePosition, items["swatch"].AbsoluteSize
        local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
        local overSwatch = pos.X >= sAbs.X and pos.X <= sAbs.X + sSize.X and pos.Y >= sAbs.Y and pos.Y <= sAbs.Y + sSize.Y
        if not overPopup and not overSwatch then
            cfg.set_visible(false)
        end
    end)

    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:label(options)
    local cfg = {
        name = options.name or "Label",
        items = {},
    }

    local items = cfg.items
    items["label"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["elements"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["label"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(...)
        local args = {...}
        local text = args[#args]
        items["label"].Text = tostring(text)
    end
    cfg.Set = cfg.set

    return setmetatable(cfg, library)
end

function library:list(properties)
    local cfg = {
        items = {},
        options = properties.options or { "1", "2", "3" },
        flag = properties.flag or library:next_flag(),
        callback = properties.callback or function() end,
        data_store = {},
        current_element = nil,
    }

    local items = cfg.items
    items["list"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["list"],
        Padding = dim(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    library:create("UIPadding", {
        Parent = items["list"],
        PaddingRight = dim(0, 4),
        PaddingLeft = dim(0, 4),
    })

    function cfg.refresh_options(options_to_refresh)
        for _, option in cfg.data_store do
            option:Destroy()
        end
        cfg.data_store = {}

        for _, option_data in options_to_refresh do
            local button = library:create("TextButton", {
                FontFace = fonts.small,
                TextColor3 = rgb(0, 0, 0),
                BorderColor3 = rgb(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = vec2(1, 0),
                Parent = items["list"],
                Name = "\0",
                Position = dim2(1, 0, 0, 0),
                Size = dim2(1, 0, 0, 30),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = themes.preset.light,
            })
            cfg.data_store[#cfg.data_store + 1] = button

            local name = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = themes.preset.dimtext,
                BorderColor3 = rgb(0, 0, 0),
                Text = option_data,
                Parent = button,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 14,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UICorner", {
                Parent = button,
                CornerRadius = dim(0, 3),
            })

            button.MouseButton1Click:Connect(function()
                local current = cfg.current_element
                if current and current ~= name then
                    library:tween(current, { TextColor3 = themes.preset.dimtext })
                end
                flags[cfg.flag] = option_data
                cfg.callback(option_data)
                library:tween(name, { TextColor3 = themes.preset.text })
                cfg.current_element = name
            end)

            name.MouseEnter:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = rgb(140, 140, 140) })
            end)

            name.MouseLeave:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = themes.preset.dimtext })
            end)
        end
    end

    cfg.refresh_options(cfg.options)
    return setmetatable(cfg, library)
end

function library:init_config(window)
    window:seperator({ name = "Settings" })

    local configsPage = window:tab({
        name = "Configs",
        icon = "folder",
        tabs = { "Configs" },
    })

    local left = configsPage:column({})
    local right = configsPage:column({})

    local createSec = left:section({ name = "Configs", icon = "folder", size = 1 })


    local createRow = library:create("Frame", {
        Parent = createSec.items["elements"],
        BackgroundTransparency = 1, Size = dim2(1, 0, 0, 32), BorderSizePixel = 0,
    })
    local nameBox = library:create("TextBox", {
        Parent = createRow, FontFace = fonts.font, Text = "", PlaceholderText = "config name",
        PlaceholderColor3 = themes.preset.dimtext, TextColor3 = themes.preset.text, TextSize = 14,
        BackgroundColor3 = themes.preset.light, ClearTextOnFocus = false,
        Position = dim2(0, 0, 0, 0), Size = dim2(1, -78, 1, 0), BorderSizePixel = 0,
    })
    library:create("UICorner", { Parent = nameBox, CornerRadius = dim(0, 6) })
    library:create("UIPadding", { Parent = nameBox, PaddingLeft = dim(0, 10), PaddingRight = dim(0, 10) })

    local createBtn = library:create("TextButton", {
        Parent = createRow, FontFace = fonts.font, Text = "Create", TextSize = 14,
        TextColor3 = themes.preset.text, AutoButtonColor = false, BackgroundColor3 = themes.preset.light,
        AnchorPoint = vec2(1, 0), Position = dim2(1, 0, 0, 0), Size = dim2(0, 70, 1, 0), BorderSizePixel = 0,
    })
    library:create("UICorner", { Parent = createBtn, CornerRadius = dim(0, 6) })

    local selected_config = nil
    local autoload_name = nil
    local config_rows = {}
    local show_info
    local refresh_list

    pcall(function()
        if isfile and isfile(library.directory .. "/autoload.txt") then
            autoload_name = readfile(library.directory .. "/autoload.txt")
        end
    end)

    createBtn.MouseButton1Click:Connect(function()
        local name = tostring(nameBox.Text or ""):gsub("[^%w _%-]", "")
        if name == "" then
            library:Notification({ Name = "Name required", Description = "Type a name before creating.", Icon = "triangle-alert" })
            return
        end
        local path = library.directory .. "/configs/" .. name .. ".json"
        if isfile and isfile(path) then
            library:Notification({ Name = "Already exists", Description = '"' .. name .. '" already exists.', Icon = "triangle-alert" })
            return
        end
        library:SaveConfigFile(name)
        nameBox.Text = ""
        selected_config = name
        refresh_list()
        show_info(name)
        library:Notification({ Name = "Config created", Description = '"' .. name .. '" saved.', Icon = "plus" })
    end)

    local listHolder = library:create("Frame", {
        Parent = createSec.items["elements"], Name = " ", BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
    })
    library:create("UIListLayout", { Parent = listHolder, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    local function make_icon_btn(parent, icon, x_offset, callback)
        local btn = library:create("TextButton", {
            Parent = parent, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            AnchorPoint = vec2(1, 0.5), Position = dim2(1, x_offset, 0.5, 0),
            Size = dim2(0, 22, 0, 22), BorderSizePixel = 0, ZIndex = 5,
        })
        local img = library:create("ImageLabel", {
            Parent = btn, BackgroundTransparency = 1, AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0), Size = dim2(0, 13, 0, 13),
            ImageColor3 = themes.preset.dimtext, BorderSizePixel = 0, ZIndex = 5,
        })
        ApplyIcon(img, icon)
        btn.MouseEnter:Connect(function() library:tween(img, { ImageColor3 = themes.preset.text }) end)
        btn.MouseLeave:Connect(function() library:tween(img, { ImageColor3 = themes.preset.dimtext }) end)
        btn.MouseButton1Click:Connect(callback)
        return btn, img
    end

    local function add_config_row(name)
        local row = library:create("Frame", {
            Parent = listHolder, Name = " ", Size = dim2(1, 0, 0, 36),
            BackgroundColor3 = themes.preset.light, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = row, CornerRadius = dim(0, 6) })

        local accent_bar = library:create("Frame", {
            Parent = row, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 0, 0.5, 0),
            Size = dim2(0, 3, 0, 0), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = accent_bar, CornerRadius = dim(0, 4) })
        library:apply_theme(accent_bar, "accent", "BackgroundColor3")

        local label = library:create("TextLabel", {
            Parent = row, FontFace = fonts.font, Text = name, TextSize = 14,
            TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
            Position = dim2(0, 12, 0, 0), Size = dim2(1, -120, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0,
        })


        local autoIcon = library:create("ImageLabel", {
            Parent = row, BackgroundTransparency = 1,
            AnchorPoint = vec2(0, 0.5), Position = dim2(0, 12, 0.5, 0),
            Size = dim2(0, 0, 0, 0), ImageColor3 = themes.preset.accent,
            BorderSizePixel = 0, ZIndex = 4, Visible = false,
        })
        ApplyIcon(autoIcon, "star")
        library:apply_theme(autoIcon, "accent", "ImageColor3")

        local function update_auto_visual()
            if name == autoload_name then
                autoIcon.Visible = true
                autoIcon.Size = dim2(0, 12, 0, 12)
                label.Position = dim2(0, 28, 0, 0)
                label.Size = dim2(1, -136, 1, 0)
            else
                autoIcon.Visible = false
                autoIcon.Size = dim2(0, 0, 0, 0)
                label.Position = dim2(0, 12, 0, 0)
                label.Size = dim2(1, -120, 1, 0)
            end
        end
        update_auto_visual()

        local hit = library:create("TextButton", {
            Parent = row, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            Size = dim2(1, -110, 1, 0), BorderSizePixel = 0, ZIndex = 3,
        })

        local function set_selected(active)
            label.TextColor3 = active and themes.preset.text or themes.preset.dimtext
            library:tween(accent_bar, { Size = dim2(0, 3, 0, active and 18 or 0) })
        end

        hit.MouseButton1Click:Connect(function()
            selected_config = name
            for _, r in config_rows do r.set_selected(r.name == name) end
            library:LoadConfigFile(name)
            show_info(name)
            library:Notification({ Name = "Config loaded", Description = 'Restored "' .. name .. '".', Icon = "check" })
        end)

        make_icon_btn(row, "download", -64, function()
            library:SaveConfigFile(name)
            show_info(name)
            library:Notification({ Name = "Config saved", Description = 'Overwrote "' .. name .. '".', Icon = "download" })
        end)
        make_icon_btn(row, "share-2", -42, function()
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) and setclipboard then
                setclipboard(readfile(path))
                library:Notification({ Name = "Config copied", Description = '"' .. name .. '" copied.', Icon = "share-2" })
            end
        end)
        make_icon_btn(row, "star", -20, function()
            if autoload_name == name then
                autoload_name = nil
                pcall(function()
                    if isfile(library.directory .. "/autoload.txt") then delfile(library.directory .. "/autoload.txt") end
                end)
                library:Notification({ Name = "Autoload cleared", Description = "No config will auto-load.", Icon = "star" })
            else
                autoload_name = name
                pcall(writefile, library.directory .. "/autoload.txt", name)
                library:Notification({ Name = "Autoload set", Description = '"' .. name .. '" will load on startup.', Icon = "star" })
            end

            for _, r in config_rows do
                r.update_auto()
            end
            if selected_config then show_info(selected_config) end
        end)
        make_icon_btn(row, "trash-2", 2, function()
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) then delfile(path) end
            if autoload_name == name then
                autoload_name = nil
                pcall(function()
                    if isfile(library.directory .. "/autoload.txt") then delfile(library.directory .. "/autoload.txt") end
                end)
            end
            if selected_config == name then
                selected_config = nil
                show_info(nil)
            end
            refresh_list()
            library:Notification({ Name = "Config deleted", Description = 'Removed "' .. name .. '".', Icon = "trash-2" })
        end)

        local data = {
            name = name, row = row, set_selected = set_selected,
            update_auto = update_auto_visual,
        }
        insert(config_rows, data)
        if name == selected_config then set_selected(true) end
        return data
    end

    refresh_list = function()
        for _, r in config_rows do r.row:Destroy() end
        config_rows = {}
        for _, name in library:ListConfigs() do
            add_config_row(name)
        end
    end
    refresh_list()


    local infoSec = right:section({ name = "Config info", icon = "info", size = 0.4 })
    local info_labels = {}
    local function add_info_row(key)
        local l = infoSec:label({ name = key .. ": -" })
        info_labels[key] = l
    end
    add_info_row("Config version")
    add_info_row("Compatibility")
    add_info_row("Created")
    add_info_row("Creator")
    add_info_row("Saved flags")
    add_info_row("Autoload")

    show_info = function(name)
        if not name then
            for k, l in pairs(info_labels) do l.set(k .. ": -") end
            return
        end
        local path = library.directory .. "/configs/" .. name .. ".json"
        local data = {}
        pcall(function() data = http_service:JSONDecode(readfile(path)) end)
        local count = 0
        for key in pairs(data) do
            if string.sub(tostring(key), 1, 2) ~= "__" then count = count + 1 end
        end
        local same = data.__version == library.version
        info_labels["Config version"].set("Config version: " .. (data.__version or "Unknown"))
        info_labels["Compatibility"].set("Compatibility: " .. (same and "Compatible" or "Outdated"))
        info_labels["Created"].set("Created: " .. (data.__created or "Unknown"))
        info_labels["Creator"].set("Creator: " .. (data.__creator or "Unknown"))
        info_labels["Saved flags"].set("Saved flags: " .. tostring(count) .. " flags")
        info_labels["Autoload"].set("Autoload: " .. ((autoload_name == name) and "Yes" or "No"))
    end
    show_info(nil)


    local themeSec = right:section({ name = "Theme", icon = "palette", size = 0.6 })
    themeSec:label({ name = "Presets" })

    local presets = {
        { name = "Default", color = rgb(155, 150, 219), bg = rgb(14, 14, 16), section = rgb(22, 22, 24), element = rgb(25, 25, 29), light = rgb(33, 33, 35) },
        { name = "Azure", color = rgb(96, 150, 255), bg = rgb(16, 20, 30), section = rgb(20, 25, 37), element = rgb(25, 31, 46), light = rgb(33, 41, 60) },
        { name = "Emerald", color = rgb(76, 214, 148), bg = rgb(14, 24, 20), section = rgb(18, 30, 25), element = rgb(23, 37, 31), light = rgb(30, 48, 40) },
        { name = "Ocean", color = rgb(72, 200, 214), bg = rgb(14, 23, 28), section = rgb(18, 28, 34), element = rgb(23, 35, 42), light = rgb(30, 45, 54) },
        { name = "Rose", color = rgb(240, 118, 150), bg = rgb(26, 17, 21), section = rgb(32, 21, 26), element = rgb(39, 26, 32), light = rgb(50, 33, 41) },
    }
    local dotsHolder = library:create("Frame", {
        Parent = themeSec.items["elements"], BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 24), BorderSizePixel = 0,
    })
    library:create("UIListLayout", {
        Parent = dotsHolder, FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left, Padding = dim(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for _, preset in presets do
        local dot = library:create("TextButton", {
            Parent = dotsHolder, Text = "", AutoButtonColor = false,
            Size = dim2(0, 18, 0, 18), BackgroundColor3 = preset.color, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = dot, CornerRadius = dim(1, 0) })
        local stroke = library:create("UIStroke", { Parent = dot, Color = rgb(255, 255, 255), Thickness = 0 })
        dot.MouseButton1Click:Connect(function()
            library:update_theme("accent", preset.color)

            themes.preset.background = preset.bg or themes.preset.background
            themes.preset.section = preset.section or themes.preset.section
            themes.preset.element = preset.element or themes.preset.element
            themes.preset.light = preset.light or themes.preset.light

            library:update_theme("accent", preset.color)
            if config_flags["menu_accent"] then
                pcall(config_flags["menu_accent"], preset.color)
            else
                flags["menu_accent"] = { Color = preset.color, Transparency = 0 }
            end
            if config_flags["theme_bg"] then pcall(config_flags["theme_bg"], themes.preset.background) end
            if config_flags["theme_section"] then pcall(config_flags["theme_section"], themes.preset.section) end
            for _, child in dotsHolder:GetChildren() do
                if child:IsA("TextButton") then
                    local s = child:FindFirstChildOfClass("UIStroke")
                    if s then s.Thickness = (child == dot) and 2 or 0 end
                end
            end
        end)
    end

    themeSec:colorpicker({
        name = "Accent", flag = "menu_accent", color = themes.preset.accent,
        callback = function(color)
            library:update_theme("accent", color)
        end,
    })
    themeSec:colorpicker({
        name = "Background", flag = "theme_bg", color = themes.preset.background,
        callback = function(color) themes.preset.background = color end,
    })
    themeSec:colorpicker({
        name = "Section", flag = "theme_section", color = themes.preset.section,
        callback = function(color) themes.preset.section = color end,
    })
    themeSec:keybind({
        name = "Menu Bind", flag = "menu_bind",
        key = library.MenuKeybind or Enum.KeyCode.RightControl, mode = "Toggle",
        callback = function(bool)
            if window and window.toggle_menu then window.toggle_menu(bool) end
        end,
        default = true,
    })

    do
        local old_set = config_flags["menu_bind"]
        if old_set then
            config_flags["menu_bind"] = function(value)
                old_set(value)
                local key = value
                if type(value) == "table" then key = value.key or value[1] end
                if typeof(key) == "EnumItem" then
                    library.MenuKeybind = key
                    if library.ProfileKeyBox then
                        library.ProfileKeyBox.Text = keys[key] or key.Name
                    end
                end
            end
        end
    end


    if autoload_name then
        task.defer(function()
            if library:LoadConfigFile(autoload_name) then
                selected_config = autoload_name
                refresh_list()
                show_info(autoload_name)
            end
        end)
    end
end

function library:UserPanel(window)
    local userTab = window:tab({
        name = "User",
        icon = "user",
        tabs = { "Profile" },
    })

    local col = userTab:column({})
    local sec = col:section({ name = "Profile", icon = "user", size = 1 })

    local display = lp.DisplayName or lp.Name
    local uname = "@" .. (lp.Name or "unknown")
    local uid = tostring(lp.UserId or 0)

    local accountAge = "Unknown"
    pcall(function()
        accountAge = tostring(lp.AccountAge or 0) .. " days"
    end)

    sec:label({ name = display })
    sec:label({ name = uname })
    sec:label({ name = "User ID: " .. uid })
    sec:label({ name = "Account age: " .. accountAge })
    sec:label({ name = "Library: Chromatik v" .. library.version })





    local menuKeyLabel = "RCtrl"
    pcall(function()
        local f = flags["menu_bind"]
        if type(f) == "table" and f.key then
            local k = f.key
            if typeof(k) == "EnumItem" then
                menuKeyLabel = keys[k] or k.Name
            else
                menuKeyLabel = tostring(k):gsub("Enum.KeyCode.", ""):gsub("KeyCode.", "")
            end
        end
    end)
    sec:label({ name = "Menu key: " .. tostring(menuKeyLabel) .. "  (change in Configs)" })

    sec:button({
        name = "Unload",
        callback = function()
            library:Notification({ Name = "Unloading", Description = "Chromatik is shutting down.", Icon = "power" })
            task.wait(0.4)
            library:unload_menu()
        end,
    })

    return sec
end


-- Keep floating panels on-screen (keybind list / ESP preview)
local function clamp_panel_position(x, y, panel_w, panel_h)
    local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    panel_w = tonumber(panel_w) or 280
    panel_h = tonumber(panel_h) or 120
    local margin = 8
    local max_x = math.max(margin, vp.X - panel_w - margin)
    local max_y = math.max(margin, vp.Y - panel_h - margin)
    x = tonumber(x) or margin
    y = tonumber(y) or margin
    -- treat clearly broken / off-screen saves as defaults
    if x < -panel_w + 40 or x > vp.X - 40 or y < -40 or y > vp.Y - 40 then
        x, y = margin, math.floor(vp.Y * 0.35)
    end
    return math.clamp(x, margin, max_x), math.clamp(y, margin, max_y)
end

function library:KeybindList(params)
    params = params or {}
    if library.KeybindListInstance and library.KeybindListInstance.Gui then
        return library.KeybindListInstance
    end

    local title = params.Title or params.Name or "Keybind list"
    local position = params.Position or dim2(0, 18, 0.4, 0)
    local visible = params.Visible ~= false


    local pos_file = library.directory .. "/keybindlist_pos.json"
    pcall(function()
        if isfile and isfile(pos_file) then
            local data = http_service:JSONDecode(readfile(pos_file))
            if type(data) == "table" and data.x ~= nil and data.y ~= nil then
                local cx, cy = clamp_panel_position(data.x, data.y, 280, 200)
                position = dim2(0, cx, 0, cy)
            end
        end
    end)
    -- also clamp default/param positions that use only scale (can land off-screen after res change)
    do
        local ox = position.X.Offset + (camera.ViewportSize.X * position.X.Scale)
        local oy = position.Y.Offset + (camera.ViewportSize.Y * position.Y.Scale)
        local cx, cy = clamp_panel_position(ox, oy, 280, 200)
        position = dim2(0, cx, 0, cy)
    end

    local gui = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = true,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9990,
    })

    local panel = library:create("Frame", {
        Parent = gui,
        Position = position,
        Size = dim2(0, 280, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 70,
        Active = true,
    })
    library:create("UICorner", { Parent = panel, CornerRadius = dim(0, 10) })

    local function save_keybindlist_pos()
        pcall(function()
            if not writefile then return end
            pcall(makefolder, library.directory)
            local p = panel.Position
            writefile(pos_file, http_service:JSONEncode({
                x = math.floor(p.X.Offset + 0.5),
                y = math.floor(p.Y.Offset + 0.5),
            }))
        end)
    end
    library:create("UIStroke", {
        Parent = panel,
        Color = rgb(30, 30, 36),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    library:create("UIPadding", {
        Parent = panel,
        PaddingTop = dim(0, 12),
        PaddingBottom = dim(0, 10),
        PaddingLeft = dim(0, 12),
        PaddingRight = dim(0, 12),
    })
    library:create("UIListLayout", {
        Parent = panel,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 8),
    })


    local header = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 22),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 0,
    })


    local listIcon = library:create("ImageButton", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = dim2(0, 16, 0, 16),
        Position = dim2(0, 0, 0.5, -8),
        ImageColor3 = themes.preset.accent,
        BorderSizePixel = 0,
        ZIndex = 73,
        ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(listIcon, "menu")
    library:apply_theme(listIcon, "accent", "ImageColor3")

    local titleLabel = library:create("TextLabel", {
        Parent = header,
        FontFace = fonts.font,
        Text = title,
        TextSize = 15,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 22, 0, 0),
        Size = dim2(1, -44, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 72,
    })


    local pinBtn = library:create("ImageButton", {
        Parent = header,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, 0, 0.5, 0),
        Size = dim2(0, 16, 0, 16),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 73,
        ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(pinBtn, "pin")

    local pinned = false
    pinBtn.MouseButton1Click:Connect(function()
        pinned = not pinned
        pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
    end)


    local cols = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 1,
        Name = "Cols",
    })

    local function colHeader(text, xScale, xOffset, width, align)
        return library:create("TextLabel", {
            Parent = cols,
            FontFace = fonts.font,
            Text = text,
            TextSize = 12,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(xScale, xOffset, 0, 0),
            Size = dim2(0, width, 1, 0),
            TextXAlignment = align or Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            ZIndex = 72,
        })
    end
    colHeader("Function", 0, 4, 100, Enum.TextXAlignment.Left)
    colHeader("Hotkey", 0.5, -10, 50, Enum.TextXAlignment.Center)
    colHeader("Status", 1, -70, 66, Enum.TextXAlignment.Right)

    local divider = library:create("Frame", {
        Parent = panel,
        Size = dim2(1, 0, 0, 1),
        BackgroundColor3 = themes.preset.line or rgb(21, 21, 23),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 2,
        Name = "Divider",
    })

    local rowsFolder = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 3,
        Name = "Rows",
    })
    library:create("UIListLayout", {
        Parent = rowsFolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 2),
    })


    local collapsed = false
    local animating = false
    local body = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 1,
        ClipsDescendants = true,
        Name = "Body",
    })

    cols.Parent = body
    cols.LayoutOrder = 1
    divider.Parent = body
    divider.LayoutOrder = 2
    rowsFolder.Parent = body
    rowsFolder.LayoutOrder = 3
    library:create("UIListLayout", {
        Parent = body,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 8),
    })

    local function fade_descendants(root, transparency, t)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                library:tween(d, { TextTransparency = transparency }, Enum.EasingStyle.Quart, t)
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                library:tween(d, { ImageTransparency = transparency }, Enum.EasingStyle.Quart, t)
            elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then

            end
        end

        for _, d in ipairs(root:GetChildren()) do
            if d:IsA("TextLabel") then
                library:tween(d, { TextTransparency = transparency }, Enum.EasingStyle.Quart, t)
            end
        end
    end

    local function measure_body()

        local h = 0
        pcall(function()
            h = body.AbsoluteSize.Y
        end)
        if h < 1 then

            local rows = 0
            for _, ch in ipairs(rowsFolder:GetChildren()) do
                if ch:IsA("GuiObject") and ch.Visible then
                    rows = rows + ch.AbsoluteSize.Y + 2
                end
            end
            h = 16 + 1 + 8 + math.max(rows, 0)
        end
        return math.max(h, 0)
    end

    local function set_collapsed(state)
        if animating then return end
        local want = state == true
        if want == collapsed then return end
        animating = true
        collapsed = want

        local duration = 0.28

        if collapsed then

            body.AutomaticSize = Enum.AutomaticSize.None
            local h = measure_body()
            if h < 8 then h = 40 end
            body.Size = dim2(1, 0, 0, h)
            fade_descendants(body, 1, duration * 0.7)
            library:tween(body, { Size = dim2(1, 0, 0, 0) }, Enum.EasingStyle.Quart, duration)
            library:tween(listIcon, { ImageColor3 = themes.preset.dimtext, Rotation = -90 }, Enum.EasingStyle.Quart, duration)
            task.delay(duration, function()
                if collapsed then
                    cols.Visible = false
                    divider.Visible = false
                    rowsFolder.Visible = false
                end
                animating = false
            end)
        else
            cols.Visible = true
            divider.Visible = true
            rowsFolder.Visible = true

            body.AutomaticSize = Enum.AutomaticSize.None
            body.Size = dim2(1, 0, 0, 0)

            fade_descendants(body, 1, 0)
            task.defer(function()
                local target = measure_body()
                if target < 8 then

                    task.wait()
                    target = measure_body()
                end
                if target < 8 then target = 48 end
                library:tween(body, { Size = dim2(1, 0, 0, target) }, Enum.EasingStyle.Quart, duration)
                fade_descendants(body, 0, duration)
                library:tween(listIcon, { ImageColor3 = themes.preset.accent, Rotation = 0 }, Enum.EasingStyle.Quart, duration)
                task.delay(duration, function()
                    if not collapsed then
                        body.AutomaticSize = Enum.AutomaticSize.Y
                        body.Size = dim2(1, 0, 0, 0)
                    end
                    animating = false
                end)
            end)
        end
    end

    listIcon.MouseButton1Click:Connect(function()
        set_collapsed(not collapsed)
    end)

    local row_map = {}

    local function key_label(key)
        if not key or key == "NONE" then return "—" end
        if typeof(key) == "EnumItem" then
            return keys[key] or tostring(key.Name):gsub("KeyCode.", ""):gsub("UserInputType.", "")
        end
        return tostring(key)
            :gsub("Enum.KeyCode.", "")
            :gsub("Enum.UserInputType.", "")
            :gsub("KeyCode.", "")
    end

    local function read_active(entry)

        local active = false
        if entry.get_active then
            local ok, v = pcall(entry.get_active)
            if ok and v == true then return true end
            if ok and v == false then active = false end
        end
        local f = flags[entry.flag]
        if type(f) == "table" and f.active == true then return true end
        if entry.cfg and entry.cfg.active == true then return true end
        return active
    end

    local function ensure_row(entry, order)
        local flag = entry.flag
        local row = row_map[flag]
        if row and row.frame and row.frame.Parent then
            row.entry = entry
            row.frame.LayoutOrder = order or row.frame.LayoutOrder
            return row
        end

        local frame = library:create("TextButton", {
            Parent = rowsFolder,
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = themes.preset.element,
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 28),
            BorderSizePixel = 0,
            ZIndex = 72,
            LayoutOrder = order or 0,
        })
        library:create("UICorner", { Parent = frame, CornerRadius = dim(0, 6) })

        local nameLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = entry.name or flag,
            TextSize = 13,
            TextColor3 = themes.preset.text,
            BackgroundTransparency = 1,
            Position = dim2(0, 4, 0, 0),
            Size = dim2(0.42, -4, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        local keyLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = "—",
            TextSize = 13,
            TextColor3 = themes.preset.text,
            BackgroundTransparency = 1,
            Position = dim2(0.42, 0, 0, 0),
            Size = dim2(0.22, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        local statusLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = "Toggle",
            TextSize = 13,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0.64, 0, 0, 0),
            Size = dim2(0.36, -4, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        frame.MouseEnter:Connect(function()
            if collapsed then return end
            local r = row_map[flag]
            if r then r._hovered = true end
            frame.BackgroundTransparency = 0
            frame.BackgroundColor3 = themes.preset.element
        end)
        frame.MouseLeave:Connect(function()
            local r = row_map[flag]
            if r then r._hovered = false end
            local active = false
            if r and r.entry then active = read_active(r.entry) end
            frame.BackgroundTransparency = active and 0.35 or 1
        end)

        row = {
            frame = frame,
            nameLbl = nameLbl,
            keyLbl = keyLbl,
            statusLbl = statusLbl,
            entry = entry,
            _hovered = false,
        }
        row_map[flag] = row
        return row
    end

    local function read_mode(entry)
        local mode = "Toggle"
        pcall(function()
            if entry.get_mode then
                mode = tostring(entry.get_mode() or mode)
            elseif entry.cfg and entry.cfg.mode then
                mode = tostring(entry.cfg.mode)
            elseif flags[entry.flag] and type(flags[entry.flag]) == "table" and flags[entry.flag].mode then
                mode = tostring(flags[entry.flag].mode)
            end
        end)
        mode = mode:gsub("^%l", string.upper)
        if mode ~= "Hold" and mode ~= "Always" then mode = "Toggle" end
        return mode
    end

    local function apply_row_state(row, active, key, mode)
        row.keyLbl.Text = key_label(key)
        mode = mode or read_mode(row.entry or {})


        if row.statusLbl then
            row.statusLbl.Text = mode
            row.statusLbl.TextColor3 = active and themes.preset.accent or themes.preset.dimtext
        end
        if active then
            row.nameLbl.TextColor3 = themes.preset.text
            row.keyLbl.TextColor3 = themes.preset.accent
            row.frame.BackgroundTransparency = 0.35
            row.frame.BackgroundColor3 = themes.preset.element
        else
            row.nameLbl.TextColor3 = themes.preset.text
            row.keyLbl.TextColor3 = themes.preset.text
            if not row._hovered then
                row.frame.BackgroundTransparency = 1
            end
        end
    end

    local function refresh()
        local seen = {}
        local order = 0
        for _, entry in ipairs(library.keybind_registry or {}) do
            if entry.name and entry.name ~= "" then
                order = order + 1
                seen[entry.flag] = true
                local row = ensure_row(entry, order)
                local active = read_active(entry)
                local key = "NONE"
                pcall(function()
                    if entry.get_key then key = entry.get_key() end
                end)
                row.nameLbl.Text = tostring(entry.name)
                local mode = read_mode(entry)
                apply_row_state(row, active, key, mode)
                row._was_active = active
                row._last_key = key
                row._last_mode = mode
            end
        end
        for flag, row in pairs(row_map) do
            if not seen[flag] then
                pcall(function() row.frame:Destroy() end)
                row_map[flag] = nil
            end
        end
    end


    do
        local dragging, start, start_pos
        local function begin_drag(input)
            if pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = input.Position
                start_pos = panel.Position
            end
        end
        header.InputBegan:Connect(begin_drag)
        titleLabel.InputBegan:Connect(begin_drag)
        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    save_keybindlist_pos()
                end
            end
        end)
        library:connection(uis.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    save_keybindlist_pos()
                end
            end
        end)
        library:connection(uis.InputChanged, function(input)
            if not dragging or pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local nx = start_pos.X.Offset + (input.Position.X - start.X)
                local ny = start_pos.Y.Offset + (input.Position.Y - start.Y)
                local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or 280
                local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or 120
                nx, ny = clamp_panel_position(nx, ny, pw, ph)
                panel.Position = dim2(0, nx, 0, ny)
            end
        end)
    end

    local _kbListAccum = 0
    library:connection(run.Heartbeat, function(dt)
        if not panel.Parent or not panel.Visible then return end
        _kbListAccum = _kbListAccum + (dt or 0.016)
        if _kbListAccum < 0.1 then return end
        _kbListAccum = 0

        for _, row in pairs(row_map) do
            local entry = row.entry
            if entry then
                local active = read_active(entry)
                local key = "NONE"
                pcall(function()
                    if entry.get_key then key = entry.get_key() end
                end)
                local mode = read_mode(entry)
                if row._was_active ~= active or row._last_key ~= key or row._last_mode ~= mode then
                    row._was_active = active
                    row._last_key = key
                    row._last_mode = mode
                    if not collapsed then
                        apply_row_state(row, active, key, mode)
                    end
                end
            end
        end
    end)

    local api = {
        Gui = gui,
        Panel = panel,
        Refresh = refresh,
        ResetPosition = function()
            local cx, cy = clamp_panel_position(18, math.floor((camera.ViewportSize.Y or 800) * 0.38), 280, 200)
            panel.Position = dim2(0, cx, 0, cy)
            save_keybindlist_pos()
        end,
        SetVisible = function(bool)
            visible = bool == true
            panel.Visible = visible
        end,
        SetCollapsed = set_collapsed,
        SetPinned = function(bool)
            pinned = bool == true
            pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
            if pinned then dock_to_main() end
        end,
        DockToMain = function()
            dock_to_main()
        end,
        SetTitle = function(t)
            titleLabel.Text = tostring(t)
        end,
        Destroy = function()
            pcall(function() gui:Destroy() end)
            library.KeybindListInstance = nil
        end,
    }

    library.KeybindListInstance = api
    refresh()
    task.defer(function()
        pcall(function()
            local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or 280
            local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or 120
            local cx, cy = clamp_panel_position(panel.AbsolutePosition.X, panel.AbsolutePosition.Y, pw, ph)
            panel.Position = dim2(0, cx, 0, cy)
            save_keybindlist_pos()
        end)
    end)
    return api
end

function library:Watermark(params)
    params = params or {}
    if library.WatermarkBar then
        return library.WatermarkBar
    end


    if not library["watermark_gui"] then
        library["watermark_gui"] = library:create("ScreenGui", {
            Parent = coregui,
            Name = "\0",
            Enabled = true,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 9999,
        })
    end

    local Icon = params.Icon or "layers"
    local Items = {}

    Items.Bar = library:create("Frame", {
        Parent = library["watermark_gui"],
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 0, 14),
        Size = dim2(0, 0, 0, 32),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 60,
        Active = false,
    })
    Items.Bar.AutomaticSize = Enum.AutomaticSize.X

    library:create("UICorner", {
        Parent = Items.Bar,
        CornerRadius = dim(0, 8),
    })

    library:create("UIPadding", {
        Parent = Items.Bar,
        PaddingLeft = dim(0, 12),
        PaddingRight = dim(0, 12),
    })

    library:create("UIListLayout", {
        Parent = Items.Bar,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 10),
    })

    local order = 0
    local function NextOrder()
        order = order + 1
        return order
    end

    local iconLabel = library:create("ImageLabel", {
        Parent = Items.Bar,
        BackgroundTransparency = 1,
        Size = dim2(0, 20, 0, 20),
        ImageColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 61,
        ScaleType = Enum.ScaleType.Fit,
    })
    iconLabel.LayoutOrder = NextOrder()
    ApplyIcon(iconLabel, Icon)

    local function Separator()
        local Sep = library:create("Frame", {
            Parent = Items.Bar,
            Size = dim2(0, 1, 0, 14),
            BackgroundColor3 = themes.preset.light,
            BorderSizePixel = 0,
            ZIndex = 61,
        })
        Sep.LayoutOrder = NextOrder()
    end

    local function Stat(Text)
        local Label = library:create("TextLabel", {
            Parent = Items.Bar,
            FontFace = fonts.font,
            Text = Text,
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Size = dim2(0, 0, 0, 16),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 61,
        })
        Label.LayoutOrder = NextOrder()
        return Label
    end

    Separator()
    local GameStat = Stat("...")
    Separator()
    local FpsStat = Stat("0 fps")
    Separator()
    local PingStat = Stat("0 ms")
    Separator()
    local TimeStat = Stat(os.date("%I:%M %p"))

    task.spawn(function()
        local Ok, Info = pcall(function()
            return marketplace:GetProductInfo(game.PlaceId)
        end)
        GameStat.Text = (Ok and Info and Info.Name) or "Unknown"
    end)

    local Frames = 0
    library:connection(run.RenderStepped, function()
        Frames = Frames + 1
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not Items.Bar or not Items.Bar.Parent then
                break
            end
            FpsStat.Text = tostring(Frames * 2) .. " fps"
            Frames = 0

            local Ping = 0
            pcall(function()
                local Stat = stats.Network.ServerStatsItem["Data Ping"]
                Ping = floor(Stat:GetValue())
            end)
            PingStat.Text = tostring(Ping) .. " ms"
            TimeStat.Text = os.date("%I:%M %p")
        end
    end)


    Items.Bar.Active = false
    library.WatermarkBar = Items.Bar

    local Watermark = { Instance = Items.Bar }

    function Watermark:SetIcon(NewIcon)
        ApplyIcon(iconLabel, NewIcon)
    end

    function Watermark:SetVisible(Bool)
        Items.Bar.Visible = Bool
    end

    return Watermark
end

library.Notifs = {}

function library:Notification(Params)
    if library.silent then return end

    Params = Params or {}
    local Title = Params.Name or Params.Title or "Notification"
    local Content = Params.Description or Params.Content or Params.info or ""
    local Icon = Params.Icon or Params.icon or "bell"
    local Accent = Params.Color or themes.preset.accent
    local Duration = Params.Duration or Params.lifetime or 5

    local CardW = 300
    local bodyH = 0
    if Content ~= "" then
        bodyH = math.max(18, math.ceil(#Content / 36) * 16)
    end
    local CardH = 38 + (Content ~= "" and bodyH + 6 or 0) + 18

    local parent = library["items"] or coregui

    local Frame = library:create("Frame", {
        Parent = parent,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, 340, 0, 15),
        Size = dim2(0, CardW, 0, CardH),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 80,
    })

    library:create("UICorner", {
        Parent = Frame,
        CornerRadius = dim(0, 10),
    })

    local IconImg = library:create("ImageLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Position = dim2(0, 13, 0, 11),
        Size = dim2(0, 18, 0, 18),
        ImageColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 81,
    })
    ApplyIcon(IconImg, Icon)

    library:create("TextLabel", {
        Parent = Frame,
        FontFace = fonts.font,
        Text = Title,
        TextSize = 15,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 40, 0, 10),
        Size = dim2(1, -70, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        ZIndex = 81,
    })

    local CloseImg = library:create("ImageLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -13, 0, 13),
        Size = dim2(0, 14, 0, 14),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 82,
    })
    ApplyIcon(CloseImg, "x")

    local CloseHit = library:create("TextButton", {
        Parent = Frame,
        Text = "",
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -8, 0, 8),
        Size = dim2(0, 24, 0, 24),
        BorderSizePixel = 0,
        ZIndex = 83,
    })

    if Content ~= "" then
        library:create("TextLabel", {
            Parent = Frame,
            FontFace = fonts.font,
            Text = Content,
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0, 13, 0, 35),
            Size = dim2(1, -26, 0, bodyH),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            BorderSizePixel = 0,
            ZIndex = 81,
        })
    end

    local BarBack = library:create("Frame", {
        Parent = Frame,
        Position = dim2(0, 13, 1, -12),
        Size = dim2(1, -26, 0, 5),
        BackgroundColor3 = themes.preset.element or themes.preset.light,
        BorderSizePixel = 0,
        ZIndex = 81,
    })
    library:create("UICorner", { Parent = BarBack, CornerRadius = dim(0, 4) })

    local BarFill = library:create("Frame", {
        Parent = BarBack,
        Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 82,
    })
    library:create("UICorner", { Parent = BarFill, CornerRadius = dim(0, 4) })
    library:apply_theme(BarFill, "accent", "BackgroundColor3")

    local Notif = {
        Frame = Frame,
        Dead = false,
        Height = CardH,
    }
    insert(library.Notifs, Notif)

    local function StackHeight(Stop)
        local Y = 15
        for _, Value in library.Notifs do
            if Value == Stop then break end
            if Value.Dead then continue end
            Y = Y + Value.Height + 10
        end
        return Y
    end

    local function Reflow()
        local Y = 15
        for _, Value in library.Notifs do
            if Value.Dead then continue end
            library:tween(Value.Frame, { Position = dim2(1, -15, 0, Y) }, Enum.EasingStyle.Quart, 0.3)
            Y = Y + Value.Height + 10
        end
    end

    local StartY = StackHeight(Notif)
    Frame.Position = dim2(1, 340, 0, StartY)
    library:tween(Frame, { Position = dim2(1, -15, 0, StartY) }, Enum.EasingStyle.Exponential, 0.45)

    local function Dismiss()
        if Notif.Dead then return end
        Notif.Dead = true
        local Current = Frame.Position
        library:tween(Frame, { Position = dim2(1, -15, 0, Current.Y.Offset - 14) }, Enum.EasingStyle.Quart, 0.25)
        library:tween(Frame, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
        for _, d in Frame:GetDescendants() do
            if d:IsA("TextLabel") then
                library:tween(d, { TextTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            elseif d:IsA("ImageLabel") then
                library:tween(d, { ImageTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            elseif d:IsA("Frame") then
                library:tween(d, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            end
        end
        task.delay(0.3, function()
            local Index = find(library.Notifs, Notif)
            if Index then remove(library.Notifs, Index) end
            Frame:Destroy()
            Reflow()
        end)
    end

    CloseHit.MouseButton1Down:Connect(Dismiss)
    library:tween(BarFill, { Size = dim2(0, 0, 1, 0) }, Enum.EasingStyle.Linear, Duration)
    task.delay(Duration, Dismiss)
end


-- ============================================================
-- ESP Preview: floating panel (like Keybind list)
-- ============================================================
-- ESP Preview: floating panel (like Keybind list)
-- ============================================================
-- ESP Preview: floating panel (like Keybind list)
-- ============================================================
-- ESP Preview: floating panel (like Keybind list)
-- Uses 3D adornments/beams inside ViewportFrame (Highlight/2D overlays are unreliable there)
-- ============================================================
function library:EspPreview(options)
    options = options or {}
    if library.EspPreviewInstance and library.EspPreviewInstance.Gui and library.EspPreviewInstance.Gui.Parent then
        local existing = library.EspPreviewInstance
        if options.Visible ~= false then
            pcall(function()
                if existing.SetVisible then existing.SetVisible(true) end
                if existing.Refresh then existing.Refresh() end
            end)
        end
        return existing
    end

    local getVisuals = options.GetVisuals or options.getVisuals or function() return {} end
    local getPlayer = options.GetPlayer or options.getPlayer or function() return lp end
    local enabledFlag = options.Flag or options.flag or "esp_preview_enabled"
    local title = options.Title or options.Name or options.name or "ESP Preview"
    local height = tonumber(options.Height or options.height) or 320
    local width = tonumber(options.Width or options.width) or 260
    local visible = options.Visible ~= false
    local position = options.Position or dim2(1, -width - 18, 0.32, 0)

    local pos_file = library.directory .. "/esppreview_pos.json"
    pcall(function()
        if isfile and isfile(pos_file) then
            local data = http_service:JSONDecode(readfile(pos_file))
            if type(data) == "table" and data.x ~= nil and data.y ~= nil then
                local cx, cy = clamp_panel_position(data.x, data.y, width, height + 42)
                position = dim2(0, cx, 0, cy)
            end
        end
    end)
    do
        local ox = position.X.Offset + (camera.ViewportSize.X * position.X.Scale)
        local oy = position.Y.Offset + (camera.ViewportSize.Y * position.Y.Scale)
        local cx, cy = clamp_panel_position(ox, oy, width, height + 42)
        position = dim2(0, cx, 0, cy)
    end

    local gui = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = true,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9988,
    })

    local panel = library:create("Frame", {
        Parent = gui,
        Position = position,
        Size = dim2(0, width, 0, height + 42),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 70,
        Active = true,
        ClipsDescendants = true,
    })
    library:create("UICorner", { Parent = panel, CornerRadius = dim(0, 10) })
    library:create("UIStroke", {
        Parent = panel, Color = rgb(23, 23, 29), Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local function save_pos()
        pcall(function()
            if not writefile then return end
            pcall(makefolder, library.directory)
            local p = panel.Position
            writefile(pos_file, http_service:JSONEncode({
                x = math.floor(p.X.Offset + 0.5),
                y = math.floor(p.Y.Offset + 0.5),
            }))
        end)
    end

    local header = library:create("Frame", {
        Parent = panel, BackgroundTransparency = 1, Size = dim2(1, 0, 0, 36),
        BorderSizePixel = 0, ZIndex = 72, Active = true,
    })
    local listIcon = library:create("ImageButton", {
        Parent = header, BackgroundTransparency = 1, Position = dim2(0, 10, 0.5, -8),
        Size = dim2(0, 16, 0, 16), ImageColor3 = themes.preset.accent,
        BorderSizePixel = 0, ZIndex = 73, ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(listIcon, "eye")
    library:apply_theme(listIcon, "accent", "ImageColor3")

    local titleLabel = library:create("TextLabel", {
        Parent = header, FontFace = fonts.font, Text = title, TextSize = 15,
        TextColor3 = themes.preset.text, BackgroundTransparency = 1,
        Position = dim2(0, 32, 0, 0), Size = dim2(1, -110, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 72,
    })

    local pinned = true -- locked to main menu by default
    local DOCK_GAP = 12
    local function dock_to_main()
        if not panel or not panel.Parent then return end
        if not pinned then return end
        local main = nil
        pcall(function()
            if shared and shared._juruMenuMain and shared._juruMenuMain.Parent then
                main = shared._juruMenuMain
            end
        end)
        if not main then
            pcall(function()
                local sg = library.items
                if sg then
                    for _, ch in ipairs(sg:GetChildren()) do
                        if ch:IsA("Frame") and ch.AbsoluteSize.X > 400 then
                            main = ch
                            break
                        end
                    end
                end
            end)
        end
        if not main then return end
        local ap, asz = main.AbsolutePosition, main.AbsoluteSize
        local pw = (panel.AbsoluteSize.X > 10 and panel.AbsoluteSize.X) or width
        local ph = (panel.AbsoluteSize.Y > 10 and panel.AbsoluteSize.Y) or (height + 42)
        local menuH = asz.Y > 80 and asz.Y or 575
        local menuW = asz.X > 80 and asz.X or 720
        local x = ap.X + menuW + DOCK_GAP
        local y = ap.Y + menuH * 0.5 - ph * 0.5 -- dead vertical center of menu
        local vs = camera.ViewportSize
        if x + pw > vs.X - 6 then
            x = max(6, ap.X - pw - DOCK_GAP)
        end
        if y < 6 then y = 6 end
        if y + ph > vs.Y - 6 then
            y = max(6, vs.Y - ph - 6)
        end
        panel.Position = dim2(0, floor(x + 0.5), 0, floor(y + 0.5))

        -- follow main menu visibility
        pcall(function()
            local menuOn = true
            if library.items and library.items.Enabled == false then menuOn = false end
            if shared and shared._juruMenuOpen == false then menuOn = false end
            if main and main.Visible == false then menuOn = false end
            panel.Visible = state.open and menuOn
        end)
    end

    -- pin removed (permanently docked)
    local pinBtn = { ImageColor3 = themes.preset.accent }

    local closeBtn = library:create("ImageButton", {
        Parent = header, BackgroundTransparency = 1, AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -10, 0.5, 0), Size = dim2(0, 14, 0, 14),
        ImageColor3 = themes.preset.dimtext, BorderSizePixel = 0, ZIndex = 73, ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(closeBtn, "x")

    local body = library:create("Frame", {
        Parent = panel, BackgroundTransparency = 1, Position = dim2(0, 8, 0, 36),
        Size = dim2(1, -16, 1, -44), BorderSizePixel = 0, ZIndex = 71, ClipsDescendants = true,
    })

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "Viewport"
    viewport.BackgroundColor3 = rgb(18, 18, 22)
    viewport.BorderSizePixel = 0
    viewport.Size = dim2(1, 0, 1, 0)
    viewport.ZIndex = 71
    viewport.Ambient = Color3.fromRGB(200, 200, 210)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-0.4, -1, -0.3)
    viewport.Parent = body
    library:create("UICorner", { Parent = viewport, CornerRadius = dim(0, 6) })

    local cam = Instance.new("Camera")
    cam.FieldOfView = 70
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    -- transparent input catcher for orbit (no 2D ESP here — ESP is 3D inside VF)
    local inputLayer = library:create("TextButton", {
        Parent = body, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 80, Active = true,
    })

    local statusLabel = library:create("TextLabel", {
        Parent = body, FontFace = fonts.font, Text = "Loading character...", TextSize = 13,
        TextColor3 = rgb(200, 200, 210), BackgroundTransparency = 1,
        Size = dim2(1, -16, 1, 0), Position = dim2(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true, BorderSizePixel = 0, Visible = true, ZIndex = 90,
    })

    local state = {
        open = visible == true,
        rotation = 0, -- Atlanta-style auto spin
        clone = nil,
        focus = Vector3.new(0, 1.5, 0),
        lastCloneAt = 0,
        destroyed = false,
        idleTrack = nil,
        -- ESP object lists
        chamAdorns = {},
        skeletonBeams = {},
        nameBillboard = nil,
        distBillboard = nil,
        weaponBillboard = nil,
        boxAdorn = nil,
        hpBg = nil,
        hpFill = nil,
        lastVisKey = "",
        previewHighlight = nil,
        _skelEnabled = false,
        _skelColor = nil,
    }
    local ensureSkeletonBones, hideSkeletonBones, updateSkeletonBones, ensureSkeletonOverlay, hideSkeletonOverlay, updateSkeletonOverlay
    flags[enabledFlag] = state.open

    local function fireCallback(on)
        pcall(function() flags[enabledFlag] = on == true end)
        if type(options.Callback) == "function" or type(options.callback) == "function" then
            pcall(options.Callback or options.callback, on == true)
        end
    end

    local function findRoot(model)
        if not model then return nil end
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or model.PrimaryPart
    end

    local function clearEspObjects()
        for _, a in ipairs(state.chamAdorns) do pcall(function() a:Destroy() end) end
        state.chamAdorns = {}
        for _, b in ipairs(state.skeletonBeams) do
            pcall(function()
                if b.beam then b.beam:Destroy() end
                if b.a0 then b.a0:Destroy() end
                if b.a1 then b.a1:Destroy() end
            end)
        end
        state.skeletonBeams = {}
        for _, key in ipairs({"nameBillboard", "distBillboard", "weaponBillboard", "boxAdorn", "hpBg", "hpFill"}) do
            local obj = state[key]
            if obj then pcall(function() obj:Destroy() end) end
            state[key] = nil
        end
        state.lastVisKey = ""
    end

    local function destroyClone()
        if state.previewHighlight then
            pcall(function() state.previewHighlight:Destroy() end)
            state.previewHighlight = nil
        end
        pcall(hideSkeletonBones)
        clearEspObjects()
        if state.idleTrack then
            pcall(function() state.idleTrack:Stop(0) end)
            state.idleTrack = nil
        end
        if state.clone then
            pcall(function() state.clone:Destroy() end)
            state.clone = nil
        end
        for _, ch in ipairs(viewport:GetChildren()) do
            if ch ~= cam and (ch:IsA("Model") or ch:IsA("BasePart") or ch:IsA("WorldModel") or ch:IsA("Folder")) then
                pcall(function() ch:Destroy() end)
            end
        end
    end

    local IDLE_R15 = "rbxassetid://507766666"
    local IDLE_R6 = "rbxassetid://180435571"

    local function playIdleOnly(clone)
        if not clone then return end
        pcall(function()
            local hum = clone:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = hum
            end
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
            local isR15 = clone:FindFirstChild("UpperTorso") ~= nil
            local anim = Instance.new("Animation")
            anim.AnimationId = isR15 and IDLE_R15 or IDLE_R6
            local track = animator:LoadAnimation(anim)
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Action4
            track:Play(0, 1, 1)
            state.idleTrack = track
        end)
    end

    local function prepareClone(src)
        pcall(function() src.Archivable = true end)
        for _, d in ipairs(src:GetDescendants()) do
            pcall(function() d.Archivable = true end)
        end
        local ok, clone = pcall(function() return src:Clone() end)
        if not ok or not clone then return nil, "Clone() failed" end

        for _, d in ipairs(clone:GetDescendants()) do
            local cn = d.ClassName
            if cn == "BillboardGui" or cn == "SurfaceGui" or cn == "Highlight"
                or cn == "ForceField" or cn == "Sound" or cn == "ParticleEmitter"
                or cn == "Fire" or cn == "Smoke" or cn == "Sparkles"
                or cn == "BoxHandleAdornment" or cn == "LineHandleAdornment"
                or cn == "Beam" then
                pcall(function() d:Destroy() end)
            elseif cn == "Script" or cn == "LocalScript" or cn == "ModuleScript" then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                pcall(function()
                    d.Anchored = true
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                    d.CastShadow = true
                    d.Massless = true
                    d.AssemblyLinearVelocity = Vector3.zero
                    d.AssemblyAngularVelocity = Vector3.zero
                    if d.LocalTransparencyModifier and d.LocalTransparencyModifier ~= 0 then
                        d.LocalTransparencyModifier = 0
                    end
                end)
            elseif d:IsA("Humanoid") then
                pcall(function()
                    d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                    d.NameDisplayDistance = 0
                    d.HealthDisplayDistance = 0
                    d.AutoRotate = false
                    d.WalkSpeed = 0
                    d.JumpPower = 0
                end)
            end
        end

        local root = findRoot(clone)
        if root then pcall(function() clone.PrimaryPart = root end) end
        pcall(function() clone:PivotTo(CFrame.new(0, 0, 0)) end)

        root = findRoot(clone)
        local head = clone:FindFirstChild("Head")
        local focus = Vector3.new(0, 1.5, 0)
        if root and head then
            focus = Vector3.new(0, (root.Position.Y + head.Position.Y) * 0.5, 0)
        elseif root then
            focus = Vector3.new(0, root.Position.Y + 0.5, 0)
        end
        return clone, focus
    end

    local function normFill(v)
        local fill = tonumber(v)
        if fill == nil then fill = 0.55 end
        if fill > 1 then fill = fill / 100 end
        return clamp(fill, 0, 1)
    end

    -- Highlight parented outside the ViewportFrame (Adornee = clone) — matches world chams
    -- Atlanta-style ESP preview: fixed Frame overlays on ViewportFrame (same as real ScreenESP)
    local previewObjects = {}
    local function ensurePreviewFrames()
        if previewObjects.holder and previewObjects.holder.Parent then return previewObjects end
        local cache = library.cache or library.other
        if not cache then
            cache = library:create("Folder", { Parent = library.other or coregui, Name = "\0" })
        end
        local holder = library:create("Frame", {
            Parent = viewport,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 8),
            Size = dim2(0, 120, 0, 175),
            ZIndex = 80,
        })
        local name = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            FontFace = fonts.font, TextSize = 12, Text = "Player",
            TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            AnchorPoint = vec2(0, 1), Size = dim2(1, 0, 0, 0),
            Position = dim2(0, 0, 0, -4), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        local box_handler = library:create("Frame", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2), ZIndex = 81,
        })
        local box_stroke = library:create("UIStroke", {
            Parent = box_handler, Color = themes.preset.accent, Thickness = 1,
            LineJoinMode = Enum.LineJoinMode.Miter,
        })
        local box_fill = library:create("Frame", {
            Parent = box_handler, BackgroundColor3 = themes.preset.accent,
            BackgroundTransparency = 0.8, BorderSizePixel = 0, Size = dim2(1, 0, 1, 0), ZIndex = 80,
        })
        local corners = library:create("Frame", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = dim2(1, 0, 1, 0), ZIndex = 82,
        })
        local function mkCorner(anchor, pos, size)
            local outer = library:create("Frame", {
                Parent = corners, AnchorPoint = anchor, Position = pos, Size = size,
                BorderSizePixel = 0, BackgroundColor3 = rgb(0, 0, 0), ZIndex = 82,
            })
            library:create("Frame", {
                Parent = outer, Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2),
                BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent, ZIndex = 83,
            })
        end
        mkCorner(vec2(0, 0), dim2(0, 0, 0, -1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(0, 0), dim2(0, 0, 0, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(1, 0), dim2(1, 0, 0, -1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(1, 0), dim2(1, 0, 0, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(0, 1), dim2(0, 0, 1, 1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(0, 1), dim2(0, 0, 1, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(1, 1), dim2(1, 0, 1, 1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(1, 1), dim2(1, 0, 1, 0), dim2(0, 3, 0.25, 0))

        local hp_holder = library:create("Frame", {
            Parent = holder, AnchorPoint = vec2(1, 0), Position = dim2(0, -4, 0, 0),
            Size = dim2(0, 4, 1, 0), BorderSizePixel = 0, BackgroundColor3 = rgb(0, 0, 0), ZIndex = 82,
        })
        local hp_fill = library:create("Frame", {
            Parent = hp_holder, Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2),
            BorderSizePixel = 0, BackgroundColor3 = rgb(80, 255, 120), ZIndex = 83,
        })
        local dist = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, FontFace = fonts.font, TextSize = 11,
            Text = "0st", TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 1, 4), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        local weapon = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, FontFace = fonts.font, TextSize = 11,
            Text = "None", TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 1, 16), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        previewObjects = {
            holder = holder, name = name, box_handler = box_handler, box_stroke = box_stroke,
            box_fill = box_fill, corners = corners, hp_holder = hp_holder, hp_fill = hp_fill,
            dist = dist, weapon = weapon, cache = cache,
        }
        return previewObjects
    end

    local function applyAllEsp(clone, vis)
        vis = vis or getVisuals() or {}
        local o = ensurePreviewFrames()
        local col = vis.Color or vis.ChamsColor or themes.preset.accent
        if typeof(col) ~= "Color3" then col = themes.preset.accent end
        if col.R > 0.92 and col.G > 0.92 and col.B > 0.92 then col = themes.preset.accent end

        local any = vis.Names or vis.Boxes or vis.BoxFilled or vis.HealthBar or vis.Distance or vis.Weapon
        o.holder.Visible = any == true

        -- Name
        o.name.Visible = vis.Names == true
        o.name.TextColor3 = col
        o.name.Text = "Player"

        -- Box normal vs hide
        local showBox = vis.Boxes == true or vis.BoxFilled == true
        o.box_handler.Visible = showBox
        o.box_stroke.Color = col
        o.box_stroke.Enabled = vis.Boxes == true
        o.box_fill.Visible = vis.BoxFilled == true
        o.box_fill.BackgroundColor3 = col
        o.corners.Visible = false -- normal box by default; corners optional later

        -- Health
        o.hp_holder.Visible = vis.HealthBar == true
        o.hp_fill.BackgroundColor3 = vis.HealthColor or rgb(80, 255, 120)

        -- Distance / weapon under box
        o.dist.Visible = vis.Distance == true
        o.dist.TextColor3 = col
        o.dist.Text = "0st"
        o.weapon.Visible = vis.Weapon == true
        o.weapon.TextColor3 = col
        o.weapon.Text = "None"
        o.weapon.Position = dim2(0, 0, 1, (vis.Distance == true) and 16 or 4)


        -- ============================================================
        -- Preview chams = outer translucent shells (looks like Highlight fill)
        -- Preview skeleton = 2D lines drawn ON TOP of the ViewportFrame
        -- ============================================================
        if clone then
            local fillCol = vis.ChamsColor or col
            if typeof(fillCol) ~= "Color3" then fillCol = col end
            if fillCol.R > 0.92 and fillCol.G > 0.92 and fillCol.B > 0.92 then
                fillCol = themes.preset.accent
            end
            local fill = tonumber(vis.ChamsFill) or 0.55
            if fill > 1 then fill = fill / 100 end
            fill = clamp(fill, 0, 1)

            -- base body stays normal grey (not painted purple)
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart")
                    and part.Name ~= "HumanoidRootPart"
                    and part.Name ~= "JuruSkelBone"
                    and part.Name ~= "JuruChamsShell"
                then
                    pcall(function()
                        part.Color = Color3.fromRGB(163, 162, 165)
                        part.Material = Enum.Material.SmoothPlastic
                        part.Transparency = 0
                    end)
                end
            end

            -- destroy old shells
            for _, s in ipairs(state.chamShells or {}) do
                pcall(function() s:Destroy() end)
            end
            state.chamShells = {}
            state.chamShellTargets = {}

            if vis.Chams == true then
                -- shell transparency: high fill => more solid overlay
                local shellT = clamp(1 - fill, 0.15, 0.72)
                local folder = clone:FindFirstChild("JuruChamsShells")
                if folder then pcall(function() folder:Destroy() end) end
                folder = Instance.new("Folder")
                folder.Name = "JuruChamsShells"
                folder.Parent = clone
                state.chamShellFolder = folder

                for _, part in ipairs(clone:GetDescendants()) do
                    if part:IsA("BasePart")
                        and part.Name ~= "HumanoidRootPart"
                        and part.Transparency < 0.9
                        and part.Size.Magnitude > 0.08
                        and not string.find(part.Name, "Juru", 1, true)
                    then
                        local shell = Instance.new("Part")
                        shell.Name = "JuruChamsShell"
                        shell.Anchored = true
                        shell.CanCollide = false
                        shell.CanQuery = false
                        shell.CanTouch = false
                        shell.CastShadow = false
                        shell.Material = Enum.Material.ForceField
                        shell.Color = fillCol
                        shell.Transparency = shellT
                        shell.Size = part.Size * 1.12
                        shell.CFrame = part.CFrame
                        shell.Parent = folder
                        state.chamShells[#state.chamShells + 1] = shell
                        state.chamShellTargets[#state.chamShellTargets + 1] = part
                    end
                end
            else
                local folder = clone:FindFirstChild("JuruChamsShells")
                if folder then pcall(function() folder:Destroy() end) end
            end

            -- kill leftover Highlight (causes white wash in VF)
            if state.previewHighlight then
                pcall(function() state.previewHighlight:Destroy() end)
                state.previewHighlight = nil
            end
            pcall(function()
                local orphan = clone:FindFirstChild("ChromatikPreviewChams")
                if orphan then orphan:Destroy() end
            end)

            -- no 3D skeleton bones (they get buried inside limbs)
            hideSkeletonBones()

            state._skelEnabled = vis.Skeleton == true
            state._skelColor = (typeof(col) == "Color3" and col) or themes.preset.accent
            ensureSkeletonOverlay()
            if state._skelEnabled then
                pcall(updateSkeletonOverlay)
            else
                hideSkeletonOverlay()
            end
        else
            state._skelEnabled = false
            hideSkeletonBones()
            hideSkeletonOverlay()
        end
    end

    local SKELETON_PAIRS = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
    }

    -- kept for cleanup compat
    ensureSkeletonBones = function() end
    hideSkeletonBones = function()
        if state.skelBones then
            for _, bone in ipairs(state.skelBones) do
                pcall(function() if bone then bone:Destroy() end end)
            end
        end
        state.skelBones = {}
        if state.skelFolder then
            pcall(function() state.skelFolder:Destroy() end)
            state.skelFolder = nil
        end
        pcall(function()
            if state.clone then
                local f = state.clone:FindFirstChild("JuruPreviewSkeleton")
                if f then f:Destroy() end
            end
        end)
    end
    updateSkeletonBones = function()
        -- shells follow limbs while character spins
        if state.chamShells and state.chamShellTargets then
            for i, shell in ipairs(state.chamShells) do
                local target = state.chamShellTargets[i]
                if shell and shell.Parent and target and target.Parent then
                    pcall(function()
                        shell.Size = target.Size * 1.12
                        shell.CFrame = target.CFrame
                    end)
                end
            end
        end
        -- 2D skeleton on top
        pcall(updateSkeletonOverlay)
    end

    ensureSkeletonOverlay = function()
        if previewObjects.skelLines and #previewObjects.skelLines > 0 then
            local ok = true
            for _, line in ipairs(previewObjects.skelLines) do
                if not (line and line.Parent) then ok = false break end
            end
            if ok then return previewObjects.skelLines end
        end
        local lines = {}
        -- parent to viewport: UI draws above 3D content
        for i = 1, 18 do
            local line = library:create("Frame", {
                Parent = viewport,
                BackgroundColor3 = themes.preset.accent,
                BorderSizePixel = 0,
                AnchorPoint = vec2(0.5, 0.5),
                Position = dim2(0.5, 0, 0.5, 0),
                Size = dim2(0, 3, 0, 0),
                Visible = false,
                ZIndex = 100,
            })
            library:create("UICorner", { Parent = line, CornerRadius = dim(1, 0) })
            lines[i] = line
        end
        previewObjects.skelLines = lines
        return lines
    end

    hideSkeletonOverlay = function()
        local lines = previewObjects.skelLines
        if not lines then return end
        for _, line in ipairs(lines) do
            if line then line.Visible = false end
        end
    end

    updateSkeletonOverlay = function()
        if not state._skelEnabled or not state.clone or not state.clone.Parent then
            hideSkeletonOverlay()
            return
        end
        local lines = ensureSkeletonOverlay()
        local clone = state.clone
        local vfCam = viewport.CurrentCamera or cam
        if not vfCam then hideSkeletonOverlay() return end
        local col = state._skelColor or themes.preset.accent
        if typeof(col) ~= "Color3" then col = themes.preset.accent end

        local function findP(n)
            local p = clone:FindFirstChild(n, true)
            return (p and p:IsA("BasePart")) and p or nil
        end

        local function project(world)
            local sp, on = vfCam:WorldToViewportPoint(world)
            return Vector2.new(sp.X, sp.Y), on and sp.Z > 0
        end

        local li = 1
        for _, pair in ipairs(SKELETON_PAIRS) do
            if li > #lines then break end
            local line = lines[li]
            local p0, p1 = findP(pair[1]), findP(pair[2])
            if p0 and p1 and p0 ~= p1 then
                local pa, oa = project(p0.Position)
                local pb, ob = project(p1.Position)
                if oa and ob then
                    local dx, dy = pb.X - pa.X, pb.Y - pa.Y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 1.5 then
                        local midX = (pa.X + pb.X) * 0.5
                        local midY = (pa.Y + pb.Y) * 0.5
                        local angle = math.deg(math.atan2(dy, dx))
                        line.BackgroundColor3 = col
                        line.Visible = true
                        line.Size = dim2(0, len, 0, 3)
                        line.Position = dim2(0, midX, 0, midY)
                        line.Rotation = angle
                        li = li + 1
                    else
                        line.Visible = false
                        li = li + 1
                    end
                else
                    line.Visible = false
                    li = li + 1
                end
            else
                -- skip missing pair without consuming? still advance to keep stable indices
                line.Visible = false
                li = li + 1
            end
        end
        for i = li, #lines do
            if lines[i] then lines[i].Visible = false end
        end
    end


    local function rebuildClone(force)
        if state.destroyed or not state.open then return end
        local now = tick()
        if not force and (now - state.lastCloneAt) < 1.0 then return end

        -- Prefer static preview dummy (no walk cycle), else local character
        local src = nil
        local tempDefault = nil
        pcall(function()
            local plr = getPlayer()
            if plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                src = plr.Character
            end
        end)
        if not src then
            pcall(function()
                if lp.Character then
                    lp.Character.Archivable = true
                    src = lp.Character
                end
            end)
        end
        if not src and type(makeDefaultCharacter) == "function" then
            pcall(function()
                tempDefault = makeDefaultCharacter()
                src = tempDefault
            end)
        end
        if not src then
            statusLabel.Text = "No character yet"
            statusLabel.Visible = true
            destroyClone()
            return
        end
        if not src:FindFirstChildOfClass("Humanoid") or not findRoot(src) then
            statusLabel.Text = "Waiting for character..."
            statusLabel.Visible = true
            return
        end

        state.lastCloneAt = now
        destroyClone()

        local clone, focusOrErr = prepareClone(src)
        pcall(function() if tempDefault and tempDefault ~= src then tempDefault:Destroy() end end)
        if not clone then
            statusLabel.Text = "Clone failed — " .. tostring(focusOrErr)
            statusLabel.Visible = true
            return
        end

        clone.Name = "EspPreviewChar"
        -- WorldModel improves engine instance rendering inside ViewportFrame
        local world = viewport:FindFirstChildOfClass("WorldModel")
        if not world then
            world = Instance.new("WorldModel")
            world.Name = "EspWorld"
            world.Parent = viewport
        end
        state.worldModel = world
        local parentOk, parentErr = pcall(function() clone.Parent = world end)
        if not parentOk then
            parentOk, parentErr = pcall(function() clone.Parent = viewport end)
        end
        if not parentOk then
            statusLabel.Text = "Parent failed — " .. tostring(parentErr)
            statusLabel.Visible = true
            pcall(function() clone:Destroy() end)
            return
        end

        state.clone = clone
        state.focus = typeof(focusOrErr) == "Vector3" and focusOrErr or Vector3.new(0, 1.5, 0)
        viewport.CurrentCamera = cam

        task.defer(function()
            if state.clone == clone then
                playIdleOnly(clone)
                end
        end)

        statusLabel.Visible = false
        task.defer(function()
            if state.clone == clone then
                applyAllEsp(clone, getVisuals() or {})
            end
        end)
    end

    local function updateCamera()
        -- Fixed camera (Atlanta): unzoomable, character spins in place
        if not state.clone or not state.clone.Parent then return end
        pcall(function()
            state.rotation = (state.rotation or 0) + 0.5
            local root = findRoot(state.clone)
            local cf = CFrame.new(Vector3.new(0, 1, -6)) * CFrame.Angles(0, math.rad(state.rotation), 0)
            if state.clone.PrimaryPart then
                pcall(function() state.clone:PivotTo(cf) end)
            elseif root then
                root.CFrame = cf
            end
            cam.CFrame = CFrame.new(Vector3.new(0, 1.5, 4), Vector3.new(0, 1, -6))
            viewport.CurrentCamera = cam
        end)
        -- skeleton lines must track the spin every frame
        pcall(updateSkeletonBones)
    end


    local function setOpen(bool)
        bool = bool == true
        state.open = bool
        panel.Visible = bool
        flags[enabledFlag] = bool
        if bool then
            statusLabel.Text = "Loading character..."
            statusLabel.Visible = true
            state.lastCloneAt = 0
            task.defer(function() rebuildClone(true) end)
        else
            destroyClone()
        end
        fireCallback(bool)
    end

    -- Atlanta preview: fixed camera, no orbit, no zoom (input ignored)

    -- Panel drag
    do
        local dragging, start, start_pos
        local function begin_drag(input)
            if pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = input.Position
                start_pos = panel.Position
            end
        end
        header.InputBegan:Connect(begin_drag)
        titleLabel.InputBegan:Connect(begin_drag)
        local function end_drag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then dragging = false; save_pos() end
            end
        end
        header.InputEnded:Connect(end_drag)
        library:connection(uis.InputEnded, end_drag)
        library:connection(uis.InputChanged, function(input)
            if not dragging or pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local nx = start_pos.X.Offset + (input.Position.X - start.X)
                local ny = start_pos.Y.Offset + (input.Position.Y - start.Y)
                local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or width
                local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or (height + 42)
                nx, ny = clamp_panel_position(nx, ny, pw, ph)
                panel.Position = dim2(0, nx, 0, ny)
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        setOpen(false)
        pcall(function()
            flags[enabledFlag] = false
            flags["juru_esp_preview"] = false
            if type(options.Callback) == "function" then options.Callback(false) end
            if type(options.callback) == "function" then options.callback(false) end
            if config_flags and config_flags[enabledFlag] then pcall(config_flags[enabledFlag], false) end
            if config_flags and config_flags["juru_esp_preview"] then pcall(config_flags["juru_esp_preview"], false) end
            -- force Juru config + silent UI flag
            if shared and shared.Juru then
                shared.Juru.EspPreview = shared.Juru.EspPreview or {}
                shared.Juru.EspPreview.Enabled = false
            end
            -- notify any listeners
            if shared then shared._juruEspPreviewClosed = tick() end
        end)
    end)

    local accum = 0
    library:connection(run.RenderStepped, function(dt)
        if state.destroyed then return end
        if not panel or not panel.Parent then return end
        -- Always dock + sync visibility with main menu
        local menuOn = true
        pcall(function()
            if library.items and library.items.Enabled == false then menuOn = false end
            if shared and shared._juruMenuOpen == false then menuOn = false end
            if shared and shared._juruMenuMain and shared._juruMenuMain.Visible == false then menuOn = false end
        end)
        panel.Visible = state.open and menuOn
        if gui then gui.Enabled = state.open and menuOn end
        if not state.open or not menuOn then return end
        dock_to_main()
        updateCamera() -- spins character + fixed cam
        accum = accum + (dt or 0.016)
        if accum < 0.2 then return end
        accum = 0
        if not state.clone or not state.clone.Parent then
            rebuildClone(true)
        elseif (tick() - state.lastCloneAt) > 12 then
            rebuildClone(true)
        else
            applyAllEsp(state.clone, getVisuals() or {})
        end
    end)

    library:connection(lp.CharacterAdded, function()
        task.delay(1, function()
            if state.open and not state.destroyed then rebuildClone(true) end
        end)
    end)

    if state.open then
        task.spawn(function()
            for _ = 1, 8 do
                if state.destroyed or not state.open then return end
                rebuildClone(true)
                if state.clone and state.clone.Parent then return end
                task.wait(0.35)
            end
        end)
    end

    local api = {
        Gui = gui,
        Panel = panel,
        Viewport = viewport,
        Camera = cam,
        GetClone = function() return state.clone end,
        GetCamera = function() return cam end,
        GetPanel = function() return panel end,
        GetViewport = function() return viewport end,
        -- Real ESP host: Juru projects normal ESP onto this rect
        GetRenderContext = function()
            if not state.open or not panel or not panel.Parent then return nil end
            local clone = state.clone
            if not clone or not clone.Parent then return nil end
            return {
                clone = clone,
                camera = cam,
                panel = panel,
                viewport = viewport,
                open = state.open,
            }
        end,
        ResetPosition = function()
            local vp = camera.ViewportSize
            local cx, cy = clamp_panel_position(vp.X - width - 18, math.floor(vp.Y * 0.32), width, height + 42)
            panel.Position = dim2(0, cx, 0, cy)
            save_pos()
        end,
        SetVisible = function(bool) setOpen(bool == true) end,
        SetEnabled = function(bool) setOpen(bool == true) end,
        IsEnabled = function() return state.open end,
        IsVisible = function() return state.open end,
        Refresh = function()
            state.lastCloneAt = 0
            state.lastVisKey = ""
            rebuildClone(true)
        end,
        DockToMain = function() dock_to_main() end,
        SetPinned = function(bool)
            pinned = bool == true
            pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
        end,
        SetTitle = function(t) titleLabel.Text = tostring(t) end,
        Destroy = function()
            state.destroyed = true
            state.open = false
            destroyClone()
            pcall(function() gui:Destroy() end)
            library.EspPreviewInstance = nil
        end,
    }

    if type(config_flags) == "table" then
        config_flags[enabledFlag] = function(v)
            if type(v) == "boolean" then
                setOpen(v)
            elseif type(v) == "table" and v.active ~= nil then
                setOpen(v.active == true)
            end
        end
    end

    library.EspPreviewInstance = api
    return api
end



getgenv().Chromatik = library
getgenv().Aether = library
return library
