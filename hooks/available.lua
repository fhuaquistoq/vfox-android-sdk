--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local http = require("http")
    local env = require("env")

    local base_url = env.ANDROID_SDK_MIRROR_URL or "https://dl.google.com/android/repository"
    local metadata_url = base_url .. "/repository2-3.xml"

    local resp = http.get({ url = metadata_url })
    if resp.status_code ~= 200 then
        error("Failed to fetch Android SDK metadata: HTTP " .. resp.status_code)
    end

    local versions = {}
    local seen = {}

    -- Parse XML to find cmdline-tools packages
    -- Look for remotePackage elements with path="cmdline-tools;VERSION"
    for path_attr in resp.body:gmatch('remotePackage%s+path="([^"]+)"') do
        -- Match cmdline-tools;VERSION pattern, excluding "latest"
        local version = path_attr:match("^cmdline%-tools;(.+)$")
        if version and version ~= "latest" and not seen[version] then
            seen[version] = true
            table.insert(versions, {
                version = version,
                note = "",
            })
        end
    end

    -- Sort versions semantically (newest first)
    table.sort(versions, function(a, b)
        local function parse_version(v)
            local parts = {}
            local suffix = ""
            
            -- Extract suffix like -alpha01, -rc01
            local main, suf = v:match("^([%d%.]+)(.*)$")
            if main then
                suffix = suf or ""
                -- Split version by dots
                for num in main:gmatch("(%d+)") do
                    table.insert(parts, tonumber(num))
                end
            else
                table.insert(parts, 0)
            end
            
            return parts, suffix
        end
        
        local parts_a, suffix_a = parse_version(a.version)
        local parts_b, suffix_b = parse_version(b.version)
        
        -- Compare version parts numerically
        local max_parts = math.max(#parts_a, #parts_b)
        for i = 1, max_parts do
            local num_a = parts_a[i] or 0
            local num_b = parts_b[i] or 0
            if num_a ~= num_b then
                return num_a > num_b  -- Descending order (newest first)
            end
        end
        
        -- If version numbers are equal, compare suffixes
        -- Versions without suffix come before versions with suffix
        -- (e.g., 16.0 > 16.0-alpha01)
        if suffix_a == "" and suffix_b ~= "" then
            return true
        elseif suffix_a ~= "" and suffix_b == "" then
            return false
        else
            return suffix_a > suffix_b
        end
    end)

    return versions
end
