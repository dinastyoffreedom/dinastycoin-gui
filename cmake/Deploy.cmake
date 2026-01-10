if(APPLE OR (WIN32 AND NOT STATIC))
    add_custom_target(deploy)
    get_target_property(_qmake_executable Qt5::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)

    if(APPLE AND NOT IOS)
        find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS "${_qt_bin_dir}")
        add_custom_command(TARGET deploy
                           POST_BUILD
                           COMMAND "${MACDEPLOYQT_EXECUTABLE}" "$<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../.." -always-overwrite -qmldir="${CMAKE_SOURCE_DIR}"
                           COMMENT "Running macdeployqt..."
        )

        # workaround for a Qt bug that requires manually adding libqsvg.dylib to bundle
        find_file(_qt_svg_dylib "libqsvg.dylib" PATHS "${CMAKE_PREFIX_PATH}/plugins/imageformats" NO_DEFAULT_PATH)
        if(_qt_svg_dylib)
            add_custom_command(TARGET deploy
                               POST_BUILD
                               COMMAND ${CMAKE_COMMAND} -E copy ${_qt_svg_dylib} $<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../PlugIns/imageformats/
                               COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change "${CMAKE_PREFIX_PATH}/lib/QtGui.framework/Versions/5/QtGui" "@executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui" $<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../PlugIns/imageformats/libqsvg.dylib
                               COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change "${CMAKE_PREFIX_PATH}/lib/QtWidgets.framework/Versions/5/QtWidgets" "@executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets" $<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../PlugIns/imageformats/libqsvg.dylib
                               COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change "${CMAKE_PREFIX_PATH}/lib/QtSvg.framework/Versions/5/QtSvg" "@executable_path/../Frameworks/QtSvg.framework/Versions/5/QtSvg" $<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../PlugIns/imageformats/libqsvg.dylib
                               COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change "${CMAKE_PREFIX_PATH}/lib/QtCore.framework/Versions/5/QtCore" "@executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore" $<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../PlugIns/imageformats/libqsvg.dylib
                               COMMENT "Copying libqsvg.dylib, running install_name_tool"

            )
        endif()

        # Copy Boost dylibs that macdeployqt doesn't pick up
        find_package(Boost QUIET COMPONENTS atomic container date_time)
        set(_boost_extras Boost::atomic Boost::container Boost::date_time)
        foreach(_tgt IN LISTS _boost_extras)
            if(TARGET ${_tgt})
                add_custom_command(TARGET deploy POST_BUILD
                                   COMMAND ${CMAKE_COMMAND} -E copy
                                   "$<TARGET_FILE:${_tgt}>"
                                   "$<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../Frameworks/"
                                   COMMENT "Copying $<TARGET_FILE_NAME:${_tgt}>"
                )
            endif()
        endforeach()

        # Apple Silicon requires all binaries to be codesigned
        find_program(CODESIGN_EXECUTABLE NAMES codesign)
        if(CODESIGN_EXECUTABLE)
            add_custom_command(TARGET deploy
                            POST_BUILD
                            COMMAND "${CODESIGN_EXECUTABLE}" --force --deep --sign - "$<TARGET_FILE_DIR:dinastycoin-wallet-gui>/../.."
                            COMMENT "Running codesign..."
            )
        endif()

    elseif(WIN32)
        find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")
        add_custom_command(TARGET dinastycoin-wallet-gui POST_BUILD
                           COMMAND "${CMAKE_COMMAND}" -E env PATH="${_qt_bin_dir}" "${WINDEPLOYQT_EXECUTABLE}" "$<TARGET_FILE:dinastycoin-wallet-gui>" -no-translations -qmldir="${CMAKE_SOURCE_DIR}"
                           COMMENT "Running windeployqt..."
        )
        set(WIN_DEPLOY_DLLS
            libboost_chrono-mt.dll
            libboost_filesystem-mt.dll
            libboost_locale-mt.dll
            libboost_program_options-mt.dll
            libboost_serialization-mt.dll
            libboost_thread-mt.dll
            libprotobuf.dll
            libbrotlicommon.dll
            libbrotlidec.dll
            libusb-1.0.dll
            zlib1.dll
            libzstd.dll
            libwinpthread-1.dll
            libtiff-6.dll
            libstdc++-6.dll
            libpng16-16.dll
            libpcre16-0.dll
            libpcre-1.dll
            libmng-2.dll
            liblzma-5.dll
            liblcms2-2.dll
            libjpeg-8.dll
            libintl-8.dll
            libiconv-2.dll
            libharfbuzz-0.dll
            libgraphite2.dll
            libglib-2.0-0.dll
            libfreetype-6.dll
            libbz2-1.dll
            libpcre2-16-0.dll
            libhidapi-0.dll
            libdouble-conversion.dll
            libgcrypt-20.dll
            libgpg-error-0.dll
            libsodium-26.dll
            libzmq.dll
            #platform files
            libgcc_s_seh-1.dll
            #openssl files
            libssl-3-x64.dll
            libcrypto-3-x64.dll
            #icu
            libicudt78.dll
            libicuin78.dll
            libicuio78.dll
            libicutu78.dll
            libicuuc78.dll
            #missing
            libabsl_cord-2508.0.0.dll
            libabsl_cord_internal-2508.0.0.dll
            libabsl_cordz_info-2508.0.0.dll
            libabsl_die_if_null-2508.0.0.dll
            libabsl_hash-2508.0.0.dll
            libabsl_log_internal_check_op-2508.0.0.dll
            libabsl_log_internal_conditions-2508.0.0.dll
            libabsl_log_internal_message-2508.0.0.dll
            libabsl_log_internal_nullguard-2508.0.0.dll
            libabsl_raw_hash_set-2508.0.0.dll
            libabsl_raw_logging_internal-2508.0.0.dll
            libabsl_raw_hash_set-2508.0.0.dll
            libabsl_spinlock_wait-2508.0.0.dll
            libabsl_status-2508.0.0.dll
            libabsl_statusor-2508.0.0.dll
            libabsl_str_format_internal-2508.0.0.dll
            libabsl_strings-2508.0.0.dll
            libabsl_strings_internal-2508.0.0.dll          
            libabsl_synchronization-2508.0.0.dll
            # libabsl_thread-2508.0.0.dll
            libabsl_throw_delegate-2508.0.0.dll
            libabsl_time-2508.0.0.dll
            libabsl_time_zone-2508.0.0.dll
            libabsl_crc_cord_state-2508.0.0.dll
            libabsl_stacktrace-2508.0.0.dll
            libabsl_base-2508.0.0.dll
            libabsl_city-2508.0.0.dll
            libabsl_cordz_handle-2508.0.0.dll
            libabsl_strerror-2508.0.0.dll
            libabsl_leak_check-2508.0.0.dll
            libabsl_hashtablez_sampler-2508.0.0.dll
            libabsl_examine_stack-2508.0.0.dll
            libabsl_log_globals-2508.0.0.dll
            libabsl_log_internal_format-2508.0.0.dll
            libabsl_log_internal_globals-2508.0.0.dll
            libabsl_log_internal_proto-2508.0.0.dll
            libabsl_log_internal_log_sink_set-2508.0.0.dll
            libabsl_log_internal_structured_proto-2508.0.0.dll
            libabsl_tracing_internal-2508.0.0.dll
            libabsl_strings-2508.0.0.dll
            libabsl_kernel_timeout_internal-2508.0.0.dll
            libabsl_malloc_internal-2508.0.0.dll
            libabsl_crc32c-2508.0.0.dll
            libabsl_crc_internal-2508.0.0.dll
            libabsl_symbolize-2508.0.0.dll
            libabsl_log_sink-2508.0.0.dll
            libpcre2-8-0.dll    
            libabsl_int128-2508.0.0.dll         
            libutf8_validity.dll
            libunbound-8.dll
            libmd4c.dll
        )

        # Boost Regex is header-only since 1.77
        if (Boost_VERSION_STRING VERSION_LESS 1.77.0)
            list(APPEND WIN_DEPLOY_DLLS libboost_regex-mt.dll)
        endif()

        list(TRANSFORM WIN_DEPLOY_DLLS PREPEND "$ENV{MSYSTEM_PREFIX}/bin/")
        add_custom_command(TARGET deploy
                           POST_BUILD
                           COMMAND ${CMAKE_COMMAND} -E copy ${WIN_DEPLOY_DLLS} "$<TARGET_FILE_DIR:dinastycoin-wallet-gui>"
                           COMMENT "Copying DLLs to target folder"
        )
    endif()
endif()
