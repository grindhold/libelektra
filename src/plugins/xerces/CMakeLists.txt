if (DEPENDENCY_PHASE)
	find_package(XercesC QUIET)

	if (NOT XercesC_FOUND)
		remove_plugin (xerces "XercesC library libxerces-c-dev not found")
	elseif (XercesC_VERSION VERSION_LESS 3.0.0)
		remove_plugin (xerces "XercesC library version 3.0.0 or higher required")
	endif ()
endif (DEPENDENCY_PHASE)

add_plugin (xerces
	CPP
	SOURCES
		xerces.hpp xerces.cpp
		deserializer.hpp deserializer.cpp
		serializer.hpp serializer.cpp
		util.hpp
	INCLUDE_DIRECTORIES
		${XercesC_INCLUDE_DIRS}
	LINK_LIBRARIES
		${XercesC_LIBRARIES}
	LINK_ELEKTRA
		elektra-meta
	INSTALL_TEST_DATA
)

if (ADDTESTING_PHASE)
	include (LibAddTest)
	add_plugintest (xerces
		MEMLEAK
		INSTALL_TEST_DATA
	)
endif (ADDTESTING_PHASE)
