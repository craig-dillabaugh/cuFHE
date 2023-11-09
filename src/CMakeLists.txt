add_library(vsp_cufhe_gpu
    vsp_bootstrap_gpu.cu
    vsp_cufhe_gates_gpu.cu
    vsp_cufhe_gpu.cu
    vsp_keyswitch_gpu.cu
    details/vsp_allocator_gpu.cu
    ntt_gpu/vsp_ntt_twiddle.cu
    )
target_link_libraries(vsp_cufhe_gpu INTERFACE tfhe++)
target_include_directories(vsp_cufhe_gpu
    PUBLIC ${PROJECT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/thirdparties/TFHEpp/include
    ${PROJECT_SOURCE_DIR}/thirdparties/TFHEpp/thirdparties/cereal/include
    ${PROJECT_SOURCE_DIR}/thirdparties/TFHEpp/thirdparties/randen
    ${PROJECT_SOURCE_DIR}/thirdparties/TFHEpp/thirdparties/spqlios
    )
set_target_properties(vsp_cufhe_gpu PROPERTIES CUDA_ARCHITECTURES "70;75;80") # V100, GTX 1660 Ti, A100
