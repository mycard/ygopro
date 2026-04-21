include "lzma/."

if SERVER_MODE then
project "ygopro"
    kind "ConsoleApp"
    cppdialect "C++14"

    defines { "YGOPRO_SERVER_MODE" }

    files { "gframe.cpp", "config.h",
            "game.cpp", "game.h", "myfilesystem.h",
            "deck_manager.cpp", "deck_manager.h",
            "data_manager.cpp", "data_manager.h",
            "replay.cpp", "replay.h",
            "netserver.cpp", "netserver.h",
            "single_duel.cpp", "single_duel.h",
            "tag_duel.cpp", "tag_duel.h" }
    includedirs { "../ocgcore", EVENT_INCLUDE_DIR, SQLITE_INCLUDE_DIR }
    links { "ocgcore", "clzma", LUA_LIB_NAME, "sqlite3", "event" }
    if SERVER_ZIP_SUPPORT then
        defines { "SERVER_ZIP_SUPPORT" }
        links { "irrlicht" }
        if BUILD_IRRLICHT then
            includedirs { IRRLICHT_INCLUDE_DIR }
        end
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

    files { "*.cpp", "*.h" }
    includedirs { "../ocgcore", EVENT_INCLUDE_DIR, IRRLICHT_INCLUDE_DIR, JPEG_INCLUDE_DIR, SQLITE_INCLUDE_DIR }
    links { "ocgcore", "clzma", LUA_LIB_NAME, "sqlite3", "irrlicht", JPEG_LIB_NAME, "freetype", "event" }
end

    if not BUILD_LUA then
        libdirs { LUA_LIB_DIR }
    end

    if not BUILD_EVENT then
        libdirs { EVENT_LIB_DIR }
        links { "event_pthreads" }
    end

    if not BUILD_IRRLICHT then
        libdirs { IRRLICHT_LIB_DIR }
    end

if not SERVER_MODE then
    if not BUILD_PNG_IRRLICHT then
        links { "png" }
        libdirs { PNG_LIB_DIR }
    end

    if not BUILD_JPEG then
        libdirs { JPEG_LIB_DIR }
    end

    if BUILD_FREETYPE then
        includedirs { FREETYPE_CUSTOM_INCLUDE_DIR, FREETYPE_INCLUDE_DIR }
    else
        includedirs { FREETYPE_INCLUDE_DIR }
        libdirs { FREETYPE_LIB_DIR }
    end
end

    if not BUILD_SQLITE then
        libdirs { SQLITE_LIB_DIR }
    end

if not SERVER_MODE then
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
                    links { "opusfile", "vorbisfile", "opus", "vorbis", "ogg" }
                    libdirs { OPUS_LIB_DIR, OPUSFILE_LIB_DIR, VORBIS_LIB_DIR, OGG_LIB_DIR }
                end
            end
        end
        if AUDIO_LIB == "irrklang" then
            defines { "YGOPRO_USE_IRRKLANG" }
            includedirs { IRRKLANG_INCLUDE_DIR }
            if not IRRKLANG_PRO then
                libdirs { IRRKLANG_LIB_DIR }
            end
            if IRRKLANG_PRO_BUILD_IKPMP3 then
                links { "ikpmp3" }
            end
        end
    end
end

    filter "system:windows"
        entrypoint "mainCRTStartup"
        files "ygopro.rc"
if SERVER_PRO2_SUPPORT then
        targetname ("AI.Server")
end
        links { "ws2_32", "iphlpapi", "winmm" }
        if USE_AUDIO and AUDIO_LIB == "irrklang" then
            links { "irrKlang" }
            if IRRKLANG_PRO then
                defines { "IRRKLANG_STATIC" }
                filter { "system:windows", "not configurations:Debug" }
                    libdirs { IRRKLANG_PRO_RELEASE_LIB_DIR }
                filter { "system:windows", "configurations:Debug" }
                    libdirs { IRRKLANG_PRO_DEBUG_LIB_DIR }
                filter {}
            end
        end
    filter "not action:vs*"
        cppdialect "C++14"

    filter "system:macosx"
if not SERVER_MODE then
        openmp "Off"
        links { "OpenGL.framework", "Cocoa.framework", "IOKit.framework" }
        defines { "GL_SILENCE_DEPRECATION" }
end
        if MAC_ARM then
            linkoptions { "-arch arm64" }
        end
        if MAC_INTEL then
            linkoptions { "-arch x86_64" }
        end
        if USE_AUDIO and AUDIO_LIB == "irrklang" then
            links { "irrklang" }
        end

    filter "system:linux"
if not SERVER_MODE then
        links { "GL", "X11", "dl", "pthread" }
        linkoptions { "-fopenmp" }
end
if SERVER_MODE then -- support old gcc
        links { "pthread", "dl" }
end
        if USE_AUDIO and AUDIO_LIB == "irrklang" then
            links { "IrrKlang" }
            linkoptions{ IRRKLANG_LINK_RPATH }
        end
