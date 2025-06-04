# CEFDownload.cmake
# Handles CEF downloading with robust fallback mechanisms

# Set CEF distribution name and URL
if(CEF_USE_MINIMAL_DIST)
    set(CEF_DIST_NAME "cef_binary_${CEF_VERSION}_${CEF_PLATFORM}_minimal")
else()
    set(CEF_DIST_NAME "cef_binary_${CEF_VERSION}_${CEF_PLATFORM}")
endif()
set(CEF_URL "https://cef-builds.spotifycdn.com/${CEF_DIST_NAME}.tar.bz2")

# Function to perform robust download with multiple fallbacks
function(cef_robust_download)
    set(CEF_DOWNLOAD_DIR "${CMAKE_BINARY_DIR}/_cef_download")
    set(CEF_ARCHIVE_PATH "${CEF_DOWNLOAD_DIR}/${CEF_DIST_NAME}.tar.bz2")
    
    # Create download directory
    file(MAKE_DIRECTORY "${CEF_DOWNLOAD_DIR}")
    
    # Check if already downloaded
    if(EXISTS "${CEF_ARCHIVE_PATH}")
        message(STATUS "CEF archive already exists, skipping download")
        set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
        return()
    endif()
    
    message(STATUS "Downloading CEF archive to: ${CEF_ARCHIVE_PATH}")
    
    # Try CMake's built-in download first
    _cef_try_cmake_download("${CEF_URL}" "${CEF_ARCHIVE_PATH}")
    if(EXISTS "${CEF_ARCHIVE_PATH}")
        _cef_verify_download_size("${CEF_ARCHIVE_PATH}")
        set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
        return()
    endif()
    
    # Try curl
    _cef_try_curl_download("${CEF_URL}" "${CEF_ARCHIVE_PATH}")
    if(EXISTS "${CEF_ARCHIVE_PATH}")
        _cef_verify_download_size("${CEF_ARCHIVE_PATH}")
        set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
        return()
    endif()
    
    # Try wget
    _cef_try_wget_download("${CEF_URL}" "${CEF_ARCHIVE_PATH}")
    if(EXISTS "${CEF_ARCHIVE_PATH}")
        _cef_verify_download_size("${CEF_ARCHIVE_PATH}")
        set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
        return()
    endif()
    
    # Try PowerShell on Windows
    if(WIN32)
        _cef_try_powershell_download("${CEF_URL}" "${CEF_ARCHIVE_PATH}")
        if(EXISTS "${CEF_ARCHIVE_PATH}")
            _cef_verify_download_size("${CEF_ARCHIVE_PATH}")
            set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
            return()
        endif()
    endif()
    
    message(FATAL_ERROR "All download methods failed. Please check your internet connection and the CEF URL: ${CEF_URL}")
endfunction()

# Internal function to try CMake download
function(_cef_try_cmake_download url output_path)
    file(DOWNLOAD 
        "${url}" 
        "${output_path}"
        TIMEOUT 1800                 # 30 minute timeout total
        INACTIVITY_TIMEOUT 300       # 5 minute inactivity timeout
        SHOW_PROGRESS               # Show download progress
        STATUS download_status
        LOG download_log
    )
    
    list(GET download_status 0 status_code)
    list(GET download_status 1 status_string)
    
    if(NOT status_code EQUAL 0)
        message(STATUS "CMake download failed: ${status_code} - ${status_string}")
        file(REMOVE "${output_path}")
    endif()
endfunction()

# Internal function to try curl download
function(_cef_try_curl_download url output_path)
    find_program(CURL_EXECUTABLE curl)
    if(NOT CURL_EXECUTABLE)
        return()
    endif()
    
    message(STATUS "Retrying download with curl using HTTP/1.1...")
    execute_process(
        COMMAND ${CURL_EXECUTABLE} 
                -L                          # Follow redirects
                --http1.1                   # Force HTTP/1.1 to avoid HTTP/2 issues
                --retry 3                   # Retry failed downloads
                --retry-delay 5             # Wait 5 seconds between retries
                --max-time 1800             # 30 minute timeout total
                --connect-timeout 60        # 60 second connection timeout
                --progress-bar              # Show progress bar instead of verbose output
                -o "${output_path}" 
                "${url}"
        RESULT_VARIABLE curl_result
        OUTPUT_VARIABLE curl_output
        ERROR_VARIABLE curl_error
    )
    
    if(NOT curl_result EQUAL 0)
        message(STATUS "Curl failed with error (${curl_result}): ${curl_error}")
        file(REMOVE "${output_path}")
    endif()
endfunction()

# Internal function to try wget download
function(_cef_try_wget_download url output_path)
    find_program(WGET_EXECUTABLE wget)
    if(NOT WGET_EXECUTABLE)
        return()
    endif()
    
    message(STATUS "Retrying download with wget...")
    execute_process(
        COMMAND ${WGET_EXECUTABLE} 
                --tries=3                   # Retry 3 times
                --wait=5                    # Wait 5 seconds between retries
                --timeout=1800              # 30 minute timeout
                --progress=bar              # Show progress
                -O "${output_path}" 
                "${url}"
        RESULT_VARIABLE wget_result
        OUTPUT_VARIABLE wget_output
        ERROR_VARIABLE wget_error
    )
    
    if(NOT wget_result EQUAL 0)
        message(STATUS "Wget failed with error (${wget_result}): ${wget_error}")
        file(REMOVE "${output_path}")
    endif()
endfunction()

# Internal function to try PowerShell download (Windows only)
function(_cef_try_powershell_download url output_path)
    message(STATUS "Retrying download with PowerShell...")
    execute_process(
        COMMAND powershell -Command "
            $ProgressPreference = 'SilentlyContinue'
            try {
                Invoke-WebRequest -Uri '${url}' -OutFile '${output_path}' -TimeoutSec 1800
                exit 0
            } catch {
                Write-Error $_.Exception.Message
                exit 1
            }"
        RESULT_VARIABLE powershell_result
        OUTPUT_VARIABLE powershell_output
        ERROR_VARIABLE powershell_error
    )
    
    if(NOT powershell_result EQUAL 0)
        message(STATUS "PowerShell failed with error (${powershell_result}): ${powershell_error}")
        file(REMOVE "${output_path}")
    endif()
endfunction()

# Internal function to verify download size
function(_cef_verify_download_size archive_path)
    if(EXISTS "${archive_path}")
        file(SIZE "${archive_path}" archive_size)
        if(${archive_size} LESS ${MIN_CEF_ARCHIVE_SIZE})
            message(FATAL_ERROR "Downloaded CEF archive seems too small (${archive_size} bytes). Download may have failed.")
        endif()
        message(STATUS "CEF archive downloaded successfully (${archive_size} bytes)")
    else()
        message(FATAL_ERROR "CEF archive not found after download attempt")
    endif()
endfunction()

# Main function to download and extract CEF
function(cef_download_and_extract)
    include(FetchContent)
    
    # Display debug info
    message(STATUS "CEF Platform: ${CEF_PLATFORM}")
    message(STATUS "CEF URL: ${CEF_URL}")
    
    # Choose source based on whether local archive is provided
    if(CEF_LOCAL_ARCHIVE_PATH AND EXISTS "${CEF_LOCAL_ARCHIVE_PATH}")
        message(STATUS "Using local CEF archive: ${CEF_LOCAL_ARCHIVE_PATH}")
        FetchContent_Declare(
            cef_binaries
            URL      ${CEF_LOCAL_ARCHIVE_PATH}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        )
    elseif(CEF_ROBUST_DOWNLOAD)
        message(STATUS "Using robust download strategy for CEF...")
        message(STATUS "This may take several minutes for large downloads...")
        
        # Perform robust download
        cef_robust_download()
        
        # Use the downloaded archive
        FetchContent_Declare(
            cef_binaries
            URL      ${CEF_LOCAL_ARCHIVE}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        )
    else()
        # Standard download with reasonable timeout
        FetchContent_Declare(
            cef_binaries
            URL      ${CEF_URL}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            TIMEOUT  600  # 10 minutes timeout for large file
        )
    endif()
    
    # Extract CEF
    set(FETCHCONTENT_QUIET OFF)
    FetchContent_GetProperties(cef_binaries)
    if(NOT cef_binaries_POPULATED)
        message(STATUS "Extracting CEF binaries...")
        FetchContent_Populate(cef_binaries)
        message(STATUS "CEF binaries extracted to: ${cef_binaries_SOURCE_DIR}")
    endif()
    
    # Set global variable for use by other functions
    set(CEF_SOURCE_DIR "${cef_binaries_SOURCE_DIR}" PARENT_SCOPE)
endfunction()
