--- Called after the tool is installed.
--- Used to set up the correct directory structure for Android SDK.
--- @param ctx table
--- @field ctx.rootPath string The installation root path
--- @field ctx.sdkInfo table SDK information including version
function PLUGIN:PostInstall(ctx)
    local file = require("file")

    local root_path = ctx.rootPath

    -- Get the version from sdkInfo
    local version = nil
    for _, info in pairs(ctx.sdkInfo) do
        version = info.version
        break
    end

    if not version then
        error("Could not determine version from sdkInfo")
    end

    -- vfox extracts cmdline-tools contents directly to rootPath
    -- But Android SDK expects: ANDROID_HOME/cmdline-tools/VERSION/bin/sdkmanager
    -- So we need to reorganize: move rootPath/* to rootPath/cmdline-tools/VERSION/

    -- Detect OS (Windows uses backslash as path separator)
    local os_type = RUNTIME.osType

    local temp_path = root_path .. "-temp"
    local target_path = file.join_path(root_path, "cmdline-tools", version)

    if os_type == "windows" then
        local cmdline_tools = file.join_path(root_path, "cmdline-tools", version)
        os.execute('mkdir "' .. cmdline_tools .. '" 2>nul')

        -- Mover TODO excepto cmdline-tools
        os.execute('robocopy "' .. root_path .. '" "' .. cmdline_tools .. '" /E /MOVE ' ..
                       '/XF cmdline-tools /XD cmdline-tools >nul')
    else
        -- Unix/Linux/macOS commands
        -- Move current rootPath to temp location
        local target_path = file.join_path(root_path, "cmdline-tools", version)
        os.execute("mkdir -p " .. target_path)
        os.execute("mv " .. root_path .. "/* " .. target_path .. "/")
    end

    -- Verify installation
    local sdkmanager = "sdkmanager"
    if os_type == "windows" then
        sdkmanager = "sdkmanager.bat"
    end

    local sdkmanager_path = file.join_path(target_path, "bin", sdkmanager)
    if not file.exists(sdkmanager_path) then
        error("sdkmanager not found at " .. sdkmanager_path)
    end
end
