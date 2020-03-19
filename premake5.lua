solution "ygo"
    location "build"
    language "C++"
    objdir "obj"
    if os.ishost("windows") or os.getenv("USE_IRRKLANG") then
        USE_IRRKLANG = true
        if os.getenv("irrklang_pro") then
            IRRKLANG_PRO = true
        end
    end

    configurations { "Release", "Debug" }
    configuration "windows"
        defines { "WIN32", "_WIN32", "WINVER=0x0501" }
        libdirs { "$(DXSDK_DIR)Lib/x86" }
        entrypoint "mainCRTStartup"
        toolset "v140_xp"
        startproject "ygopro"

    configuration "bsd"
        defines { "LUA_USE_POSIX" }
        includedirs { "/usr/local/include" }
        libdirs { "/usr/local/lib" }

    configuration "macosx"
        defines { "LUA_USE_MACOSX", "DBL_MAX_10_EXP=+308", "DBL_MANT_DIG=53"}
        includedirs { "/usr/local/include", "/usr/local/include/*" }
        libdirs { "/usr/local/lib", "/usr/X11/lib" }
        buildoptions { "-stdlib=libc++" }
        links { "OpenGL.framework", "Cocoa.framework", "IOKit.framework" }

    configuration "linux"
        defines { "LUA_USE_LINUX" }
        newoption
        {
            trigger = "environment-paths",
            description = "Read databases, scripts and images from YGOPRO_*_PATH"
        }
        if _OPTIONS["environment-paths"] then
            defines { "YGOPRO_ENVIRONMENT_PATHS" }
        end
        newoption
        {
            trigger = "xdg-environment",
            description = "Read config and data from XDG directories"
        }
        if _OPTIONS["xdg-environment"] then
            defines { "XDG_ENVIRONMENT" }
        end

    configuration "Release"
        optimize "Speed"
        targetdir "bin/release"

    configuration "Debug"
        symbols "On"
        defines "_DEBUG"
        targetdir "bin/debug"

    configuration { "Release", "vs*" }
        flags { "StaticRuntime", "LinkTimeOptimization" }
        disablewarnings { "4244", "4267", "4838", "4577", "4819", "4018", "4996", "4477", "4091", "4305" }

    configuration { "Release", "not vs*" }
        symbols "On"
        defines "NDEBUG"
        buildoptions "-march=native"

    configuration { "Debug", "vs*" }
        defines { "_ITERATOR_DEBUG_LEVEL=0" }
        disablewarnings { "4819" }

    configuration "vs*"
        vectorextensions "SSE2"
        defines { "_CRT_SECURE_NO_WARNINGS" }

    configuration "not vs*"
        buildoptions { "-fno-strict-aliasing", "-Wno-multichar" }

    configuration {"not vs*", "windows"}
        buildoptions { "-static-libgcc" }

    include "lua"
    include "ocgcore"
    include "gframe"
	if os.ishost("windows") then
		include "event"
		include "freetype"
		include "irrlicht"
		include "sqlite3"
	end
	if USE_IRRKLANG then
		include "ikpmp3"
	end
