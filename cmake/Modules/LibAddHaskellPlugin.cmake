include (LibAddMacros)

# Allows one to add plugins written in haskell, setting up the include paths and
# libraries automatically.
#
# Expects that plugins make use of cabal as their build system.
#
# MODULES:
#  the name of the haskell modules to be compiled
#  by default it assumes there is a single module called Elektra.<pluginName>
# NO_SHARED_SANDBOX:
#  By default all haskell plugins and the bindings are compiled in a shared sandbox to
#  peed up compilation times by only compiling commonly-used libraries once. Set this 
#  flag to use an independent sandbox instead in case there are e.g. library version conflicts
# SANDBOX_ADD_SOURCES:
#  additional source paths which should be added to the cabal sandbox
#  required if the build should depend on haskell libraries not available on hackage
# ADDITIONAL_SOURCES:
#  in case your plugin depends on other files than *.hs and *.lhs haskell files and the default
#  cabal file and c test file and setup file, you can specify them here
# 
macro (add_haskell_plugin target)
	cmake_parse_arguments (ARG
		"NO_SHARED_SANDBOX" # optional keywords
		"MODULE" # one value keywords
		"MODULES;SANDBOX_ADD_SOURCES;ADDITIONAL_SOURCES" # multi value keywords
		${ARGN}
	)

	set (PLUGIN_NAME ${target})
	set (PLUGIN_NAME_CAPITALIZED ${target})
	string (SUBSTRING ${PLUGIN_NAME} 0 1 FIRST_LETTER)
	string (TOUPPER ${FIRST_LETTER} FIRST_LETTER)
	string (REGEX REPLACE "^.(.*)" "${FIRST_LETTER}\\1" PLUGIN_NAME_CAPITALIZED "${PLUGIN_NAME}")
	string (TOUPPER ${PLUGIN_NAME} PLUGIN_NAME_UPPERCASE)

	if (DEPENDENCY_PHASE)
		find_package (Haskell)
		find_package (Pluginprocess)

		# set by find_program
		if (PLUGINPROCESS_FOUND) 
		if (HASKELL_FOUND)
		list (FIND BINDINGS "haskell" FINDEX)
		if (FINDEX GREATER -1)

			# needed for HsFFI.h
			execute_process (
				COMMAND ${GHC_EXECUTABLE} --print-libdir
				OUTPUT_VARIABLE GHC_LIB_DIR OUTPUT_STRIP_TRAILING_WHITESPACE
			)

			set (GHC_INCLUDE_DIRS
				${CMAKE_CURRENT_BINARY_DIR}/dist/build/Elektra # for the haskell function stubs
				${GHC_LIB_DIR}/include # for HsFFI.h
			)

			set (CABAL_OPTS "--prefix=${CMAKE_INSTALL_PREFIX}")
			if (BUILD_SHARED OR BUILD_FULL)
				# shared variants of ghc libraries have the ghc version as a suffix
				set (GHC_DYNAMIC_SUFFIX "-ghc${GHC_VERSION}")
				if (APPLE)
					set (GHC_DYNAMIC_ENDING ".dylib")
				else (APPLE)
					set (GHC_DYNAMIC_ENDING ".so")
				endif (APPLE)
				set (CABAL_OPTS "${CABAL_OPTS};--enable-shared")
			elseif (BUILD_STATIC)
				set (GHC_DYNAMIC_ENDING ".a")
				set (CABAL_OPTS "${CABAL_OPTS};--disable-shared")
			endif ()

			# since we want to continue to use our cmake add_plugin macro
			# we compile via the c compiler instead of ghc
			# so we must feed it with the ghc library paths manually
			# inspired by https://github.com/jarrett/cpphs/blob/master/Makefile
			# use HSrts_thr for the threaded version of the rts
			find_library (
				GHC_RTS_LIB "HSrts${GHC_DYNAMIC_SUFFIX}"
				PATHS "${GHC_LIB_DIR}/rts"
			)

			execute_process (
				COMMAND ${GHC-PKG_EXECUTABLE} latest base
				OUTPUT_VARIABLE GHC_BASE_NAME OUTPUT_STRIP_TRAILING_WHITESPACE
			)
			find_library (
				GHC_BASE_LIB "HS${GHC_BASE_NAME}${GHC_DYNAMIC_SUFFIX}"
				PATHS "${GHC_LIB_DIR}/${GHC_BASE_NAME}"
			)

			execute_process (
				COMMAND ${GHC-PKG_EXECUTABLE} latest integer-gmp
				OUTPUT_VARIABLE GHC_GMP_NAME OUTPUT_STRIP_TRAILING_WHITESPACE
			)
			find_library (
				GHC_GMP_LIB "HS${GHC_GMP_NAME}${GHC_DYNAMIC_SUFFIX}"
				PATHS "${GHC_LIB_DIR}/${GHC_GMP_NAME}"
			)

			execute_process (
				COMMAND ${GHC-PKG_EXECUTABLE} latest ghc-prim
				OUTPUT_VARIABLE GHC_PRIM_NAME OUTPUT_STRIP_TRAILING_WHITESPACE
			)
			find_library (
				GHC_PRIM_LIB "HS${GHC_PRIM_NAME}${GHC_DYNAMIC_SUFFIX}"
				PATHS "${GHC_LIB_DIR}/${GHC_PRIM_NAME}"
			)

			if (GHC_RTS_LIB)
			if (GHC_BASE_LIB)
			if (GHC_GMP_LIB)
			if (GHC_PRIM_LIB)

			set (PLUGIN_HASKELL_NAME "${CMAKE_CURRENT_BINARY_DIR}/libHS${target}${GHC_DYNAMIC_SUFFIX}${GHC_DYNAMIC_ENDING}")

			set (GHC_LIBS
				${GHC_RTS_LIB}
				${GHC_BASE_LIB}
				${GHC_GMP_LIB}
				gmp
				${GHC_PRIM_LIB}
				${PLUGIN_HASKELL_NAME}
			)

			# GHC's structure differs between OSX and Linux
			# On OSX we need to link iconv and Cffi additionally
			if (APPLE)
				find_library (GHC_FFI_LIB Cffi PATHS "${GHC_LIB_DIR}/rts")
				if (GHC_FFI_LIB)
					set (GHC_LIBS
						${GHC_LIBS}
						${GHC_FFI_LIB}
						iconv
					)
				else (GHC_FFI_LIB)
					remove_plugin (${target} "GHC_FFI_LIB not found")
				endif (GHC_FFI_LIB)
			endif (APPLE)

			# configure include paths
			configure_file (
				"${CMAKE_CURRENT_SOURCE_DIR}/${target}.cabal.in"
				"${CMAKE_CURRENT_BINARY_DIR}/${target}.cabal"
				@ONLY
			)
			# configure the haskell plugin base file for the current plugin
			configure_file (
				"${CMAKE_SOURCE_DIR}/src/plugins/haskell/haskell.c.in"
				"${CMAKE_CURRENT_BINARY_DIR}/haskell.c"
				@ONLY
			)
			# same for the header
			configure_file (
				"${CMAKE_SOURCE_DIR}/src/plugins/haskell/haskell.h.in"
				"${CMAKE_CURRENT_BINARY_DIR}/haskell.h"
				@ONLY
			)
			# copy the readme so the macro in haskell.c finds it
			file (
				COPY "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
				DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
			)
			# same for the setup logic, depending on wheter a custom one exists
			# use the default suitable for almost everything
			set (CABAL_CUSTOM_SETUP_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Setup.hs")
			if (NOT EXISTS ${CABAL_CUSTOM_SETUP_FILE})
				set (CABAL_CUSTOM_SETUP_FILE "${CMAKE_SOURCE_DIR}/src/plugins/haskell/Setup.hs")
			endif (NOT EXISTS ${CABAL_CUSTOM_SETUP_FILE})
			file (
				COPY ${CABAL_CUSTOM_SETUP_FILE}
				DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
			)

			set (SANDBOX_ADD_SOURCES "${ARG_SANDBOX_ADD_SOURCES};")
			if (NOT ARG_NO_SHARED_SANDBOX)
				set (SHARED_SANDBOX "--sandbox;${CMAKE_BINARY_DIR}/.cabal-sandbox")
				set (SANDBOX_ADD_SOURCES "${ARG_SANDBOX_ADD_SOURCES};../../bindings/haskell/")
			endif (NOT ARG_NO_SHARED_SANDBOX)

			configure_haskell_sandbox (
				SHARED_SANDBOX ${SHARED_SANDBOX}
				SANDBOX_ADD_SOURCES ${SANDBOX_ADD_SOURCES}
				DEPENDS c2hs_haskell
			)

			# Grab potential haskell source files
			file (GLOB_RECURSE PLUGIN_SOURCE_FILES
				"${CMAKE_CURRENT_SOURCE_DIR}/*.hs"
				"${CMAKE_CURRENT_SOURCE_DIR}/*.lhs"
			)
			set (PLUGIN_SOURCE_FILES
				"${PLUGIN_SOURCE_FILES}"
				"${CMAKE_CURRENT_SOURCE_DIR}/${target}.cabal.in"
				"${CMAKE_CURRENT_SOURCE_DIR}/testmod_${target}.c"
				"${CMAKE_SOURCE_DIR}/src/plugins/haskell/Setup.hs"
				"${ARG_ADDITIONAL_SOURCES}"
			)

			add_custom_command (
				OUTPUT ${PLUGIN_HASKELL_NAME}
				COMMAND ${CABAL_EXECUTABLE} ${CABAL_OPTS} configure -v0
				COMMAND ${CABAL_EXECUTABLE} build -v0
				WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} 
				DEPENDS c2hs_haskell
				"${CMAKE_SOURCE_DIR}/src/plugins/haskell/Setup.hs" 
				${PLUGIN_SOURCE_FILES}
				${HASKELL_ADD_SOURCES_TARGET}
			)
			add_custom_target (${target} ALL DEPENDS ${PLUGIN_HASKELL_NAME})
			
			if (BUILD_SHARED OR BUILD_FULL)
				install (DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/haskell" 
					DESTINATION "lib${LIB_SUFFIX}/elektra/")
			endif (BUILD_SHARED OR BUILD_FULL)

			else (GHC_PRIM_LIB)
				remove_plugin (${target} "GHC_PRIM_LIB not found")
			endif (GHC_PRIM_LIB)
			else (GHC_GMP_LIB)
				remove_plugin (${target} "GHC_GMP_LIB not found")
			endif (GHC_GMP_LIB)
			else (GHC_BASE_LIB)
				remove_plugin (${target} "GHC_BASE_LIB not found")
			endif (GHC_BASE_LIB)
			else (GHC_RTS_LIB)
				remove_plugin (${target} "GHC_RTS_LIB not found")
			endif (GHC_RTS_LIB)

		else (FINDEX GREATER -1)
			remove_plugin (${target} "haskell bindings are not included in the cmake configuration")
		endif (FINDEX GREATER -1)
		else (HASKELL_FOUND)
			remove_plugin (${target} ${HASKELL_NOTFOUND_INFO})
		endif (HASKELL_FOUND)
		else (PLUGINPROCESS_FOUND)
			remove_plugin (${target} "${PLUGINPROCESS_NOTFOUND_INFO}, but required for haskell plugins")
		endif (PLUGINPROCESS_FOUND)
	endif (DEPENDENCY_PHASE)

	# compile our c wrapper which takes care of invoking the haskell runtime
	# the actual haskell plugin gets linked in dynamically as a library
	add_plugin (${target}
		SOURCES
			${CMAKE_CURRENT_BINARY_DIR}/haskell.h
			${CMAKE_CURRENT_BINARY_DIR}/haskell.c
		INCLUDE_DIRECTORIES
			${GHC_INCLUDE_DIRS}
		LINK_LIBRARIES
			${GHC_LIBS}
		LINK_ELEKTRA
			elektra-pluginprocess
		DEPENDS
			${target} c2hs_haskell
		ADD_TEST
	)
	if (TARGET elektra-${target})
	if (DEPENDENCY_PHASE AND (BUILD_SHARED OR BUILD_FULL))
		set_target_properties (elektra-${target}
			PROPERTIES 
			INSTALL_RPATH "${CMAKE_INSTALL_RPATH};${CMAKE_INSTALL_PREFIX}/lib${LIB_SUFFIX}/elektra/haskell")
		# the rpath for the dependencies while we are still in the build tree
		add_custom_command (TARGET elektra-${target} POST_BUILD
			COMMAND ${CMAKE_INSTALL_NAME_TOOL} -add_rpath
				\"${CMAKE_CURRENT_BINARY_DIR}/haskell\" \"$<TARGET_FILE:elektra-${target}>\"
		)
		# remove the rpath again after installing - cmake will add the actual rpath
		install (CODE "execute_process (COMMAND ${CMAKE_INSTALL_NAME_TOOL} -delete_rpath 
			\"${CMAKE_CURRENT_BINARY_DIR}/haskell\" 
			\"${CMAKE_INSTALL_PREFIX}/lib${lib}/elektra/libelektra-${target}.so\" 
			OUTPUT_QUIET)"
		)
	endif (DEPENDENCY_PHASE AND (BUILD_SHARED OR BUILD_FULL))
	if (ADDTESTING_PHASE AND BUILD_TESTING AND (BUILD_SHARED OR BUILD_FULL))
		set_target_properties (testmod_${target}
			PROPERTIES 
			INSTALL_RPATH "${CMAKE_INSTALL_RPATH};${CMAKE_INSTALL_PREFIX}/lib${LIB_SUFFIX}/elektra/haskell")
		# guide the tests to our haskell libraries in a way it also works with the scripts
		set_property (TEST testmod_${target} PROPERTY ENVIRONMENT 
			"LD_LIBRARY_PATH=${CMAKE_CURRENT_BINARY_DIR}/haskell")
	endif (ADDTESTING_PHASE AND BUILD_TESTING AND (BUILD_SHARED OR BUILD_FULL))
	endif (TARGET elektra-${target})

	mark_as_advanced (
		GHC_FFI_LIB
		GHC_RTS_LIB
		GHC_BASE_LIB
		GHC_GMP_LIB
		GHC_PRIM_LIB
	)
endmacro (add_haskell_plugin)

# Allows adding sandbox sources for haskell plugins which will be executed in a serial manner
# to avoid cabal concurrency issues https://github.com/haskell/cabal/issues/2220. Also initializes
# sandboxes and will install the dependencies into them.
#
# SANDBOX_ADD_SOURCES:
#  additional source paths which should be added to the cabal sandbox
#  required if the build should depend on haskell libraries not available on hackage
# WORKING_DIRECTORY:
#  in case your plugin depends on other files than *.hs and *.lhs haskell files and the default
#  cabal file and c test file and setup file, you can specify them here
# DEPENDS:
#  additional targets this call should be dependent on
# 
macro (configure_haskell_sandbox)
	cmake_parse_arguments (ARG
		"" # optional keywords
		"" # one value keywords
		"SANDBOX_ADD_SOURCES;DEPENDS" # multi value keywords
		${ARGN}
	)

	get_property (HASKELL_SANDBOX_DEP_IDX GLOBAL PROPERTY HASKELL_SANDBOX_DEP_IDX)
	if (NOT HASKELL_SANDBOX_DEP_IDX)
		set (HASKELL_SANDBOX_DEP_IDX 1)
		add_custom_command (OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config"
			COMMAND ${CABAL_EXECUTABLE} sandbox init ${SHARED_SANDBOX} -v0
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			DEPENDS ${ARG_DEPENDS}
		)
		set (HASKELL_ADD_SOURCES_TARGET haskell-add-sources-${HASKELL_SANDBOX_DEP_IDX})
		add_custom_target (${HASKELL_ADD_SOURCES_TARGET} ALL DEPENDS
			"${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config")
	else (NOT HASKELL_SANDBOX_DEP_IDX)
		add_custom_command (OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config"
			COMMAND ${CABAL_EXECUTABLE} sandbox init ${SHARED_SANDBOX} -v0
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			DEPENDS haskell-add-sources-${HASKELL_SANDBOX_DEP_IDX}
			${ARG_DEPENDS}
		)
		math (EXPR HASKELL_SANDBOX_DEP_IDX "${HASKELL_SANDBOX_DEP_IDX} + 1")
		set (HASKELL_ADD_SOURCES_TARGET haskell-add-sources-${HASKELL_SANDBOX_DEP_IDX})
		add_custom_target (${HASKELL_ADD_SOURCES_TARGET} ALL DEPENDS
			"${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config")
	endif (NOT HASKELL_SANDBOX_DEP_IDX)

	if (ARG_SANDBOX_ADD_SOURCES)
		foreach (SANDBOX_ADD_SOURCE ${ARG_SANDBOX_ADD_SOURCES})
			add_custom_command (OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config"
				COMMAND ${CABAL_EXECUTABLE} sandbox add-source "${SANDBOX_ADD_SOURCE}" -v0
				APPEND
			)
		endforeach (SANDBOX_ADD_SOURCE ${ARG_SANDBOX_ADD_SOURCES})
	endif (ARG_SANDBOX_ADD_SOURCES)
	file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/cabalOptionalDependencies.cmake" 
		"execute_process (COMMAND ${CABAL_EXECUTABLE} install --only-dependencies -v0)")
	add_custom_command (OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cabal.sandbox.config"
		# ensure any further dependencies added by plugin developers get installed to the sandbox
		COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cabalOptionalDependencies.cmake"
		APPEND
	)

	set_property (GLOBAL PROPERTY HASKELL_SANDBOX_DEP_IDX "${HASKELL_SANDBOX_DEP_IDX}")
endmacro (configure_haskell_sandbox)

