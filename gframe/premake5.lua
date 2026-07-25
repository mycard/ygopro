if SERVER_MODE then
project "ygopro"
    kind "ConsoleApp"
    cppdialect "C++14"

    defines { "YGOPRO_SERVER_MODE" }

    files { "gframe.cpp", "config.h",
            "game.cpp", "game.h", "file_system.cpp", "file_system.h",
            "deck_manager.cpp", "deck_manager.h",
            "data_manager.cpp", "data_manager.h",
            "replay.cpp", "replay.h",
            "netserver.cpp", "netserver.h",
            "single_duel.cpp", "single_duel.h",
            "tag_duel.cpp", "tag_duel.h" }

    if SERVER_ZIP_SUPPORT then
        defines { "SERVER_ZIP_SUPPORT", "_IRR_STATIC_LIB_" }
        includedirs { IRRLICHT_SOURCE_DIR }
    end
    if SERVER_PRO2_SUPPORT then
        defines { "SERVER_PRO2_SUPPORT" }
    end
    if SERVER_TAG_SURRENDER_CONFIRM then
        defines { "SERVER_TAG_SURRENDER_CONFIRM" }
    end
else
project "YGOPro"
    kind "WindowedApp"
    rtti "Off"
    if USE_OPENMP then
        openmp "On"
    end

    defines { "_IRR_STATIC_LIB_" }
    files { "*.cpp", "*.h" }
end

    includedirs { "../ocgcore" }
    links { "ocgcore" }


    if BUILD_FREETYPE then
        -- Add custom include directory for FreeType before the default include directory
        includedirs { FREETYPE_CUSTOM_INCLUDE_DIR }
    end

    for _, dep in ipairs(DEPENDENCIES_METADATA) do
if IsServerUsedDep(dep.name) then
        local upper = string.upper(dep.name)
        includedirs { _G[upper .. "_INCLUDE_DIR"] }
        if _G["BUILD_" .. upper] then
            -- When building from source, the dependencies will be linked with their project names, which can't be changed via options.
            links { dep.name }
        else
            links { _G[upper .. "_LIB_NAME"] }
            libdirs { _G[upper .. "_LIB_DIR"] }
        end
end
    end

    if not BUILD_EVENT and not os.istarget("windows") then
        links { EVENT_PTHREADS_LIB_NAME }
    end

if not SERVER_MODE then
    if USE_SIMD == "none" then
        defines { "STBIR_NO_SIMD" }
    end

    if USE_AUDIO then
        defines { "YGOPRO_USE_AUDIO" }
        if AUDIO_LIB == "miniaudio" then
            defines { "YGOPRO_USE_MINIAUDIO" }
            includedirs { MINIAUDIO_INCLUDE_DIR }
            links { "miniaudio" }
            if MINIAUDIO_SUPPORT_OPUS_VORBIS then
                defines { "YGOPRO_MINIAUDIO_SUPPORT_OPUS_VORBIS" }
                includedirs { MINIAUDIO_OPUS_INCLUDE_DIR, MINIAUDIO_VORBIS_INCLUDE_DIR }
                if not MINIAUDIO_BUILD_OPUS_VORBIS then
                    links { OPUSFILE_LIB_NAME, VORBISFILE_LIB_NAME, OPUS_LIB_NAME, VORBIS_LIB_NAME, OGG_LIB_NAME }
                    libdirs { OPUSFILE_LIB_DIR, OPUS_LIB_DIR, VORBIS_LIB_DIR, OGG_LIB_DIR }
                end
            end
        end
    end
end

    filter "system:windows"
        entrypoint "mainCRTStartup"
        files "ygopro.rc"
        if SERVER_PRO2_SUPPORT then
            targetname "AI.Server"
        end
        links { "ws2_32", "iphlpapi", "winmm" }
        defines { "NOMINMAX=1", "WIN32_LEAN_AND_MEAN" }

    filter "not action:vs*"
        cppdialect "C++14"

if not SERVER_MODE then
    filter "system:macosx"
        links { "OpenGL.framework", "Cocoa.framework", "IOKit.framework", "Carbon.framework" }
        defines { "GL_SILENCE_DEPRECATION" }
end

    filter "system:linux"
if SERVER_MODE then
        -- Support old GCC toolchains used by existing server deployments.
        links { "pthread", "dl" }
else
        links { "GL", "X11", "dl", "pthread" }
        if USE_OPENMP then
            linkoptions { "-fopenmp" }
        end
    end
