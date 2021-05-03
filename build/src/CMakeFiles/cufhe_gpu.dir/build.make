# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.16

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/ubuntu/sources/cuFHE

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/ubuntu/sources/cuFHE/build

# Include any dependencies generated for this target.
include src/CMakeFiles/cufhe_gpu.dir/depend.make

# Include the progress variables for this target.
include src/CMakeFiles/cufhe_gpu.dir/progress.make

# Include the compile flags for this target's objects.
include src/CMakeFiles/cufhe_gpu.dir/flags.make

src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o: ../src/bootstrap_gpu.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CUDA object src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/local/cuda-11.3/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /home/ubuntu/sources/cuFHE/src/bootstrap_gpu.cu -o CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o

src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o: ../src/cufhe_gates_gpu.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CUDA object src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/local/cuda-11.3/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /home/ubuntu/sources/cuFHE/src/cufhe_gates_gpu.cu -o CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o

src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o: ../src/cufhe_gpu.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CUDA object src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/local/cuda-11.3/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /home/ubuntu/sources/cuFHE/src/cufhe_gpu.cu -o CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o

src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o: ../src/details/allocator_gpu.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CUDA object src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/local/cuda-11.3/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /home/ubuntu/sources/cuFHE/src/details/allocator_gpu.cu -o CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o

src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o: ../src/ntt_gpu/ntt_1024_twiddle.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CUDA object src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/local/cuda-11.3/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /home/ubuntu/sources/cuFHE/src/ntt_gpu/ntt_1024_twiddle.cu -o CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o

src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.o: ../src/cufhe.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/cufhe_gpu.dir/cufhe.cc.o -c /home/ubuntu/sources/cuFHE/src/cufhe.cc

src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/cufhe_gpu.dir/cufhe.cc.i"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/ubuntu/sources/cuFHE/src/cufhe.cc > CMakeFiles/cufhe_gpu.dir/cufhe.cc.i

src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/cufhe_gpu.dir/cufhe.cc.s"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/ubuntu/sources/cuFHE/src/cufhe.cc -o CMakeFiles/cufhe_gpu.dir/cufhe.cc.s

src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o: src/CMakeFiles/cufhe_gpu.dir/flags.make
src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o: ../src/cufhe_io.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o -c /home/ubuntu/sources/cuFHE/src/cufhe_io.cc

src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.i"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/ubuntu/sources/cuFHE/src/cufhe_io.cc > CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.i

src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.s"
	cd /home/ubuntu/sources/cuFHE/build/src && /usr/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/ubuntu/sources/cuFHE/src/cufhe_io.cc -o CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.s

# Object files for target cufhe_gpu
cufhe_gpu_OBJECTS = \
"CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o" \
"CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o" \
"CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o" \
"CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o" \
"CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o" \
"CMakeFiles/cufhe_gpu.dir/cufhe.cc.o" \
"CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o"

# External object files for target cufhe_gpu
cufhe_gpu_EXTERNAL_OBJECTS =

src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/bootstrap_gpu.cu.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/cufhe_gates_gpu.cu.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/cufhe_gpu.cu.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/details/allocator_gpu.cu.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/ntt_gpu/ntt_1024_twiddle.cu.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/cufhe.cc.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/cufhe_io.cc.o
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/build.make
src/libcufhe_gpu.a: src/CMakeFiles/cufhe_gpu.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/ubuntu/sources/cuFHE/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Linking CXX static library libcufhe_gpu.a"
	cd /home/ubuntu/sources/cuFHE/build/src && $(CMAKE_COMMAND) -P CMakeFiles/cufhe_gpu.dir/cmake_clean_target.cmake
	cd /home/ubuntu/sources/cuFHE/build/src && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/cufhe_gpu.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
src/CMakeFiles/cufhe_gpu.dir/build: src/libcufhe_gpu.a

.PHONY : src/CMakeFiles/cufhe_gpu.dir/build

src/CMakeFiles/cufhe_gpu.dir/clean:
	cd /home/ubuntu/sources/cuFHE/build/src && $(CMAKE_COMMAND) -P CMakeFiles/cufhe_gpu.dir/cmake_clean.cmake
.PHONY : src/CMakeFiles/cufhe_gpu.dir/clean

src/CMakeFiles/cufhe_gpu.dir/depend:
	cd /home/ubuntu/sources/cuFHE/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/ubuntu/sources/cuFHE /home/ubuntu/sources/cuFHE/src /home/ubuntu/sources/cuFHE/build /home/ubuntu/sources/cuFHE/build/src /home/ubuntu/sources/cuFHE/build/src/CMakeFiles/cufhe_gpu.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : src/CMakeFiles/cufhe_gpu.dir/depend

